package Claude::Agent::Content::Text;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Content::Text',
        'type:Str:readonly:default(text)',
        'text:Str:required',
        'raw:HashRef:predicate',
    );
}

1;

__END__

=head1 NAME

Claude::Agent::Content::Text - Text content block

=head1 DESCRIPTION

A text content block containing Claude's response text.

=head1 ATTRIBUTES

=head2 type

Always C<text>. Read only.

=head2 text

The text content.

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
