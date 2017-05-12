package DBIx::Class::ResultSet::Faceter::Facet;
use Moose::Role;

use DBIx::Class::ResultSet::Faceter::Types qw(Order);

=head1 NAME

DBIx::Class::ResultSet::Faceter::Facet - A Facet

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 min

The minimum number of values that a facet must have to be included.  Anything
B<less> than the value of this attribute will be discarded.

=cut

has 'min' => (
    is => 'ro',
    isa => 'Int',
    predicate => 'has_min'
);

=head2 name

The name of this facet.  This attribute is required.  It should be unique when
compared to any other facets used on the ResultSet.

=cut

has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

=head2 order

The sort order of this facet.  Defaults to 'desc'.  Valid values are C<desc>
and <asc>.

=cut

has 'order' => (
    is => 'ro',
    isa => Order,
    default => 'desc'
);

=head1 METHODS

=head2 has_min

Predicate for the C<min> attribute.

=head2 process

The process method is the only required method for something implementing this
role. When faceting the Facet class will be called once for each row in the
ResultSet that is being faceted. It is expected to return a string that will
place it into a facet. Any sorting, limiting, offseting or other operations
are handled by the role and not necessary.

=cut

requires 'process';

# Internal method used to prepare this data for use inside a Result... handles
# sorting and limiting and all that jazz.  Expects an argument of the data
# of a completed facet in the form of:
# {
#   facet_value_A => $count_A,
#   facet_value_B => $count_B,
# }
# etc, etc
sub _prepare {
    my ($self, $data) = @_;

    my @keys;

    if($self->has_min) {
        my $min = $self->min;
        foreach my $key (keys %{ $data }) {
            if($data->{$key} >= $min) {
                # We only add the keys that are greater than or equal to the
                # specified minimum.  Anything else we won't add, which
                # discards it.
                push(@keys, $key);
            }
        }
    } else {
        # No min, keys is all the keys we have
        @keys = keys(%{ $data });
    }

    if($self->order eq 'desc') {
        @keys = sort { $data->{$b} <=> $data->{$a} } @keys;
    } else {
        @keys = sort { $data->{$a} <=> $data->{$b} } @keys;
    }

    my @final = ();
    foreach my $key (@keys) {
        push(@final, { $key => $data->{$key} });
    }

    return \@final;
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

1;