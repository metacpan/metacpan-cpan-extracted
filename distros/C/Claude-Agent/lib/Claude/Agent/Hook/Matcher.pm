package Claude::Agent::Hook::Matcher;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
use Scalar::Util qw(blessed);
use Try::Tiny;
use Future;
use Types::Common -types;
use Marlin
    'matcher',                    # Regex pattern for tool names (optional)
    'hooks'   => sub { [] },      # ArrayRef of coderefs
    'timeout' => sub { 60 };      # Timeout in seconds

=head1 NAME

Claude::Agent::Hook::Matcher - Hook matcher for Claude Agent SDK

=head1 DESCRIPTION

Defines a hook matcher that triggers callbacks for specific tools.

=head2 ATTRIBUTES

=over 4

=item * matcher - Optional regex pattern to match tool names

=item * hooks - ArrayRef of callback coderefs

=item * timeout - Timeout in seconds (default: 60)

=back

=head2 CALLBACK SIGNATURE

Hooks receive input data, tool use ID, context, and an optional IO::Async::Loop.
They can return either a hashref (synchronous) or a Future (asynchronous).

    # Synchronous hook (backward compatible)
    sub callback {
        my ($input_data, $tool_use_id, $context, $loop) = @_;

        # $input_data contains:
        # - tool_name: Name of the tool
        # - tool_input: Input parameters for the tool

        # $context contains:
        # - session_id: Current session ID
        # - cwd: Current working directory

        # $loop is the IO::Async::Loop (optional, may be undef)

        # Return hashref with decision:
        return {
            decision => 'continue',  # or 'allow', 'deny'
            reason   => 'Optional reason',
            # For 'allow', can include:
            updated_input => { ... },
        };
    }

    # Asynchronous hook (returns Future)
    sub async_callback {
        my ($input_data, $tool_use_id, $context, $loop) = @_;

        # Use loop for async operations (e.g., HTTP requests)
        return $loop->delay_future(after => 0.1)->then(sub {
            # Perform async validation...
            return Future->done({
                decision => 'allow',
            });
        });
    }

=head2 METHODS

=head3 matches

    my $bool = $matcher->matches($tool_name);

Check if this matcher matches the given tool name.

B<IMPORTANT - Platform Limitation:> Regex timeout protection uses alarm()
which only works on Unix-like systems. On Windows (MSWin32, cygwin), a
post-execution time check is performed, but B<this cannot interrupt a
regex that hangs indefinitely> - it only detects slow patterns after
completion. Pattern length is limited to 1000 characters and basic nested
quantifier detection is performed to provide additional ReDoS protection,
but sophisticated ReDoS attacks with shorter patterns may still be possible.
For security-critical applications, especially on Windows, consider using
re::engine::PCRE2 or Regexp::Timeout for proper cross-platform timeout
support, or use pre-validated patterns only.

=cut

sub matches {
    my ($self, $tool_name) = @_;

    # Handle undefined tool name
    return 0 unless defined $tool_name;

    # No matcher means match all
    return 1 unless defined $self->matcher;

    my $pattern = $self->matcher;

    # If it's a simple string (no regex metacharacters), do exact match
    # Use quotemeta to reliably detect plain strings vs regex patterns
    if ($pattern eq quotemeta($pattern)) {
        return $tool_name eq $pattern;
    }

    # Otherwise treat as regex with timeout protection against ReDoS
    # Use Try::Tiny with finally to ensure alarm is always cleared
    my $result;
    try {
        # Validate pattern length to mitigate ReDoS
        if (length($pattern) > 1000) {
            die "Pattern too long\n";
        }

        # Detect potentially dangerous ReDoS patterns (works on all platforms)
        # Look for nested quantifiers like (a+)+ or (a*)*
        if ($pattern =~ /\([^)]*[+*][^)]*\)[+*]/ ||
            $pattern =~ /\([^)]*\|[^)]*\)[+*]/) {
            die "Potentially dangerous nested quantifier pattern\n";
        }

        # Cross-platform timeout mechanism using Time::HiRes
        # Note: alarm() only works on Unix-like systems (skipped on Windows)
        # For true cross-platform ReDoS protection, consider re::engine::PCRE2
        # or Regexp::Timeout. This implementation provides best-effort protection.
        my $use_alarm = $^O ne 'MSWin32' && $^O ne 'cygwin';
        my $timeout_seconds = 1;

        if ($use_alarm) {
            local $SIG{ALRM} = sub { die "Regex timeout\n" };
            alarm($timeout_seconds);
        }

        # For Windows, use Time::HiRes-based polling timeout as fallback
        # This is not as precise as alarm() but provides some protection
        require Time::HiRes;
        my $start_time = Time::HiRes::time();

        my $compiled = qr/$pattern/;
        $result = $tool_name =~ $compiled ? 1 : 0;

        # Check if we exceeded timeout on Windows (post-facto detection)
        if (!$use_alarm && (Time::HiRes::time() - $start_time) > $timeout_seconds) {
            die "Regex timeout (Windows)\n";
        }

        alarm(0) if $use_alarm;
    } catch {
        $result = 0;
    } finally {
        alarm(0) if $^O ne 'MSWin32' && $^O ne 'cygwin';
    };
    return $result // 0;
}

