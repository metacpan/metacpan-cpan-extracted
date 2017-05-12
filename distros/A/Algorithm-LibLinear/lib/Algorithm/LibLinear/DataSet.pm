package Algorithm::LibLinear::DataSet;

use 5.014;
use Algorithm::LibLinear::Types;
use Carp qw//;
use List::MoreUtils qw/none/;
use Smart::Args;

sub new {
    args
        my $class => 'ClassName',
        my $data_set => 'ArrayRef[Algorithm::LibLinear::LabeledData]';

    bless +{ data_set => $data_set } => $class;
}

sub load {
    args
        my $class => 'ClassName',
        my $fh => +{ isa => 'FileHandle', optional => 1, },
        my $filename => +{ isa => 'Str', optional => 1, },
        my $string => +{ isa => 'Str', optional => 1, };

    if (none { defined } ($fh, $filename, $string)) {
        Carp::croak('No source specified.');
    }
    my $source = $fh;
    $source //= do {
        open my $fh, '<', +($filename // \$string) or Carp::croak($!);
        $fh;
    };
    $class->new(data_set => $class->parse_input_file($source));
}

sub add_data {
    args
        my $self,
        my $data => 'Algorithm::LibLinear::LabeledData';

    push @{ $self->data_set }, $data;
}

sub as_arrayref { $_[0]->{data_set} }

sub as_problem {
    args
        my $self,
        my $bias => +{ isa => 'Num', default => -1.0, };

    my (@features, @labels);
    for my $data (@{ $self->as_arrayref }) {
        push @features, $data->{feature};
        push @labels, $data->{label};
    }
    Algorithm::LibLinear::Problem->new(\@labels, \@features, $bias);
}

sub as_string {
    args
        my $self;

    my $result = '';
    for my $entry (@{ $self->as_arrayref }) {
        my $feature = $entry->{feature};
        my @feature_dump =
            map { "$_:$feature->{$_}" } sort { $a <=> $b } keys %$feature;
        $result .= join(' ', $entry->{label}, @feature_dump) . "\n";
    }
    return $result;
}

sub parse_input_file {
    args_pos
        my $class => 'ClassName',
        my $source => 'FileHandle';

    my @data_set;
    while (defined(my $line = <$source>)) {
        chomp $line;
        my ($label, @feature) = split /\s+/, $line;
        $label += 0;
        my %feature = map {
            my ($index, $value) = split /:/;
            $index += 0;
            $value += 0;
            ($index => $value);
        } @feature;
        push @data_set, +{ feature => \%feature, label => $label, };
    }
    return \@data_set;
}

sub size { 0 + @{ $_[0]->as_arrayref } }

1;

__DATA__

=head1 NAME

Algorithm::LibLinear::DataSet

=head1 SYNOPSIS

  use Algorithm::LibLinear::DataSet;
  
  my $data_set = Algorithm::LibLinear::DataSet->new(data_set => [
    +{ feature => +{ 1 => 0.708333, 2 => 1, 3 => 1, ... }, label => 1, },
    +{ feature => +{ 1 => 0.583333, 2 => -1, 3 => 0.333333, ... }, label => -1, },
    +{ feature => +{ 1 => 0.166667, 2 => 1, 3 => -0.333333, ... }, label => 1, },
    ...
  ]);
  my $data_set = Algorithm::LibLinear::DataSet->load(fh => \*DATA);
  my $data_set = Algorithm::LibLinear::DataSet->load(filename => 'liblinear_file');
  my $data_set = Algorithm::LibLinear::DataSet->load(string => "+1 1:0.70833 ...");
  
  say $data_set->size;
  say $data_set->as_string;  # '+1 1:0.70833 2:1 3:1 ...'
  
  __DATA__
  +1 1:0.708333 2:1 3:1 4:-0.320755 5:-0.105023 6:-1 7:1 8:-0.419847 9:-1 10:-0.225806 12:1 13:-1 
  -1 1:0.583333 2:-1 3:0.333333 4:-0.603774 5:1 6:-1 7:1 8:0.358779 9:-1 10:-0.483871 12:-1 13:1 
  +1 1:0.166667 2:1 3:-0.333333 4:-0.433962 5:-0.383562 6:-1 7:-1 8:0.0687023 9:-1 10:-0.903226 11:-1 12:-1 13:1 
  ...

=head1 DESCRIPTION

This class represents set of feature vectors with gold answers.

=head1 METHODS

=head2 new(data_set => \@data_set)

Constructor.

C<data_set> is an ArrayRef of HashRef that has 2 keys: C<feature> and C<label>.
The value of C<feature> is a HashRef which represents a (sparse) feature vector. Its key is an index and corresponding value is a real number. The indices must be >= 1.
The value of C<label> is an integer that is class label the feature belonging.

=head2 load(fh => \*FH | filename => $path | string => $string)

Class method. Loads data set from LIBSVM/LIBLINEAR format file.

=head2 as_string

Dumps the data set as a LIBSVM/LIBLINEAR format data.

=head2 size

The number of data.

=cut
