package DBIx::Class::ResultSet::Faceter::Facet::HashRef;
use Moose;

with 'DBIx::Class::ResultSet::Faceter::Facet';

=head1 NAME

DBIx::Class::ResultSet::Faceter::Facet::HashRef - Faceting on a HashRef

=head1 SYNOPSIS

  $faceter->add_facet('HashRef', {
	name => 'Last Name', key => 'name_last'
  });

=head1 DESCRIPTION

Used when the "row" is a plain HashRef, as created by the DBIx::Class
HashRefInflator.

=head1 ATTRIBUTES

=head2 key

The name of the key to facet on.

=cut

has 'key' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

=head1 METHODS

=head2 process

Returns the name of the specified column.

=cut

sub process {
    my ($self, $row) = @_;

    return $row->{$self->key};
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