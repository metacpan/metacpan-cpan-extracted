package Claude::Agent::Hook::Registry;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Scalar::Util qw(blessed);
use Future;
use Claude::Agent::Logger '$log';
use Claude::Agent::Types;
use Claude::Agent::Hook::Context;

BEGIN {
    Object::Proto::define('Claude::Agent::Hook::Registry',
        'hooks:HashRef:default({})',
        'loop:predicate',
        'query:weak:predicate',
        '_callbacks:HashRef:default({})',
        '_order:ArrayRef:default([])',
        '_warned:HashRef:default({})',
    );
}

sub BUILD {
    my ($self) = @_;
    my $n = 0;
    for my $event (sort keys %{$self->hooks}) {
        for my $matcher (@{ $self->hooks->{$event} // [] }) {
            next unless blessed($matcher) && $matcher->can('hooks');
            my @ids;
            for my $callback (@{$matcher->hooks}) {
                my $id = 'hook_' . $n++;
                $self->_callbacks->{$id} = {
                    callback => $callback,
                    matcher  => $matcher,
                    event    => $event,
                };
                push @ids, $id;
            }
            push @{$self->_order}, { event => $event, matcher => $matcher, ids => \@ids };
        }
    }
    return;
}

sub callback_ids {
    my ($self) = @_;
    return [ map { @{$_->{ids}} } @{$self->_order} ];
}

sub to_initialize_config {
    my ($self) = @_;
    my %config;
    for my $entry (@{$self->_order}) {
        my $matcher = $entry->{matcher};
        my $item = {
            matcher         => $matcher->matcher,
            hookCallbackIds => $entry->{ids},
        };
        $item->{timeout} = $matcher->timeout if $matcher->has_timeout;
        push @{ $config{ $entry->{event} } }, $item;
    }
    return \%config;
}

sub run {
    my ($self, $callback_id, $input, $tool_use_id) = @_;

    my $entry = $self->_callbacks->{$callback_id}
        or return Future->fail("No hook callback found for ID: $callback_id");

    $input = {} unless ref $input eq 'HASH';
    my $loop = $self->has_loop ? $self->loop : undef;

    my $context = Claude::Agent::Hook::Context->new(
        Claude::Agent::Types::defined_args(
            hook_event_name => $input->{hook_event_name} // $entry->{event},
            session_id      => $input->{session_id},
            cwd             => $input->{cwd},
            transcript_path => $input->{transcript_path},
            permission_mode => $input->{permission_mode},
            tool_name       => $input->{tool_name},
            tool_input      => $input->{tool_input},
            tool_use_id     => $tool_use_id // $input->{tool_use_id},
            loop            => $loop,
            query           => ($self->has_query ? $self->query : undef),
        )
    );

    $log->debug(sprintf("Hook: running %s for %s", $callback_id, $context->hook_event_name // 'event'));

    my $result;
    my $ok = eval { $result = $entry->{callback}->($input, $tool_use_id, $context, $loop); 1 };
    if (!$ok) {
        my $err = $@ || 'Hook execution failed';
        $log->debug(sprintf("Hook: %s died: %s", $callback_id, $err));
        return Future->fail("$err");
    }

    my $future = blessed($result) && $result->isa('Future') ? $result : Future->done($result);

    if ($loop && $entry->{matcher}->has_timeout && !$future->is_ready) {
        my $timeout = $entry->{matcher}->timeout;
        $future = Future->wait_any(
            $future,
            $loop->timeout_future(after => $timeout)->else(sub {
                return Future->fail("hook $callback_id timed out after ${timeout}s");
            }),
        );
    }

    return $future->then(sub {
        my ($output) = @_;
        return Future->done($self->_normalise($callback_id, $output));
    });
}

sub _normalise {
    my ($self, $callback_id, $output) = @_;

    return {} unless defined $output;
    return $output unless ref $output eq 'HASH';

    my $decision = $output->{decision} // '';
    return $output unless $decision =~ /^(?:continue|allow|deny)$/;

    unless ($self->_warned->{$callback_id}++) {
        warn "Hook callback $callback_id returned the 0.13 {decision => '$decision'} shape; "
           . "use Claude::Agent::Hook::Result\n";
    }

    return {} if $decision eq 'continue';

    my %specific = (
        hookEventName      => $self->_callbacks->{$callback_id}{event},
        permissionDecision => $decision,
    );
    $specific{permissionDecisionReason} = $output->{reason} if defined $output->{reason};
    $specific{updatedInput} = $output->{updated_input} if defined $output->{updated_input};
    return { hookSpecificOutput => \%specific };
}

1;

__END__

=head1 NAME

Claude::Agent::Hook::Registry - Register hook callbacks with the CLI and run them

=head1 SYNOPSIS

    my $registry = Claude::Agent::Hook::Registry->new(
        hooks => { PreToolUse => [ $matcher, ... ] },
        loop  => $loop,
        query => $query,
    );

    my $config = $registry->to_initialize_config;
    my $future = $registry->run('hook_0', $input, $tool_use_id);

=head1 DESCRIPTION

A query builds one registry from its C<hooks> option. The registry gives
every callback an id, produces the C<hooks> entry of the SDK C<initialize>
request, and runs the callback the CLI names in a C<hook_callback>
control request.

=head1 ATTRIBUTES

=head2 hooks

HashRef of event name to ArrayRef of L<Claude::Agent::Hook::Matcher>.

=head2 loop

The L<IO::Async::Loop>, used for timeouts and handed to callbacks.

=head2 query

The L<Claude::Agent::Query>, handed to callbacks through the context.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored. Ids are
assigned in event name order, then matcher order, then callback order:
C<hook_0>, C<hook_1>, and so on.

=head2 callback_ids

ArrayRef of every id, in registration order.

=head2 to_initialize_config

    my $config = $registry->to_initialize_config;

C<{ Event =E<gt> [ { matcher =E<gt> $pattern, hookCallbackIds =E<gt> [...],
timeout =E<gt> $seconds }, ... ] }>. C<matcher> is undef for a matcher with
none; C<timeout> is present only when the matcher sets one.

=head2 run

    my $future = $registry->run($callback_id, $input, $tool_use_id);

Runs one callback with the CLI's hook input and returns a L<Future> of the
hook output hashref. An unknown id, a callback that dies, a Future that
fails, or a callback that outruns its matcher's C<timeout> (when a loop is
set) all fail the Future. A callback returning undef yields an empty hash;
a callback returning the 0.13 C<{ decision =E<gt> ... }> shape is
translated to the CLI's shape, with a warning the first time.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
