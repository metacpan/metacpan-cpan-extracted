package Claude::Agent::Message::RateLimitEvent;

use 5.020;
use strict;
use warnings;

use Object::Proto ();
use Claude::Agent::Message::Base;

BEGIN {
    Object::Proto::define('Claude::Agent::Message::RateLimitEvent',
        extends => 'Claude::Agent::Message::Base',
        'rate_limit_info:HashRef:required',
    );
}

sub status          { $_[0]->rate_limit_info->{status} }
sub resets_at       { $_[0]->rate_limit_info->{resetsAt} }
sub rate_limit_type { $_[0]->rate_limit_info->{rateLimitType} }
sub utilization     { $_[0]->rate_limit_info->{utilization} }
sub overage_status  { $_[0]->rate_limit_info->{overageStatus} }

1;

__END__

=head1 NAME

Claude::Agent::Message::RateLimitEvent - Rate limit status event

=head1 DESCRIPTION

Emitted when the CLI learns the account's rate limit status from an API
response.

=head1 ATTRIBUTES

=head2 type

Always C<rate_limit_event>.

=head2 rate_limit_info

The status hash as the CLI sent it, with its camelCase keys.

=head2 uuid, session_id, parent_tool_use_id, agent_id, raw

See L<Claude::Agent::Message::Base>.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 status

C<allowed>, C<allowed_warning>, C<rejected> or whatever the CLI reports.

=head2 resets_at

Unix time at which the limit resets.

=head2 rate_limit_type

Which limit the event is about.

=head2 utilization

Fraction of the limit used.

=head2 overage_status

The overage state, when the CLI reports one.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
