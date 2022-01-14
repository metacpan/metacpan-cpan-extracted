# Bio/RNA/BarMap/Mapping/MinMappingEntry.pm

package Bio::RNA::BarMap::Mapping::MinMappingEntry;
our $VERSION = '0.02';

use 5.012;
use warnings;

use Moose;
use namespace::autoclean;

use Scalar::Util qw( weaken );

use Bio::RNA::BarMap::Mapping::Type;
use Bio::RNA::BarMap::Mapping::Set;


has 'index' => (is => 'ro', required => 1);

has 'to_type' => (
    is => 'rw',
    isa => 'Bio::RNA::BarMap::Mapping::Type',
);

# Ensure object is cleaned after use => use weak refs
has '_from'  => (
    is       => 'ro',
    init_arg => undef,      # use add_from() method to add elements
    default  => sub { Bio::RNA::BarMap::Mapping::Set->new },
);

has 'to' => (
    is          => 'rw',
    weak_ref    => 1,
    predicate   => 'has_to',
    isa         => __PACKAGE__,             # another entry
);

# Always use this method to add 'from' minima. This ensures the refs
# are weakened and no memory leaks arise.
sub add_from {
    my ($self, @from) = @_;
    weaken $_ foreach @from;                # turn into weak references
    $self->_from->insert(@from);
}

sub get_from {
    my ($self) = @_;
    my @from = $self->_from->elements;
    return @from;
}

__PACKAGE__->meta->make_immutable;

1;          # End of Bio::RNA::BarMap::Mapping::MinMappingEntry


__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RNA::BarMap::Mapping::MinMappingEntry - Store I<BarMap> mappings of a
single minimum.

=head1 SYNOPSIS

    use v5.12;              # for 'say()' and '//' a.k.a. logical defined-or
    use Bio::RNA::BarMap;

    my $entry = Bio::RNA::BarMap::Mapping::MinMappingEntry->new(
        index   => 3,               # of minimum of this entry
        to      => $to_min,         # the mininimum this one is mapped to
    );

    # Query the entry.
    if ($entry->has_to) {           # maps to something
        say 'This minimum maps ',
            $entry->$to_type->is_exact ? 'exactly' : 'approximately',
            ' to minimum ', $entry->to->index;
    }

    $entry->add_from($from_min_1, $from_min_2);     # add mins mapping to self
    say "Minima mapped to this minimum:",
    join q{, }, map {$_->index $entry->get_from();


=head1 DESCRIPTION

Internal class used to store the mapping of a single minimum. Both the forward
direction ("target minimum", C<to()>) and the reverse direction ("source
minima", C<get_from()>) are provided. While the target minimum is unique, but
not necessarily defined (cf. C<has_to()>), there may be zero to many source
minima, and so these are stored in a set internally. Use C<add_from()> to add
to this set.

=head1 METHODS

=head2 Bio::RNA::BarMap::Mapping::MinMappingEntry->new(arg_name => $arg_val, ...)

Constructor of the mapping entry class.

=over

=item Supported arguments:

=over

=item index

Required. Index of the minimum described by this entry.

=item to

Optional. Reference to mapping entry object describing the minimum that this
minimum is mapped to.

=back

=item Non-argument:

=over

=item from

To add source minima (i. e. minima that are mapped to this minimum), use the
method C<add_from()> instead.

=back

=back

=head2 $entry->index

Index of the minimum this entry is representing.

=head2 $entry->to_type

Type of the "to" mapping, either exact or approximate. Object of type
L<Bio::RNA::BarMap::Mapping::Type>.

=head2 $entry->to

Returns the entry this minimum is being mapped to. May be C<undef>.

=head2 $entry->to($to_min_entry)

Sets the C<to> attribute to point to C<$to_min_entry>.

=head2 $entry->add_from(@from_entries)

Adds entries to the set of source minima, i. e. those that are mapped to this
minimum. This method makes sure that the stored references are properly
weakened and no memory leaks arise.

=head2 $entry->get_from

Returns the entries of minima that are mapped to this minimum, as stored in
the source minima set.

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

# End of Bio/RNA/BarMap/Mapping/MinMappingEntry.pm
