# Bio/RNA/Treekin/Record.pm

# Stores a data from a single row of the Treekin file, i.e. the populations of
# all minima at a given time point.
package Bio::RNA::Treekin::Record;
our $VERSION = '0.05';

use v5.14;                          # required for non-destructive subst m///r
use strict;
use warnings;

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

use autodie qw(:all);
use Scalar::Util qw(reftype openhandle);
use List::Util qw(first pairmap max uniqnum all);
use Carp qw(croak);

use Bio::RNA::Treekin::PopulationDataRecord;

use overload '""' => \&stringify;


has '_population_data'  => (
    is       => 'ro',
    required => 1,
    init_arg => 'population_data',
);

has 'date'              => (is => 'ro', required => 1);
has 'sequence'          => (is => 'ro', required => 1);
has 'method'            => (is => 'ro', required => 1);
has 'start_time'        => (is => 'ro', required => 1);
has 'stop_time'         => (is => 'ro', required => 1);
has 'temperature'       => (is => 'ro', required => 1);
has 'basename'          => (is => 'ro', required => 1);
has 'time_increment'    => (is => 'ro', required => 1);
has 'degeneracy'        => (is => 'ro', required => 1);
has 'absorbing_state'   => (is => 'ro', required => 1);
has 'states_limit'      => (is => 'ro', required => 1);

# Add optional attributes including predicate.
has $_ => (
               is        => 'ro',
               required  => 0,
               predicate => "has_$_",
          )
    foreach qw(
                 info
                 init_population
                 rates_file
                 file_index
                 cmd
                 of_iterations
            );

# Get number of population data rows stored.
sub population_data_count {
    my ($self) = @_;

    my $data_count = @{ $self->_population_data };
    return $data_count;
}

# Number of states / minima in this simulation.
# Get number of mins in the first population record; it should be the
# same for all records.
sub min_count {
    my $self = shift;

    my $first_pop = $self->population(0);
    confess 'min_count: no population data present'
        unless defined $first_pop;

    my $min_count = $first_pop->min_count;

    return $min_count;
}

# Return a list of all minima, i. e. 1..n, where n is the total number of
# minima.
sub mins {
    my ($self) = @_;
    my @mins = 1..$self->min_count;

    return @mins;
}

# Keep only the population data for the selected minima, remove all other.
# Will NOT rescale populations, so they may no longer sum up to 1.
# Arguments:
#   mins: List of mins to keep. Will be sorted and uniq'ed (cf. splice()).
# Returns the return value of splice().
sub keep_mins {
    my ($self, @kept_mins) = @_;
    @kept_mins = uniqnum sort {$a <=> $b} @kept_mins;   # sort / uniq'ify
    return $self->splice_mins(@kept_mins);
}

# Keep only the population data for the selected minima, remove all other.
# May duplicate and re-order.
#   mins: List of mins to keep. Will be used as is.
# Returns itself.
sub splice_mins {
    my ($self, @kept_mins) = @_;

    my $min_count = $self->min_count;
    confess 'Cannot splice, minimum out of bounds'
        unless all {$_ >= 1 and $_ <= $min_count} @kept_mins;

    # Directly update raw population data here instead of doing tons of
    # calls passing the same min array.
    my @kept_indices = map {$_ - 1} @kept_mins;
    for my $pop_data (@{$self->_population_data}) { # each point in time
        my $raw_pop_data = $pop_data->_populations;
        @{$raw_pop_data} = @{$raw_pop_data}[@kept_indices];
    }

    return $self;
}

# Get the maximal population for the given minimum over all time points.
sub max_pop_of_min {
    my ($self, $min) = @_;
    my $max_pop = '-Inf';
    for my $pop_data (@{$self->_population_data}) { # each point in time
        $max_pop = max $max_pop, $pop_data->of_min($min);   # update max
    }
    return $max_pop;
}

# For a given minimum, return all population values in chronological
# order.
# Arguments:
#   min: Minimum for which to collect the population data.
# Returns a list of population values in chronological order.
sub pops_of_min {
    my ($self, $min) = @_;

    my @pops_of_min = map { $_->of_min($min) } $self->populations;

    return @pops_of_min;
}

# Final population data record, i.e. the result of the simulation.
sub final_population {
    my ($self) = @_;

    my $final_population_data
        = $self->population($self->population_data_count - 1);

    return $final_population_data;
}

# Get the i-th population data record (0-based indexing).
sub population {
    my ($self, $i) = @_;

    my $population_record = $self->_population_data->[$i];
    return $population_record;
}

