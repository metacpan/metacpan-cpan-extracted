package Claude::Agent::Hook::Result;

use 5.020;
use strict;
use warnings;

sub proceed {
    return {};
}

sub allow {
    my ($class, %args) = @_;
    return _permission('allow', %args);
}

sub deny {
    my ($class, %args) = @_;
    return _permission('deny', %args);
}

sub ask {
    my ($class, %args) = @_;
    return _permission('ask', %args);
}

sub defer {
    my ($class, %args) = @_;
    return _permission('defer', %args);
}

sub _permission {
    my ($decision, %args) = @_;
    my %specific = (
        hookEventName      => $args{event} // 'PreToolUse',
        permissionDecision => $decision,
    );
    $specific{permissionDecisionReason} = $args{reason} if defined $args{reason};
    $specific{updatedInput} = $args{updated_input} if defined $args{updated_input};
    return { hookSpecificOutput => \%specific };
}

sub block {
    my ($class, %args) = @_;
    my $result = { decision => 'block' };
    $result->{reason} = $args{reason} if defined $args{reason};
    return $result;
}

sub stop {
    my ($class, %args) = @_;
    my $result = { continue => \0 };
    $result->{stopReason} = $args{reason} if defined $args{reason};
    return $result;
}

sub add_context {
    my ($class, $text, %args) = @_;
    return {
        hookSpecificOutput => {
            hookEventName     => $args{event} // 'PreToolUse',
            additionalContext => $text,
        },
    };
}

sub update_tool_output {
    my ($class, $output, %args) = @_;
    return {
        hookSpecificOutput => {
            hookEventName     => $args{event} // 'PostToolUse',
            updatedToolOutput => $output,
        },
    };
}

sub system_message {
    my ($class, $text) = @_;
    return { systemMessage => $text };
}

sub suppress_output {
    return { suppressOutput => \1 };
}

sub async {
    my ($class, %args) = @_;
    my $result = { async => \1 };
    $result->{asyncTimeout} = $args{timeout} if defined $args{timeout};
    return $result;
}

sub merge {
    my ($class, @results) = @_;
    my %merged;
    for my $result (@results) {
        next unless ref $result eq 'HASH';
        for my $key (keys %$result) {
            if ($key eq 'hookSpecificOutput' && ref $merged{$key} eq 'HASH' && ref $result->{$key} eq 'HASH') {
                $merged{$key} = { %{$merged{$key}}, %{$result->{$key}} };
            }
            else {
                $merged{$key} = $result->{$key};
            }
        }
    }
    return \%merged;
}

1;

__END__

=head1 NAME

Claude::Agent::Hook::Result - Build hook callback results

=head1 SYNOPSIS

    use Claude::Agent::Hook::Result;

    return Claude::Agent::Hook::Result->proceed;

    return Claude::Agent::Hook::Result->allow(
        updated_input => { command => 'safe command' },
        reason        => 'Modified for safety',
    );

    return Claude::Agent::Hook::Result->deny(
        reason => 'Operation not permitted',
    );

    return Claude::Agent::Hook::Result->merge(
        Claude::Agent::Hook::Result->add_context('The build is red.', event => 'UserPromptSubmit'),
        Claude::Agent::Hook::Result->system_message('Context added'),
    );

=head1 DESCRIPTION

Every method returns a plain hashref in the shape the CLI reads from a
hook, so a callback can also build the hash by hand. The permission
methods write C<hookSpecificOutput> for the event named by C<event>,
which defaults to C<PreToolUse>.

=head1 CLASS METHODS

=head2 proceed

An empty hash: the event continues as it would without the hook.

=head2 allow

    allow(reason => $text, updated_input => \%input, event => 'PreToolUse')

Let the tool run, bypassing the permission system, optionally with new
input.

=head2 deny

    deny(reason => $text, event => 'PreToolUse')

Stop the tool. The reason is shown to the model.

=head2 ask

    ask(reason => $text)

Make the CLI ask for permission as if no rule matched.

=head2 defer

    defer(reason => $text)

Let the CLI exit and resume later for a decision that takes a long time.

=head2 block

    block(reason => $text)

C<{ decision =E<gt> 'block', reason =E<gt> $text }>: for Stop, SubagentStop,
UserPromptSubmit and PostToolUse, where it blocks the stop, the prompt, or
feeds the reason back to the model.

=head2 stop

    stop(reason => $text)

C<{ continue =E<gt> false, stopReason =E<gt> $text }>: end the turn now.

=head2 add_context

    add_context($text, event => 'UserPromptSubmit')

Add text to the model's context for this event.

=head2 update_tool_output

    update_tool_output($output, event => 'PostToolUse')

Replace what the model sees as the tool's output.

=head2 system_message

    system_message($text)

Show a message to the person.

=head2 suppress_output

Hide the hook's output from the transcript.

=head2 async

    async(timeout => $seconds)

Tell the CLI the hook keeps running in the background.

=head2 merge

    merge(@results)

Combine several results into one hash; later keys win and
C<hookSpecificOutput> hashes are merged key by key.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
