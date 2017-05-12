package Catmandu::Exporter::Stat;

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Statistics::Descriptive;
use List::Util;
use Algorithm::HyperLogLog;
use Statistics::TopK;
use POSIX qw(floor);
use Moo;

with 'Catmandu::Exporter';

has fields       => (is => 'rw');
has as           => (is => 'ro', default => sub { 'Table'} );
has res          => (is => 'ro');
has topk         => (is => 'ro', default => sub { 100 });
has hll          => (is => 'ro', default => sub { 14 });
has counter      => (is => 'ro');

sub add {
    my ($self, $data) = @_;

    unless (defined $self->fields) {
        $self->fields(join(",",sort keys %$data));
    }

    my @keys = split(/,/,$self->fields);

    for my $key (@keys) {
        my $val = $data->{$key};
        $self->inc_key_value($key,$val);
    }

    $self->{counter} += 1;
}

# Update a counter of unique values in a field , plus the number of
# values in a field.
sub inc_key_value {
    my ($self,$key,$val) = @_;

    my $prev  = $self->{res}->{$key};
    my $count = 0;

    $prev->{hll}  = Algorithm::HyperLogLog->new($self->hll)
                            unless exists $prev->{hll};
    $prev->{top}  = Statistics::TopK->new($self->topk)
                            unless exists $prev->{top};

    $prev->{stat} = Statistics::Descriptive::Sparse->new()
                            unless exists $prev->{stat};

    if (is_array_ref($val)) {
        for (@$val) {
            if (!defined($_) || length($_) == 0) {
                $prev->{top}->add('<null>');
                $prev->{hll}->add('<null>');
            }
            else {
                $prev->{top}->add($_);
                $prev->{hll}->add($_);
                $count++;
            }
        }
    }
    elsif (is_hash_ref($val)) {
        # Nested fields are not supported for now. Treat them as unique
        # values...
        $prev->{top}->add("$val");
        $prev->{hll}->add("$val");
        $count++;
    }
    else {
        if (!defined($val) || length($val) == 0) {
            $prev->{top}->add('<null>');
            $prev->{hll}->add('<null>');
        }
        else {
            $prev->{top}->add($val);
            $prev->{hll}->add($val);
            $count++;
        }
    }

    $prev->{count} += $count;
    $prev->{zero}  += 1 if $count == 0;
    $prev->{stat}->add_data($count);

    $self->{res}->{$key} = $prev;
}

# Return the stats for a key
sub get_stat {
    my ($self,$key) = @_;
    return $self->{res}->{$key}->{stat};
}

# Return the estimated number of unique values in a field
sub get_key_uniq {
    my ($self,$key) = @_;
    return sprintf "%.3f" , $self->{res}->{$key}->{hll}->estimate();
}

# Return the estimated entropy of a field
sub entropy {
    my ($self,$key) = @_;

    my %values             = $self->{res}->{$key}->{top}->counts;
    my $sample_count       = keys %values;
    my $sample_cardinality = floor($self->get_key_uniq($key));

    my $is_exact = $sample_count == $sample_cardinality ? 1 : 0;

    my $cnt = 0;
    my $has_unit_values = 0;

    for my $k (keys %values) {
        $cnt += $values{$k};
        $has_unit_values = 1 if $values{$k} == 1;
    }

    my $missing_values = $sample_cardinality - $sample_count;

    if ($missing_values > 0 && ! $has_unit_values) {
        print STDERR "Statistics::TopK bin not big enough to estimate the entropy\n";
        print STDERR "Increate --topk to a value > " . $self->topk . "\n";
        return 'n/a';
    }

    $cnt += $missing_values;

    return 'n/a' unless $cnt > 0;

    my $h = 0;
    for my $k (keys %values) {
        my $p = $values{$k}/$cnt;
        $h += $p * log($p)/log(2);
    }

    if ($has_unit_values) {
        my $p = 1 / $cnt;
        $h += $missing_values * $p * log($p)/log(2);
    }

    return sprintf "%.1f/%.1f" , -1 * $h ,log($cnt)/log(2);
}

