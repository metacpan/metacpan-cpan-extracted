# All methods are class methods, it's not meant to be instantiated. It just
# manages the type name string and converts it to arrows, etc.
package Bio::RNA::BarMap::Mapping::Type;
our $VERSION = '0.01';

use 5.012;
use warnings;

use Moose;
use Moose::Util::TypeConstraints;           # for enum()
use namespace::autoclean;


has '_type' => (
    is       => 'ro',
    isa      => enum([qw(EXACT APPROX)]),
    required => 1,
);

# Only allow construction from a single arrow string.
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    confess 'Pass a single arrow string to construct a Mapping::Type object'
        if @_ != 1 or ref $_[0];

    my $arrow = shift;                              # arrow string passed
    if ($arrow eq '->') {
        return $class->$orig(_type => 'EXACT')
    }
    elsif ($arrow eq '~>') {
        return $class->$orig(_type => 'APPROX')
    }
    else {
        confess 'Unknown arrow string in constructor';
    }
};

# Returns a new mapping type object of type 'exact'.
sub exact  { return $_[0]->new('->');  }

# Returns a new mapping type object of type 'approx'.
sub approx { return $_[0]->new('~>'); }

# Returns true iff the object is of EXACT type.
sub is_exact {
    my ($self) = @_;
    return $self->_type() eq 'EXACT';
}

# Returns true iff the object is of APPROX type.
sub is_approx {
    my ($self) = @_;
    return $self->_type() eq 'APPROX';
}

# Return the arrow representation of this object, i.e. '->' for exact and '~>'
# for approx mapping type objects.
sub arrow {
    my ($self) = @_;
    return $self->is_exact ? '->' : '~>';
}


__PACKAGE__->meta->make_immutable;

1;              # End of Bio::RNA::BarMap::Mapping::Type


__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RNA::BarMap::Mapping::Type - Represents the type of a I<BarMap> mapping
(exact or approximate)

=head1 SYNOPSIS

    use v5.12;                                              # for 'say'
    use Bio::RNA::BarMap;

    # Get a new mapping type object ... from arrow string:
    my $type = Bio::RNA::BarMap::Mapping::Type->new('->');  # exact
       $type = Bio::RNA::BarMap::Mapping::Type->new('~>');  # approx

    # ... or programmatically:
    $type = Bio::RNA::BarMap::Mapping::Type->exact;         # exact
    $type = Bio::RNA::BarMap::Mapping::Type->approx;        # approx

    # Verify mapping type.
    say 'Mapping is ', $type->is_exact  ? 'exact' : 'approximate';
    say 'Mapping arrow: ', $type->arrow;


=head1 DESCRIPTION

The objects of this class are used to represent the two possible types of a
mapping, either exact or approximate, and to easily convert between these two
values and their respective arrow representation. In I<BarMap> files,
C<< -> >> denotes an exact mapping, and C<< ~> >> an approximate one. The
object is constructed from the arrow string via the constructor C<new()>, or
using the methods C<exact()> and C<approx()> to get a new object of the
respective type.


=head1 METHODS

=head2 Bio::RNA::BarMap::Mapping::Type->new($arrow_string)

Constructs a new type object from its arrow string representation, i. e.
C<< -> >> for the exact and C<< ~> >> for the approximate variant.

=head2 Bio::RNA::BarMap::Mapping::Type->exact()

Class method. Returns a new mapping type object of I<exact> type.

=head2 Bio::RNA::BarMap::Mapping::Type->approx()

Class method. Returns a new mapping type object of I<approximate> type.

=head2 $type->is_exact()

Returns true iff the current object is of I<exact> type.

=head2 $type->is_approx()

Returns true iff the current object is of I<approximate> type.

=head2 $type->arrow()

Returns the type of this object in its arrow string representation, i. e.
C<< -> >> for the exact and C<< ~> >> for the approximate.

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


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2019 Felix Kuehnl.

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

# End of Bio::RNA::BarMap::Mapping::Type / lib/Bio/RNA/BarMap/Mapping/Type.pm
