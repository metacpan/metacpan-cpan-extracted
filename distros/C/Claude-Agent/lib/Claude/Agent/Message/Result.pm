package Claude::Agent::Message::Result;

use 5.020;
use strict;
use warnings;

use Types::Common -types;
use Marlin
    -base => 'Claude::Agent::Message::Base',
    'subtype!'           => Str,     # 'success', 'error_*', etc.
    'result?'            => Str,     # Final result text
    'is_error?'          => Bool,
    'duration_ms?'       => Num,
    'duration_api_ms?'   => Num,     # API-specific duration
    'num_turns?'         => Int,
    'total_cost_usd?'    => Num,
    'usage?'             => HashRef, # Token usage stats
    'model_usage?'       => HashRef, # Per-model usage breakdown
    'permission_denials?' => ArrayRef, # Permission denial records
    'structured_output?' => Any,     # Parsed JSON for structured outputs
    'tool_use_result?'   => Any;     # Tool use result data

=head1 NAME

Claude::Agent::Message::Result - Result message type

=head1 DESCRIPTION

Represents the final result of a query.

=head2 ATTRIBUTES

=over 4

=item * type - Always 'result'

=item * subtype - Result type: 'success', 'error_max_turns', 'error_during_execution', etc.

=item * uuid - Unique message identifier

=item * session_id - Session identifier

=item * result - The final result text

=item * is_error - Boolean indicating if this is an error result

=item * duration_ms - Total duration in milliseconds

=item * num_turns - Number of conversation turns

=item * total_cost_usd - Total cost in USD

=item * usage - Token usage statistics

=item * structured_output - Parsed structured output if output_format was specified

=back

=head2 RESULT SUBTYPES

=over 4

=item * success - Query completed successfully

=item * error_max_turns - Reached maximum turn limit

=item * error_during_execution - Error occurred during execution

=item * error_max_structured_output_retries - Could not produce valid structured output

=back

=head2 METHODS

=head3 is_success

    if ($msg->is_success) { ... }

Helper to check if the result was successful.

=cut

sub is_success {
    my ($self) = @_;
    return $self->subtype eq 'success';
}

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut

1;
