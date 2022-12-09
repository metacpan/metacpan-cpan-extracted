# A simple set class implemented using a hash. Supports storing references.
# Faster then Set::Scalar for this specific use case. It significantly reduces
# the runtime.
package Bio::RNA::BarMap::Mapping::Set;
our $VERSION = '0.04';

use v5.12;
use warnings;

use autodie qw(:all);
use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use List::Util qw(pairmap);

# Elements are stored in a hash ref. For simple values, key is the element
# and value is undef. For references, the key gets stringified and the
# value stores the actual reference.
has _elems => (is => "ro", init_arg => undef, default => sub { {} });

# Return all elements. If defined, use the value, else the key.
sub elements { pairmap {$b // $a} %{ $_[0]->_elems } }

# Insert elements into the set. Returns itself.
sub insert {
    my $self = shift;
    # Don't store simple values twice, but preserve references.
    $self->_elems->{$_} = ref $_ ? $_ : undef foreach @_;
    $self;
}

__PACKAGE__->meta->make_immutable;

1; # End of Bio::RNA::BarMap::Mapping::Set


__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RNA::BarMap::Mapping::Set - Internally used class to store sets

=head1 SYNOPSIS

    use v5.12;              # for 'say()' and '//' a.k.a. logical defined-or
    use Bio::RNA::BarMap;

    # Construct new, empty set.
    my $set = Bio::RNA::BarMap::Mapping::Set->new();

    # Insert elements.
    $set->insert( qw(hello there foo) );

    # Retrieve elements.
    say "Elements in set: ", join q{, }, $set->elements;

=head1 DESCRIPTION

A simple, pure-Perl implementation of a set data structure. It is
significantly faster than L<Set::Scalar>, which became a bottleneck during the
implementation of this module. It supports storing references, but no deep
equality checks are performed.

=head1 METHODS

=head2 Bio::RNA::BarMap::Mapping::Set->new()

Returns a new, empty set. Adding elements during construction is currently not
supported (for no specific reason), use the C<insert()> method instead.

=head2 $set->elements()

Return all items contained in this set.

=head2 $set->insert(@elements)

Insert one or more C<@elements> into the set. Supports references.


=head1 AUTHOR

Felix Kuehnl, C<< <felix at bioinf.uni-leipzig.de> >>


=head1 BUGS

Please report any bugs or feature requests by raising an issue at
L<https://github.com/xileF1337/Bio-RNA-BarMap/issues>.

You can also do so by mailing to C<bug-bio-rna-barmap at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-RNA-BarMap>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::RNA::BarMap


You can also look for information at the official BarMap website:

L<https://www.tbi.univie.ac.at/RNA/bar_map/>


=over 4

=item * Github: the official repository

L<https://github.com/xileF1337/Bio-RNA-BarMap>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-RNA-BarMap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-RNA-BarMap>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Bio-RNA-BarMap>

=item * Search CPAN

L<https://metacpan.org/release/Bio-RNA-BarMap>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2019-2021 Felix Kuehnl.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

# End of Bio/RNA/BarMap/Mapping/Set.pm
