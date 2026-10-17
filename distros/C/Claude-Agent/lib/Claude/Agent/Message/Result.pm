package Claude::Agent::Message::Result;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Message::Base;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::Result',
        extends => 'Claude::Agent::Message::Base',
        'subtype:Str:required',
        'result:predicate',
        'is_error:predicate',
        'duration_ms:predicate',
        'duration_api_ms:predicate',
        'num_turns:predicate',
        'total_cost_usd:predicate',
        'usage:predicate',
        'model_usage:predicate',
        'permission_denials:predicate',
        'structured_output:predicate',
        'tool_use_result:predicate',
        'stop_reason:predicate',
        'errors:predicate',
        'terminal_reason:predicate',
        'api_error_status:predicate',
        'user_message_uuid:predicate',
    );
}

sub is_success {
    my ($self) = @_;
    return $self->subtype eq 'success';
}

sub error_text {
    my ($self) = @_;
    if ($self->has_errors && ref $self->errors eq 'ARRAY' && @{$self->errors}) {
        return join('; ', @{$self->errors});
    }
    return $self->result if $self->has_result && length $self->result;
    return $self->subtype;
}

1;

__END__

=head1 NAME

Claude::Agent::Message::Result - Result message type

=head1 DESCRIPTION

Represents the final result of a turn.

=head1 ATTRIBUTES

=head2 type

Always C<result>.

=head2 subtype

C<success>, C<error_max_turns>, C<error_during_execution>,
C<error_max_budget_usd> or C<error_max_structured_output_retries>.

=head2 result

The final result text (success).

=head2 is_error

True for an error result. A JSON boolean decodes to a L<JSON::PP::Boolean>,
so test it for truth.

=head2 duration_ms

Total duration in milliseconds.

=head2 duration_api_ms

Time spent in API calls, in milliseconds.

=head2 num_turns

Number of conversation turns.

=head2 total_cost_usd

Estimated cost in USD.

=head2 usage

Token usage statistics for the main conversation.

=head2 model_usage

Per-model usage breakdown, sent by the CLI as C<modelUsage>.

=head2 permission_denials

Array of the tool uses that were denied during the turn.

=head2 structured_output

Parsed structured output when C<output_format> was given.

=head2 tool_use_result

Tool use result data.

=head2 stop_reason

The API stop reason of the last assistant message.

=head2 errors

Array of error strings (error subtypes).

=head2 terminal_reason

Why the turn ended, when the CLI says (for example after an interrupt).

=head2 api_error_status

HTTP status of a failing API call.

=head2 user_message_uuid

The uuid of the prompt this result answers; the value
C<rewind_files> takes.

=head2 uuid, session_id, parent_tool_use_id, agent_id, raw

See L<Claude::Agent::Message::Base>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 is_success

    if ($result->is_success) { ... }

True when the subtype is C<success>.

=head2 error_text

    my $why = $result->error_text;

The errors joined with C<; >, else the result text, else the subtype.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