# Return all population data records.
sub populations {
    return @{ $_[0]->_population_data };
}

# Add a new minimum with all-zero entries. Data can then be appended to
# this new min.
# Returns the index of the new minimum.
sub add_min {
    my $self = shift;
    my $new_min_count = $self->min_count + 1;

    # Increase the min count of all population data records by one.
    $_->set_min_count($new_min_count)
        foreach @{ $self->_population_data }, $self->init_population;

    return $new_min_count;              # count == highest index
}

# Given a list of population data records, append them to the population data
# of this record. The columns of the added data can be re-arranged on the fly by
# providing a mapping (hash ref) giving for each minimum in the population
# data to be added (key) a minimum in the current population data
# (value) to which the new minimum should be swapped. If no data is provided
# for some minimum of this record, its population is set to zero in the
# newly added entries.
# Arguments:
#   pop_data_ref:   ref to the array of population data to be added
#   append_to_min_ref:
#       hash ref describing which mininum in pop_data_ref (key)
#       should be mapped to which minimum in this record (value)
# The passed population data objects are modified.
sub append_pop_data {
    my ($self, $pop_data_ref, $append_to_min_ref) = @_;

    if (defined $append_to_min_ref) {
        my $min_count = $self->min_count;
        $_->transform($append_to_min_ref, $min_count) foreach @$pop_data_ref;
    }

    push @{ $self->_population_data }, @$pop_data_ref;

    return;
}

# Decode a single header line into a key and a value, which are returned.
sub _get_header_line_key_value {
    my ($class, $header_line) = @_;

    # key and value separated by first ':' (match non-greedy!)
    my ($key, $value) = $header_line =~ m{ ^ ( .+? ) : [ ] ( .* ) $ }x;

    confess "Invalid key in header line:\n$header_line"
        unless defined $key;

    # Convert key to lower case and replace spaces by underscores.
    $key = (lc $key) =~ s/\s+/_/gr;

    return ($key, $value);
}

# Decode the initial population from the Treekin command line. The
# population is given as multiple --p0 a=x switches, where a is the state
# index and x is the fraction of population initially present in this
# state.
# Arguments:
#   command: the command line string used to call treekin
# Returns a hash ref containing the initial population of each state a at
# position a (1-based).
sub _parse_init_population_from_cmd {
    my ($class, $command) = @_;

    my @command_parts = split /\s+/, $command;

    # Extract the initial population strings given as (multiple) arguments
    # --p0 to Treekin from the Treekin command.
    my @init_population_strings;
    while (@command_parts) {
        if (shift @command_parts eq '--p0') {
            # Next value should be a population value.
            confess 'No argument following a --p0 switch'
                unless @command_parts;
            push @init_population_strings, shift @command_parts;
        }
    }

    # Store population of state i in index i-1.
    my @init_population;
    foreach my $init_population_string (@init_population_strings) {
        my ($state, $population) = split /=/, $init_population_string;
        $init_population[$state-1] = $population;
    }

    # If no population was specified on the cmd line, init 100% in state 1
    $init_population[0] = 1 unless @init_population_strings;

    # Set undefined states to zero.
    $_ //= 0. foreach @init_population;

    my $init_population_record
        = Bio::RNA::Treekin::PopulationDataRecord->new(
            time        => 0,
            populations => \@init_population,
    );
    return $init_population_record;
}

