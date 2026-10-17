package Claude::Agent::Content::Thinking;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Content::Thinking',
        'type:Str:readonly:default(thinking)',
        'thinking:Str:required',
        'signature:Str:predicate',
        'raw:HashRef:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Content::Thinking - Thinking content block

=head1 DESCRIPTION

A thinking content block containing Claude's reasoning. Present only when extended thinking is enabled.

=head1 ATTRIBUTES

=head2 type

Always C<thinking>. Read only.

=head2 thinking

The reasoning text.

=head2 signature

Optional signature for verification. C<has_signature> reports whether it was given.

=head2 raw

The decoded block as the CLI sent it, when the object was built by
C<Claude::Agent::Content-E<gt>from_json>. Keys the class does not declare are
reachable here.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
