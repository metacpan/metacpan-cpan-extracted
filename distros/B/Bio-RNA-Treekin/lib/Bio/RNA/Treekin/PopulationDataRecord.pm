# Bio/RNA/Treekin/PopulationDataRecord.pm
package Bio::RNA::Treekin::PopulationDataRecord;
our $VERSION = '0.02';

use 5.006;
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use autodie qw(:all);
use Scalar::Util qw(reftype looks_like_number);
use   List::Util qw(max all);

use overload '""' => \&stringify;

has 'time'  => (is => 'ro', required => 1);

has '_populations' => (
    is       => 'ro',
    required => 1,
    init_arg => 'populations',
);

# Return a deep copy of this object.
sub clone {
    my $self = shift;
    my $clone = __PACKAGE__->new(
        time        => $self->time,
        populations => [ $self->populations ],
    );
    return $clone;
}

# Return number of minima for which there is population data.
sub min_count {
    my $self = shift;
    my $min_count = @{ $self->_populations };   # number of data points

    return $min_count;
}

# Use to adjust the min count, e.g. when the passed data array was
# constructed before the number of minima was known. It may not be
# shrinked as data might be lost.
sub set_min_count {
    my ($self, $new_min_count) = @_;

    my $current_min_count = @{ $self->_populations };
    confess 'Can only increase min_count'
        if  $current_min_count > $new_min_count;

    # Set additional states to population of 0.
    for my $i ( $current_min_count..($new_min_count-1) ) {
        $self->_populations->[$i] = 0.;
    }

    return;
}

# Return populations of all mins. Use of_min() instead to get the
# population of a specific min.
# Returns a list of all minima's populations.
sub populations {
    my $self = shift;
    return @{ $self->_populations };
}

# Get population for the given minimum.
sub of_min {
    my ($self, $min) = @_;

    confess "Minimum $min is out of bounds"
        if $min < 1 or $min > $self->min_count;

    # Minimum 1 is the first one (index 0)
    my $population = $self->_populations->[$min-1];
    return $population;
}

# Transform (reorder and resize) the population data according to a given
# mapping and resize to a given minimum count. All minima that are not
# mapped to a new position are discarded (replaced by zero).
# NOTE: Ensure that no two minima are mapped to the same position or crap
# will happen.
# Arguments:
#   maps_to_min_ref: Hash ref that specifies for each kept minimum (key) to
#       which new minimum (value) it is supposed to be mapped.
#   new_min_count: New size (number of mins) of the record after the
#       transformation. Defaults to the maximum value of maps_to_min_ref.
# Void.
sub transform {
    my ($self, $maps_to_min_ref, $new_min_count) = @_;

    # If not explicitely given, use max value a min was mapped to as min count.
    $new_min_count //= max values %$maps_to_min_ref;

    my @new_pops = (0) x $new_min_count;    # new array with right size
    my @source_mins    = grep { defined $maps_to_min_ref->{$_} }
                              1..$self->min_count;      # filter unmapped
    my @source_indices = map  { $_ - 1 } @source_mins;
    my @target_indices = map  { $maps_to_min_ref->{$_} - 1 } @source_mins;

    # Sanity check.
    confess "Cannot reorder as some minima are not mapped correctly"
        unless all {$_ >= 0 and $_ < $new_min_count} @target_indices;

    # Copy population data to the correct positions and overwrite original.
    @new_pops[@target_indices] = @{$self->_populations}[@source_indices];
    @{ $self->_populations }   = @new_pops;

    return;
}

sub _parse_population_data_line {
    my ($self, $population_data_line) = @_;

    my ($time, @populations) = split /\s+/, $population_data_line;

    # Sanity checks.
    confess "No population data found in line:\n$population_data_line\n"
        unless @populations;
    confess "Time value '$time' is not a number"
        unless looks_like_number $time;
    # For the sake of performance, we do not test the numberness of the data.

    # Pack args for constructor.
    my @args = (
        time        => $time,
        populations => \@populations,
    );

    return @args;
}

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    return $class->$orig(@_) if @_ != 1 or reftype $_[0];

    # We have a population data line here.
    my $population_data_line = shift;
    my @args
        = $class->_parse_population_data_line($population_data_line);

    return $class->$orig(@args);
};

