package Claude::Agent::Hook::Executor;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Logger '$log';
use Types::Common -types;
use Scalar::Util qw(blessed);
use Try::Tiny;

use Claude::Agent::Hook;
use Claude::Agent::Hook::Context;
use Claude::Agent::Hook::Result;

use Marlin
    'hooks'       => sub { {} },      # Event name => arrayref of matchers
    'session_id==.',                  # Read-write, set after init message
    'cwd?';

=head1 NAME

Claude::Agent::Hook::Executor - Executes Perl hooks for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Hook::Executor;
    use Claude::Agent::Hook::Matcher;

    my $executor = Claude::Agent::Hook::Executor->new(
        hooks => {
            PreToolUse => [
                Claude::Agent::Hook::Matcher->new(
                    matcher => 'Bash',
                    hooks   => [sub {
                        my ($input, $tool_use_id, $context) = @_;
                        if ($input->{tool_input}{command} =~ /rm -rf/) {
                            return Claude::Agent::Hook::Result->deny(
                                reason => 'Dangerous command blocked',
                            );
                        }
                        return Claude::Agent::Hook::Result->proceed();
                    }],
                ),
            ],
        },
        session_id => $session_id,
    );

    # Execute pre-tool-use hooks
    my $result = $executor->run_pre_tool_use($tool_name, $tool_input, $tool_use_id);

    if ($result->{decision} eq 'deny') {
        # Block the tool
    }

=head1 DESCRIPTION

This module executes Perl hook callbacks when tool use events occur.
It intercepts tool calls in the Query layer and runs matching hooks.

=head1 ATTRIBUTES

=head2 hooks

HashRef of hook event names to arrayrefs of L<Claude::Agent::Hook::Matcher> objects.

=head2 session_id

Current session ID (set after init message).

=head2 cwd

Current working directory.

=head1 METHODS

=head2 run_pre_tool_use

    my $result = $executor->run_pre_tool_use($tool_name, $tool_input, $tool_use_id);

Execute PreToolUse hooks for a tool call. Returns a hashref with:

    {
        decision      => 'continue' | 'allow' | 'deny',
        reason        => 'optional reason',
        updated_input => { ... },  # for 'allow' decision
    }

=cut

sub run_pre_tool_use {
    my ($self, $tool_name, $tool_input, $tool_use_id) = @_;

    return $self->_run_hooks(
        $Claude::Agent::Hook::PRE_TOOL_USE,
        $tool_name,
        $tool_input,
        $tool_use_id,
    );
}

=head2 run_post_tool_use

    my $result = $executor->run_post_tool_use($tool_name, $tool_input, $tool_use_id, $tool_result);

Execute PostToolUse hooks after a tool completes successfully.

=cut

sub run_post_tool_use {
    my ($self, $tool_name, $tool_input, $tool_use_id, $tool_result) = @_;

    return $self->_run_hooks(
        $Claude::Agent::Hook::POST_TOOL_USE,
        $tool_name,
        $tool_input,
        $tool_use_id,
        $tool_result,
    );
}

=head2 run_post_tool_use_failure

    my $result = $executor->run_post_tool_use_failure($tool_name, $tool_input, $tool_use_id, $error);

Execute PostToolUseFailure hooks after a tool fails.

=cut

sub run_post_tool_use_failure {
    my ($self, $tool_name, $tool_input, $tool_use_id, $error) = @_;

    return $self->_run_hooks(
        $Claude::Agent::Hook::POST_TOOL_USE_FAIL,
        $tool_name,
        $tool_input,
        $tool_use_id,
        undef,
        $error,
    );
}

=head2 run_notification

    $executor->run_notification($notification_type, $data);

Execute Notification hooks.

=cut

sub run_notification {
    my ($self, $notification_type, $data) = @_;

    my $matchers = $self->hooks->{$Claude::Agent::Hook::NOTIFICATION} // [];
    return { decision => 'continue' } unless @$matchers;

    my $context = Claude::Agent::Hook::Context->new(
        session_id => $self->session_id,
        cwd        => $self->cwd,
    );

    my $input_data = {
        notification_type => $notification_type,
        data              => $data,
    };

    for my $matcher (@$matchers) {
        next unless blessed($matcher) && $matcher->can('run_hooks');
        my $results = $matcher->run_hooks($input_data, undef, $context);
        # Notifications don't typically return decisions
    }

    return { decision => 'continue' };
}

=head2 run_stop

    $executor->run_stop($reason);

Execute Stop hooks when the agent stops.

=cut

sub run_stop {
    my ($self, $reason) = @_;

    my $matchers = $self->hooks->{$Claude::Agent::Hook::STOP} // [];
    return { decision => 'continue' } unless @$matchers;

    my $context = Claude::Agent::Hook::Context->new(
        session_id => $self->session_id,
        cwd        => $self->cwd,
    );

    my $input_data = { reason => $reason };

    for my $matcher (@$matchers) {
        next unless blessed($matcher) && $matcher->can('run_hooks');
        $matcher->run_hooks($input_data, undef, $context);
    }

    return { decision => 'continue' };
}

=head2 has_hooks_for

    if ($executor->has_hooks_for('PreToolUse')) { ... }

Returns true if there are hooks registered for the given event.

=cut

sub has_hooks_for {
    my ($self, $event) = @_;

    my $matchers = $self->hooks->{$event};
    return 0 unless $matchers && ref($matchers) eq 'ARRAY';
    return scalar(@$matchers) > 0;
}

# Internal method to run hooks for a given event
sub _run_hooks {
    my ($self, $event, $tool_name, $tool_input, $tool_use_id, $tool_result, $error) = @_;

    my $matchers = $self->hooks->{$event} // [];
    return { decision => 'continue' } unless @$matchers;

    # Build context - only include defined values
    my %context_args = (
        tool_name  => $tool_name,
        tool_input => $tool_input,
    );
    $context_args{session_id} = $self->session_id if defined $self->session_id;
    $context_args{cwd} = $self->cwd if $self->has_cwd && defined $self->cwd;
    my $context = Claude::Agent::Hook::Context->new(%context_args);

    # Build input data for hooks
    my $input_data = {
        tool_name  => $tool_name,
        tool_input => $tool_input,
    };
    $input_data->{tool_result} = $tool_result if defined $tool_result;
    $input_data->{error} = $error if defined $error;

    # Run matching hooks
    my $final_result = { decision => 'continue' };

    for my $matcher (@$matchers) {
        # Skip non-matcher objects
        next unless blessed($matcher) && $matcher->can('matches');

        # Check if this matcher applies to this tool
        next unless $matcher->matches($tool_name);

        # Run the hooks
        my $results = $matcher->run_hooks($input_data, $tool_use_id, $context);

        # Process results - first definitive decision wins
        for my $result (@{$results // []}) {
            next unless ref($result) eq 'HASH' && $result->{decision};

            if ($result->{decision} eq 'deny') {
                $log->info("[HOOK] PreToolUse: DENIED %s - %s",
                    $tool_name, $result->{reason} // 'no reason');
                return $result;
            }
            elsif ($result->{decision} eq 'allow') {
                $log->debug("[HOOK] PreToolUse: ALLOWED %s%s",
                    $tool_name, $result->{updated_input} ? ' (with modifications)' : '');
                return $result;
            }
            elsif ($result->{decision} eq 'error') {
                $log->warning("[HOOK] PreToolUse: ERROR in hook for %s - %s",
                    $tool_name, $result->{error} // 'unknown error');
                # Continue on error, don't block
            }
            # 'continue' - keep checking other matchers
        }
    }

    return $final_result;
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
