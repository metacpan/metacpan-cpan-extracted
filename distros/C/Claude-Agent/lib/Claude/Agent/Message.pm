package Claude::Agent::Message;

use 5.020;
use strict;
use warnings;

use Claude::Agent::Types;
use Claude::Agent::Message::Base;
use Claude::Agent::Message::User;
use Claude::Agent::Message::Assistant;
use Claude::Agent::Message::System;
use Claude::Agent::Message::HookEvent;
use Claude::Agent::Message::Result;
use Claude::Agent::Message::StreamEvent;
use Claude::Agent::Message::RateLimitEvent;
use Claude::Agent::Message::ToolProgress;

my %CLASS_FOR = (
    user             => 'Claude::Agent::Message::User',
    assistant        => 'Claude::Agent::Message::Assistant',
    system           => 'Claude::Agent::Message::System',
    result           => 'Claude::Agent::Message::Result',
    stream_event     => 'Claude::Agent::Message::StreamEvent',
    rate_limit_event => 'Claude::Agent::Message::RateLimitEvent',
    tool_progress    => 'Claude::Agent::Message::ToolProgress',
);

my %HOOK_SUBTYPE = map { $_ => 1 } qw(hook_started hook_progress hook_response);

sub _camel_to_snake {
    my ($str) = @_;
    return $str unless defined $str;
    $str =~ s/([A-Z]+)([A-Z][a-z])/${1}_$2/g;
    $str =~ s/([a-z\d])([A-Z])/${1}_$2/g;
    return lc($str);
}

sub _normalize_data {
    my ($data) = @_;

    my %normalized;
    for my $key (keys %$data) {
        $normalized{ _camel_to_snake($key) } = $data->{$key};
    }

    return \%normalized;
}

sub from_json {
    my ($class, $data) = @_;

    my $normalized = _normalize_data($data);
    my $type = $normalized->{type} // '';
    my $target = $CLASS_FOR{$type} // 'Claude::Agent::Message::Base';

    if ($type eq 'system' && $HOOK_SUBTYPE{ $normalized->{subtype} // '' }) {
        $target = 'Claude::Agent::Message::HookEvent';
    }

    return $target->new(
        Claude::Agent::Types::known_args($target, $normalized),
        raw => $data,
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Message - Message types for Claude Agent SDK

=head1 SYNOPSIS

    use Claude::Agent::Message;

    my $msg = Claude::Agent::Message->from_json($decoded);

    if ($msg->isa('Claude::Agent::Message::Assistant')) {
        print $msg->text;
    }
    elsif ($msg->isa('Claude::Agent::Message::Result')) {
        print $msg->result;
    }

=head1 DESCRIPTION

This module loads every message class and provides the factory that turns a
decoded line of the CLI's stream-json output into an object.

=head1 MESSAGE TYPES

=over 4

=item * L<Claude::Agent::Message::User> - type C<user>

=item * L<Claude::Agent::Message::Assistant> - type C<assistant>

=item * L<Claude::Agent::Message::System> - type C<system>

=item * L<Claude::Agent::Message::HookEvent> - type C<system>, hook subtypes

=item * L<Claude::Agent::Message::Result> - type C<result>

=item * L<Claude::Agent::Message::StreamEvent> - type C<stream_event>

=item * L<Claude::Agent::Message::RateLimitEvent> - type C<rate_limit_event>

=item * L<Claude::Agent::Message::ToolProgress> - type C<tool_progress>

=item * L<Claude::Agent::Message::Base> - every other type

=back

=head1 METHODS

=head2 from_json

    my $msg = Claude::Agent::Message->from_json($data);

Builds the message object for C<$data-E<gt>{type}>. The top-level keys are
converted from camelCase to snake_case before they are matched to
attributes, so C<sessionId>, C<durationMs>, C<totalCostUsd>, C<numTurns>,
C<isError>, C<modelUsage>, C<apiKeySource> and C<permissionMode> arrive as
C<session_id>, C<duration_ms> and so on. Nested hashes are not touched.
Keys the class does not declare are not lost: the decoded hash is kept as
it was sent in the object's C<raw> attribute. A key whose value is JSON null
is treated as absent. A type with no class of its own becomes a
L<Claude::Agent::Message::Base>; a message with no C<type> dies.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