# Convert this data record back to a line as found in the Treekin file.
sub stringify {
    my $self = shift;

    # Format data like treekin C code
    my $self_as_string = sprintf "%22.20e ", $self->time;
    $self_as_string
        .= join q{ }, map {sprintf "%e", $_} @{ $self->_populations };

    # There seems to be a trailing space in the treekin C code
    # (printf "%e ") but there is none in the treekin simulator output.
    # $self_as_string .= q{ };

    return $self_as_string;
}

__PACKAGE__->meta->make_immutable;


1; # End of Bio::RNA::Treekin::PopulationDataRecord

__END__


=pod

=encoding UTF-8

=head1 NAME

Bio::RNA::Treekin::PopulationDataRecord - Parse, query, and manipulate a
single data line from a I<Treekin> file.

=head1 SYNOPSIS

    use Bio::RNA::Treekin;

    my $pop_data = Bio::RNA::Treekin::PopulationDataRecord->new(
                    '<single population data line from Treekin file>');

    print "Populations at time", $pop_data->time, ":\n";
    print "    min $_: ", $pop_data->of_min($_), "\n"
        for 1..$pop_data->min_count;

    my @big_pops = grep {$pop_data->of_min($_) > 0.1} 1..$pop_data->min_count;
    print 'Minima ', join(q{, }, @big_pops), ' have a population greater 0.1\n';



=head1 DESCRIPTION

This class provides a population data record that stores the information from
a single data line of a I<Treekin> file.


=head1 METHODS


=head2 Bio::RNA::Treekin::PopulationDataRecord->new($treekin_file_line)

Construct a new population data record from a single data line of a I<Treekin>
file.

=head2 Bio::RNA::Treekin::PopulationDataRecord->new(arg => $argval, ...)

Construct a new population data record.

=over

=item Required arguments:

=over

=item time

The point in time that the population data describes.

=item populations

Array ref of the population values for all minima.

=back

=back


=head2 $pop_data->min_count

Return the number of minima in this data record. This count is not stored
explicitely, but inferred from the number of populations supplied during
construction.

=head2 $pop_data->time

Return the point in time (in arbitrary time units) that the population data
describes.

=head2 $pop_data->clone

Return a deep copy of this data record.

=head2 $pop_data->set_min_count($new_min_count)

Increase the number of minima to C<$new_min_count>. The newly added minima
will have population values of 0.

Currently, the number of minima cannot be decreased to avoid data loss.

=head2 $pop_data->populations

Return a list of all population values for minima 1, 2, ..., n in this ordner.

=head2 $pop_data->of_min($minimum)

Return the population value of the given C<$minimum> at the C<time> of this
record.

=head2 $pop_data->transform($maps_to_min_ref, $new_min_count)

Transform (reorder and resize) the population data according to a given
mapping (C<$maps_to_min_ref>) and resize to a given number of minima
(C<$new_min_count>). All minima that are not mapped to a new position are
discarded (replaced by zero).

NOTE: Ensure that no two minima are mapped to the same position or crap
will happen.

=over

=item Arguments:

=over

=item $maps_to_min_ref:

Hash ref that specifies for each kept minimum (key) to which new minimum
(value) it is supposed to be mapped.

=item $new_min_count:

New size (number of mins) of the record after the transformation. Defaults to
the maximum value of C<$maps_to_min_ref>.

=back

=back

=head2 $pop_data->stringify

=head2 "$pop_data"

Convert this data record into a string representation, corresponding to a
single line as found in a I<Treekin> file.

=head1 AUTHOR

Felix Kuehnl, C<< <felix@bioinf.uni-leipzig.de> >>


=head1 BUGS

Please report any bugs or feature requests by raising an issue at
L<https://github.com/xileF1337/Bio-RNA-Treekin/issues>.

You can also do so by mailing to C<bug-bio-rna-treekin at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-RNA-Treekin>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::RNA::Treekin


You can also look for information at:

=over 4

=item * Github: the official repository

L<https://github.com/xileF1337/Bio-RNA-Treekin>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-RNA-Treekin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-RNA-Treekin>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Bio-RNA-Treekin>

=item * Search CPAN

L<https://metacpan.org/release/Bio-RNA-Treekin>

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

# End of Bio/RNA/Treekin/PopulationDataRecord.pm
