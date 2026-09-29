# Copyright (c) 2023-2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: format independent identifier object


package Data::Identifier::Interface::Simple;

use v5.14;
use strict;
use warnings;

use Carp;

use Data::Identifier;

our $VERSION = v0.37;


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

version v0.37

=head1 SYNOPSIS

    use parent 'Data::Identifier::Interface::Simple';

(since v0.16, experimental)

This interface is for packages implementing some kind of identifier and/or objects having an identifier.

B<Note:>
This is formally an B<experimental> interface.
However, it become semi-stable (as of v0.36).
It may be changed, but is most unlikely to be renamed or removed.

See also L</FURTHER DIRECTIONS> for details.

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

=head1 FURTHER DIRECTIONS

=head2 FUTURE METHODS

To be future-safe this interface reserves the following methods:
C<displaycolour> (since v0.36),
C<icontext> (since v0.36).

Those methods may be used in the same or similar way as the corresponding methods in L<Data::Identifier>.

Future versions of this module may provide default implementations.

=head2 UNIVERSAL OPTIONS

Currently methods are defined by their counterparts in L<Data::Identifier>.
Future versions might clarify on this.

Currently the options C<default>, and C<no_defaults> are considered universal options.
They are most unlikely to be changed, or removed.

In respect to future work the following other options are currently reserved:
C<as> (since v0.36),
C<autocreate> (since v0.36),
C<context> (since v0.36),
C<language> (since v0.36),
C<language_tags> (since v0.36),
C<listas> (since v0.36),
C<list> (since v0.36),
C<online> (since v0.36),
C<rawtype> (since v0.36),
C<so> (since v0.36),
C<style> (since v0.36).

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