=head3 run_hooks

    my $future = $matcher->run_hooks($input_data, $tool_use_id, $context, $loop);

Run all hooks and return a Future that resolves to an arrayref of results.
Hooks may return either a hashref (synchronous) or a Future (asynchronous).

=cut

sub run_hooks {
    my ($self, $input_data, $tool_use_id, $context, $loop) = @_;

    my @hooks = @{$self->hooks};
    return Future->done([]) unless @hooks;

    # Process hooks sequentially, stopping on definitive decisions
    return $self->_run_hooks_sequentially(\@hooks, $input_data, $tool_use_id, $context, $loop, []);
}

# Internal: run hooks one at a time, chaining Futures
sub _run_hooks_sequentially {
    my ($self, $hooks, $input_data, $tool_use_id, $context, $loop, $results) = @_;

    return Future->done($results) unless @$hooks;

    my $hook = shift @$hooks;
    my $hook_num = scalar(@{$results}) + 1;
    my $total_hooks = $hook_num + scalar(@$hooks);

    $log->trace(sprintf("Hook: Running hook %d/%d", $hook_num, $total_hooks));

    # Execute the hook
    my ($result, $hook_error);
    try {
        $result = $hook->($input_data, $tool_use_id, $context, $loop);
    } catch {
        $hook_error = $_;
    };

    # Handle sync errors
    if ($hook_error) {
        $log->debug(sprintf("Hook error: %s", $hook_error));
        push @$results, {
            decision => 'error',
            error    => 'Hook execution failed',
        };
        # Continue to next hook after error
        return $self->_run_hooks_sequentially($hooks, $input_data, $tool_use_id, $context, $loop, $results);
    }

    # If result is a Future, chain to it
    if (blessed($result) && $result->isa('Future')) {
        return $result->then(sub {
            my ($async_result) = @_;
            push @$results, $async_result // { decision => 'continue' };

            # Stop if we got a definitive decision
            if ($async_result && ref($async_result) eq 'HASH' && $async_result->{decision}
                && $async_result->{decision} =~ /^(allow|deny)$/) {
                return Future->done($results);
            }

            # Continue to next hook
            return $self->_run_hooks_sequentially($hooks, $input_data, $tool_use_id, $context, $loop, $results);
        })->else(sub {
            my ($error) = @_;
            $log->debug(sprintf("Async hook error: %s", $error));
            push @$results, {
                decision => 'error',
                error    => 'Hook execution failed',
            };
            # Continue to next hook after error
            return $self->_run_hooks_sequentially($hooks, $input_data, $tool_use_id, $context, $loop, $results);
        });
    }

    # Synchronous result
    my $decision = ref($result) eq 'HASH' ? ($result->{decision} // 'continue') : 'continue';
    $log->trace(sprintf("Hook: Hook returned decision=%s", $decision));
    push @$results, $result // { decision => 'continue' };

    # Stop if we got a definitive decision
    if ($result && ref($result) eq 'HASH' && $result->{decision}
        && $result->{decision} =~ /^(allow|deny)$/) {
        return Future->done($results);
    }

    # Continue to next hook
    return $self->_run_hooks_sequentially($hooks, $input_data, $tool_use_id, $context, $loop, $results);
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