sub _parse_header_lines {
    my ($class, $header_lines_ref) = @_;

    my @header_args;
    foreach my $line (@$header_lines_ref) {
        my ($key, $value) = $class->_get_header_line_key_value($line);

        # Implement special handling for certain keys.
        if ($key eq 'rates_file') {
            # remove (#index) from file name and store the value
            my ($file_name, $file_index)
                = $value =~ m{ ^ (.+) [ ] [(] [#] (\d+) [)] $ }x;
            push @header_args, (
                rates_file  => $file_name,
                file_index  => $file_index,
            );
        }
        elsif ($key eq 'cmd') {
            # Extract initial population from Treekin command.
            my $init_population_ref
                = $class->_parse_init_population_from_cmd($value);
            push @header_args, (
                cmd             => $value,
                init_population => $init_population_ref,
            );
        }
        else {
            # For the rest, just push key and value as constructor args.
            push @header_args, ($key => $value);
        }
    }
    return @header_args;
}


# Read all lines from the given handle and separate it into header lines
# and data lines.
sub _read_record_lines {
    my ($class, $record_handle) = @_;

    # Separate lines into header and population data.  All header lines
    # begin with a '# ' (remove it!)
    # Note: Newer versions of treekin also add header info *below* data lines.
    my ($current_line, @header_lines, @population_data_lines);
    while (defined ($current_line = <$record_handle>)) {
        next if $current_line =~ /^@/               # drop xmgrace annotations
                or $current_line =~ m{ ^ \s* $ }x;  # or empty lines

        # Header lines start with '# ', remove it.
        if ($current_line =~ s/^# //) {         # header line
            push @header_lines, $current_line;
        }
        else {                                  # data line
            push @population_data_lines, $current_line;
        }
    }

    # Sanity checks.
    confess 'No header lines found in Treekin file'
        unless @header_lines;
    chomp @header_lines;

    confess 'No population data lines found in Treekin file'
        unless @population_data_lines;
    chomp @population_data_lines;

    return \@header_lines, \@population_data_lines;
}

sub _parse_population_data_lines {
    my ($class, $population_data_lines_ref) = @_;

    my @population_data
        = map { Bio::RNA::Treekin::PopulationDataRecord->new($_) }
              @$population_data_lines_ref
              ;

    return (population_data => \@population_data);
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    # Call original constructor if passed more than one arg.
    return $class->$orig(@_) unless @_ == 1;

    # Retrive file handle or pass on hash ref to constructor.
    my $record_handle;
    if (reftype $_[0]) {
        if (reftype $_[0] eq reftype {}) {          # arg hash passed,
            return $class->$orig(@_);               # pass on as is
        }
        elsif (reftype $_[0] eq reftype \*STDIN) {  # file handle passed
            $record_handle = shift;
        }
        else {
            croak 'Invalid ref type passed to constructor';
        }
    }
    else {                                          # file name passed
        my $record_file = shift;
        open $record_handle, '<', $record_file;
    }

    # Read in file.
    my ($header_lines_ref, $population_data_lines_ref)
        = $class->_read_record_lines($record_handle);

    # Parse file.
    my @header_args = $class->_parse_header_lines($header_lines_ref);
    my @data_args
        = $class->_parse_population_data_lines($population_data_lines_ref);

    my %args = (@header_args, @data_args);
    return $class->$orig(\%args);
};

sub BUILD {
    my $self = shift;

    # Force construction despite laziness.
    $self->min_count;

    # Adjust min count of initial population as it was not known when
    # initial values were extracted from Treekin cmd.
    $self->init_population->set_min_count( $self->min_count )
        if $self->has_init_population;
}

sub stringify {
    my $self = shift;

    # Format header line value of rates file entry.
    my $make_rates_file_val = sub {
        $self->rates_file . ' (#' . $self->file_index . ')';
    };

    # Header
    my @header_entries = (
        $self->has_rates_file ? ('Rates file' => $make_rates_file_val->()) : (),
        $self->has_info       ? ('Info'       => $self->info)   : (),
        $self->has_cmd        ? ('Cmd'        => $self->cmd)    : (),
        'Date'            => $self->date,
        'Sequence'        => $self->sequence,
        'Method'          => $self->method,
        'Start time'      => $self->start_time,
        'Stop time'       => $self->stop_time,
        'Temperature'     => $self->temperature,
        'Basename'        => $self->basename,
        'Time increment'  => $self->time_increment,
        'Degeneracy'      => $self->degeneracy,
        'Absorbing state' => $self->absorbing_state,
        'States limit'    => $self->states_limit,
    );

    my $header_str = join "\n", pairmap { "# $a: $b" } @header_entries;

    # Population data
    my $population_str
        = join "\n", map { "$_" } @{ $self->_population_data };

    # Footer (new Treekin versions only).
    my $footer_str = $self->has_of_iterations
                     ? '# of iterations: ' . $self->of_iterations
                     : q{};

    my $self_as_str  = $header_str . "\n" . $population_str;
    $self_as_str    .= "\n" . $footer_str if $footer_str;

    return $self_as_str;
}

__PACKAGE__->meta->make_immutable;

1;  # End of Bio::RNA::Treekin::Record


__END__


=pod

=encoding UTF-8

=head1 NAME

Bio::RNA::Treekin::Record - Parse, query, and manipulate I<Treekin> output.

=head1 SYNOPSIS

    use Bio::RNA::Treekin;

=head1 DESCRIPTION

Parses a regular output file of I<Treekin>. Allows to query population data
as well as additional info from the header. New minima can be generated. The
stringification returns, again, a valid I<Treekin> file which can be, e. g.,
visualized using I<Grace>.

=head1 ATTRIBUTES

These attributes of the class allow to query various data from the header of
the input file.

=head2 date

The time and date of the I<Treekin> run.

=head2 sequence

The RNA sequence for which the simulation was computed.

=head2 method

The method used to build the transition matrix as documented for the
C<--method> switch of I<Treekin>.

=head2 start_time

Initial time of the simulation.

=head2 stop_time

Time at which the simulation stops.

=head2 temperature

Temperature of the simulation in degrees Celsius.

=head2 basename

Name of the input file. May be C<< <stdin> >> if data was read from standard
input.

=head2 time_increment

Factor by which the time is multiplied in each simulation step (roughly, the
truth is more complicated).

=head2 degeneracy

Whether to consider degeneracy in transition rates.

=head2 absorbing_state

The states specified as absorbing do not have any outgoing transitions and
thus serve as "population sinks" during the simulation.

=head2 states_limit

Maximum number of states (???). Value is always (?) 2^31 = 2147483647.

=head2 info

A free text field containing additional comments.

Only available in I<some> of the records of a I<BarMap> multi-record file. Use
predicate C<has_info> to check whether this attribute is available.

=head2 init_population

The initial population specified by the user. This information is extracted
from the C<cmd> attribute.

Only available in I<BarMap>'s multi-record files. Use predicate
C<has_init_population> to check whether this attribute is available.

=head2 rates_file

The file that the rate matrix was read from.

Only available in I<BarMap>'s multi-record files. Use predicate
C<has_rates_file> to check whether this attribute is available.

=head2 file_index

Zero-based index given to the input files in the order they were read.
Extracted from the C<rates_file> attribute.

Use predicate C<has_file_index> to check whether this attribute is available.

=head2 cmd

The command used to invoke I<Treekin>. Only available in I<BarMap>'s
multi-record files.

Use predicate C<has_cmd> to check whether this attribute is available.


=head1 METHODS

These methods allow the construction, querying and manipulation of the record
objects and its population data.

=head2 Bio::RNA::Treekin::Record->new($treekin_file)

=head2 Bio::RNA::Treekin::Record->new($treekin_handle)

Construct a new record from a (single) I<Treekin> file.

=head2 $record->population_data_count

Return the number of population data records, i. e. the number of simulated
time steps, including the start time.

=head2 $record->min_count

Return the number of minima.

=head2 $record->mins

Return the list of all contained minima, i. e. C<< 1...$record->min_count >>

=head2 $record->keep_mins(@kept_minima)

Remove all minima but the ones from C<@kept_minima>. The list is sorted and
de-duplicated first.

=head2 $record->splice_mins(@kept_minima)

Like C<keep_mins()>, but do not sort / de-duplicate, but use C<@kept_minima>
as is. This can be used to remove, duplicate or reorder minima.

=head2 $record->max_pop_of_min($minimum)

Get the maximum population value of all time points for a specific C<$minimum>.

=head2 $record->pops_of_min($minimum)

Get a list of the populations at all time points (in chronological order) for
a single C<$minimum>.

=head2 $record->final_population

Get the last population data record, an object of class
L<Bio::RNA::Treekin::PopulationDataRecord>. It contains the population data
for all minima at the C<stop_time>.

=head2 $record->population($i)

Get the C<$i>-th population data record, an object of class
L<Bio::RNA::Treekin::PopulationDataRecord>. C<$i> is a zero-based index in
chronological order.

=head2 $record->populations

Returns the list of all population data records. Useful for iterating.

=head2 $record->add_min

Add a single new minimum with all-zero entries. Data can then be appended to
this new min using C<append_pop_data()>.

Returns the index of the new minimum.

=head2 $record->append_pop_data($pop_data_ref, $append_to_min_ref)

Given a list of population data records C<$pop_data_ref>, append them to the
population data of this record.

The columns of the added data can be
re-arranged on the fly by providing a mapping C<$append_to_min_ref> (a hash
ref) giving for each minimum in C<$pop_data_ref> (key) a
minimum in the current population data (value) to which the new minimum should
be swapped. If no data is provided for some minimum of this record, its
population is set to zero in the newly added entries.

=head2 $record->stringify

=head2 "$record"

Returns the record as a I<Treekin> file.

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

# End of Bio/RNA/Treekin/Record.pm
