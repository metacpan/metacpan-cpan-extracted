package DBIx::Class::ResultSet::Faceter::Result;
use Moose;

=head1 NAME

DBIx::Class::ResultSet::Faceter::Facet - The result of a faceting operation

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 count

The number of facets in this result.

=head2 facets

A HashRef of facets in the form of:

  {
    'facet_name_1' => [
        { 'facet_value_A' => $count_A },
        { 'facet_value_B' => $count_B }
    ],
    'facet_name_2' => [
        { 'facet_value_A' => $count_A },
        { 'facet_value_B' => $count_B }
    ]
  }

The facets will be in whatever order you specified them to be in when you
added the facet to the L<DBIx::Class::ResultSet::Faceter>.

=cut

has 'facets' => (
    traits => [ qw(Hash) ],
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    handles => {
        count   => 'count',
        get     => 'get',
        names   => 'keys',
        set     => 'set'
    }
);


=head1 METHODS

=head2 count

Count of facets in this result.

=head2 names

An array of facet names in this Result.

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