sub commit {
    my ($self) = shift;

    my @keys = split(/,/,$self->fields);

    my $fields = [qw(name count zeros zeros% min max mean variance stdev uniq~ uniq% entropy)];

    my $exporter = Catmandu->exporter(
                        $self->as,
                        fields => $fields,
                        file => $self->file
                   );

    $exporter->add(
        { name => '#' , count => $self->counter }
    );

    my $has_overflow = 0;

    for my $key (@keys) {
        my $stats = {};
        $stats->{name}     = $key;
        $stats->{count}    = $self->{res}->{$key}->{count};
        $stats->{min}      = $self->get_stat($key)->min();
        $stats->{max}      = $self->get_stat($key)->max();
        $stats->{mean}     = $self->get_stat($key)->mean();
        $stats->{variance} = sprintf "%.1f" , $self->get_stat($key)->variance();
        $stats->{stdev}    = sprintf "%.1f" , $self->get_stat($key)->standard_deviation();
        my ($zeros,$zerosp,$occur_count,$values_count,$uniqs);
        $zeros  = $self->{res}->{$key}->{zero} // 0;
        $values_count  = $self->{res}->{$key}->{count};
        $occur_count   = $self->get_stat($key)->count();
        $zerosp = sprintf "%.1f" , $occur_count > 0 ? 100 * $zeros / $occur_count : 100;
        $uniqs  = sprintf "%.1f" , $values_count > 0 ? 100 * $self->get_key_uniq($key) / $values_count : 0.0;

        my $overflow = $values_count > 0 ? 100 * $self->get_key_uniq($key) / $values_count : 0.0;
        $overflow    = $overflow > 100 ? 1 : 0;

        $stats->{zeros}    = $zeros;
        $stats->{'zeros%'} = $zerosp;
        $stats->{'uniq~'}  = floor($self->get_key_uniq($key));
        $stats->{'uniq%'}  = $uniqs;
        $stats->{'uniq%'} .= " (!)" if $overflow;
        $stats->{'uniq~'} .= " (!)" if $overflow;
        $stats->{entropy}  = $self->entropy($key);
        $stats->{entropy} .= " (!)" if $overflow;

        $exporter->add($stats);

        $has_overflow = 1 if $overflow;
    }

    $exporter->commit;

    if ($has_overflow) {
        print STDERR <<EOF;
Overflow warning - probably your dataset is too small for an accurate uniq~, uniq% and entropy count...
EOF
    }
}

1;

=head1 NAME

Catmandu::Exporter::Stat - a statistical export

=head1 SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert -v JSON to Stat --fields isbn

    # Export the statistics as YAML
    cat data.json | catmandu convert -v JSON to Stat --fields isbn --as YAML

=head1 DESCRIPTION

The L<Catmandu::Stat> package can be used to calculate statistics on the availablity of
fields in a data file. Use this exporter to count the availability of fields or count
the number of duplicate values. For each field the exporter calculates the following
statistics:

  * name    : the name of a field
  * count   : the number of occurences of a field in all records
  * zeros   : the number of records without a field
  * zeros%  : the percentage of records without a field
  * min     : the minimum number of occurences of a field in any record
  * max     : the maximum number of occurences of a field in any record
  * mean    : the mean number of occurences of a field in all records
  * variance : the variance of the field number
  * stdev   : the standard deviation of the field number
  * uniq~   : the estimated number of unique records
  * uniq%   : the estimated percentage of uniq values
  * entropy : the minimum and maximum entropy in the field values (estimated value)

Details:

  * entropy is an indication in the variation of field values (are some values more unique than others)
  * entropy values are displayed as : minimum/maximum entropy
  * when the minimum entropy = 0, then all the field values are equal
  * when the minimum and maximum entropy are equal, then all the field values are different
  * the 'uniq%' and 'entropy' fields are estimated and are normally within 1% of the
    correct value (this is done to keep the memory requirements of this module low)

Each statistical report contains one row named hash '#' which contains the total
number of records.

=head1 CONFIGURATION

=over 4

=item v

Verbose output. Show the processing speed.

=item fix FIX

A fix or a fix file containing one or more fixes applied to the input data before
the statistics are calculated.

=item fields KEY[,KEY,...]

One or more fields in the data for which statistics need to be calculated. No deep nested
fields are allowed. The exporter will collect statistics on the availability of a field in
all records. For instance, the following record contains one 'title' field, zero 'isbn'
fields and 3 'author' fields

    ---
    title: ABCDEF
    author:
        - Davis, Miles
        - Parker, Charly
        - Mingus, Charles
    year: 1950

Examples of operation:

    # Calculate statistics on the number of records that contain a 'title'
    cat data.json | catmandu convert JSON to Stat --fields title

    # Calculate statistics on the number of records that contain a 'title', 'isbn' or 'subject' fields
    cat data.json | catmandu convert JSON to Stat --fields title,isbn,subject

    # The next example will not work: no deeply nested fields allowed
    cat data.json | catmandu convert JSON to Stat --fields foo.bar.x.y

When no fields parameter is available, then all fields are read from the first input record.

=item as Table | CSV | YAML | JSON | ...

By default the statistics are exported in a Table format. The use 'as' option to change the
export format.

=item topk NUMBER

To calculate the entropy an estimate of the probability distribution of the
data set needs to be calculated. Topk is the expected lower bound on the
number of field values which have repeated entries. By default it is set to
100. If there are more fields values with doubles, then this number needs to
be increased.

=item hll NUMBER

This is the L<Algorithm::HyperLogLog> parameter calculating the estimation of
cardinality (uniqueness) of a data set. The HLL register parameter, which should
be between 4 and 16, gives an estimate on the precision of the calculation. The
bigger the number, the better precision but also more memory will be used. Default: 14.

=back

=head1 SEE ALSO

L<Catmandu::Exporter> ,
L<Statistics::Descriptive> ,
L<Statistics::TopK> ,
L<Algorithm::HyperLogLog>

=cut

1;
