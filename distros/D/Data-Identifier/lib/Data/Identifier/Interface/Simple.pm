# Copyright (c) 2023-2024 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Interface::Simple;

use v5.14;
use strict;
use warnings;

use Carp;

use Data::Identifier;

our $VERSION = v0.22;


sub as {
    my ($self, @args) = @_;
    return $self->Data::Identifier::as(@args);
}


sub displayname {
    my ($self, @args) = @_;
    return $self->as('Data::Identifier')->displayname(@args);
}


sub ise {
    my ($self, @args) = @_;
    return $self->as('Data::Identifier')->ise(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Identifier::Interface::Simple - format independent identifier object

=head1 VERSION

version v0.22

=head1 SYNOPSIS

    use parent 'Data::Identifier::Interface::Simple';

(since v0.16, experimental)

This interface is for packages implementing some kind of identifier and/or objects having an identifier.

B<Note:>
This is an B<experimental> interface. It may be changed, renamed, or removed without notice.

=head1 METHODS

=head2 as

    my $res = $obj->as($as, %opts);

This method implements the same interface and features as L<Data::Identifier/as>.

The default implementation is a proxy for L<Data::Identifier/as>.

=head2 displayname

    my $displayname = $obj->displayname( [ %opts ] );

This method returns a string suitable to display to the user.

The interface and options are the same as L<Data::Identifier/displayname>.

The default implementation is equivalent to:

    return $obj->as('Data::Identifier')->displayname(%opts);

=head2 ise

    my $ise = $onj->ise( [ %opts ] );

Returns the ISE (UUID, OID, or URI) for the current object or die if no ISE is known nor can be calculated.

The interface and options are the same as for L<Data::Identifier/ise>.

The default implementation is equivalent to:

    return $obj->as('Data::Identifier')->ise(%opts);

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
