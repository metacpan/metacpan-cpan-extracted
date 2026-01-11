package Claude::Agent::Hook::Matcher;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
use Try::Tiny;
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

    sub callback {
        my ($input_data, $tool_use_id, $context) = @_;

        # $input_data contains:
        # - tool_name: Name of the tool
        # - tool_input: Input parameters for the tool

        # $context contains:
        # - session_id: Current session ID
        # - cwd: Current working directory

        # Return hashref with decision:
        return {
            decision => 'continue',  # or 'allow', 'deny'
            reason   => 'Optional reason',
            # For 'allow', can include:
            updated_input => { ... },
        };
    }

=head2 METHODS

=head3 matches

    my $bool = $matcher->matches($tool_name);

Check if this matcher matches the given tool name.

B<IMPORTANT - Platform Limitation:> Regex timeout protection uses alarm()
which only works on Unix-like systems. B<On Windows (MSWin32, cygwin),
malicious regex patterns will NOT be interrupted and could cause the
process to hang indefinitely.> Pattern length is limited to 1000 characters
and basic nested quantifier detection is performed to provide additional
ReDoS protection, but sophisticated ReDoS attacks with shorter patterns
may still be possible. Consider using pre-validated patterns or a regex
library with built-in timeout support (e.g., re::engine::PCRE2) for
security-critical applications on Windows.

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

        # alarm() only works on Unix-like systems, skip on Windows
        my $use_alarm = $^O ne 'MSWin32' && $^O ne 'cygwin';
        if ($use_alarm) {
            local $SIG{ALRM} = sub { die "Regex timeout\n" };
            alarm(1);
        }

        my $compiled = qr/$pattern/;
        $result = $tool_name =~ $compiled ? 1 : 0;

        alarm(0) if $use_alarm;
    } catch {
        $result = 0;
    } finally {
        alarm(0) if $^O ne 'MSWin32' && $^O ne 'cygwin';
    };
    return $result // 0;
}

=head3 run_hooks

    my $results = $matcher->run_hooks($input_data, $tool_use_id, $context);

Run all hooks and return their results.

=cut

sub run_hooks {
    my ($self, $input_data, $tool_use_id, $context) = @_;

    my @results;

    for my $hook (@{$self->hooks}) {
        my ($result, $hook_error);
        try {
            $result = $hook->($input_data, $tool_use_id, $context);
        } catch {
            $hook_error = $_;
        };

        if ($hook_error) {
            # Log full error for debugging, return sanitized message
            $log->debug("Hook error: %s", $hook_error);
            push @results, {
                decision => 'error',
                error    => 'Hook execution failed',
            };
        }
        else {
            push @results, $result // { decision => 'continue' };
        }

        # Stop if we got a definitive decision
        last if $result && ref($result) eq 'HASH' && $result->{decision}
            && $result->{decision} =~ /^(allow|deny)$/;
    }

    return \@results;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
