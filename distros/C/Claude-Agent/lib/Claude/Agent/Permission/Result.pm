package Claude::Agent::Permission::Result;

use 5.020;
use strict;
use warnings;

use Object::Proto ();

BEGIN {
    Object::Proto::define('Claude::Agent::Permission::Result',
        'behavior:Str',
    );
}

sub to_hash {
    my ($self) = @_;
    return { behavior => $self->behavior };
}

1;

__END__

=head1 NAME

Claude::Agent::Permission::Result - Base class for permission results

=head1 DESCRIPTION

Base class for the answers a C<can_use_tool> callback returns. Use
L<Claude::Agent::Permission::Result::Allow> or
L<Claude::Agent::Permission::Result::Deny>, usually through
C<Claude::Agent::Permission-E<gt>allow> and C<-E<gt>deny>.

=head1 ATTRIBUTES

=head2 behavior

C<allow> or C<deny>. Set by the subclass.

=head1 METHODS

=head2 new

Takes a flat list of name/value pairs. Unknown names are ignored.

=head2 to_hash

    my $hash = $result->to_hash;

The result in the shape the CLI expects.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
