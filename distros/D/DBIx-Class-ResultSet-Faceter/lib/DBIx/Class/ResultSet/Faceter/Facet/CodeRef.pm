package DBIx::Class::ResultSet::Faceter::Facet::CodeRef;
use Moose;

with 'DBIx::Class::ResultSet::Faceter::Facet';

=head1 NAME

DBIx::Class::ResultSet::Faceter::Facet::CodeRef - Faceting via a CodeRef

=head1 SYNOPSIS

  $faceter->add_facet('CodeRef', {
	name => 'Fancy User Stuff',
	code => sub { my $row = shift; # Do something crazy with #row }
  });

=head1 DESCRIPTION

Used when the row isn't capable (alone) of doing what is needed.  Allows a
CodeRef that is invoked for each row.  The return value of the CodeRef is
used as the facet.

=head1 ATTRIBUTES

=head2 code

The name of the key to facet on.

=cut

has 'code' => (
    traits => [ 'Code' ],
    is => 'ro',
    isa => 'CodeRef',
    required => 1,
    handles => {
        execute => 'execute'
    }
);

=head1 METHODS

=head2 process

Returns the name of the specified column.

=cut

sub process {
    my ($self, $row) = @_;

    return $self->execute($row);
}

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cold Hard Code, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__->meta->make_immutable;

1;