package Algorithm::LibLinear::FeatureScaling;

use 5.014;
use Algorithm::LibLinear::Types;
use Carp qw//;
use List::MoreUtils qw/minmax none/;
use List::Util qw/max/;
use Smart::Args;

sub new {
    args
        my $class => 'ClassName',
        my $data_set => +{
            isa => 'Algorithm::LibLinear::DataSet',
            optional => 1,
        },
        my $lower_bound => +{ isa => 'Num', default => 0, },
        my $min_max_values => +{
            isa => 'ArrayRef[ArrayRef[Num]]',
            optional => 1,
        },
        my $upper_bound => +{ isa => 'Num', default => 1.0, };

    unless ($data_set or $min_max_values) {
        Carp::croak('Neither "data_set" nor "min_max_values" is specified.');
    }

    my $self = bless +{
        lower_bound => $lower_bound,
        upper_bound => $upper_bound,
    } => $class;

    $self->{min_max_values} = $min_max_values
        // $self->compute_min_max_values(data_set => $data_set);

    return $self;
}

sub load {
    args
        my $class => 'ClassName',
        my $fh => +{ isa => 'FileHandle', optional => 1, },
        my $filename => +{ isa => 'Str', optional => 1, },
        my $string => +{ isa => 'Str', optional => 1, };

    if (none { defined } ($filename, $fh, $string)) {
        Carp::croak('No source specified.');
    }
    my $source = $fh;
    $source //= do {
        open $fh, '<', +($filename // \$string) or Carp::croak($!);
        $fh;
    };

    chomp(my $header = <$source>);
    Carp::croak('At present, y-scaling is not supported.') if $header eq 'y';
    Carp::croak('Invalid format.') if $header ne 'x';

    chomp(my $bounds = <$source>);
    my ($lower_bound, $upper_bound) = split /\s+/, $bounds;

    my @min_max_values;
    while (defined(my $min_max_values = <$source>)) {
        chomp $min_max_values;
        my (undef, $min, $max) = split /\s+/, $min_max_values;
        push @min_max_values, [ $min, $max ];
    }

    $class->new(
        lower_bound => $lower_bound,
        min_max_values => \@min_max_values,
        upper_bound => $upper_bound,
    );
}

sub as_string {
    args
        my $self;
    my $acc =
        sprintf "x\n%.16g %.16g\n", $self->lower_bound, $self->upper_bound;
    my $index = 0;
    for my $min_max_value (@{ $self->min_max_values }) {
        $acc .= sprintf "\%d %.16g %.16g\n", ++$index, @$min_max_value;
    }
    return $acc;
}

sub compute_min_max_values {
    args
        my $self,
        my $data_set => 'Algorithm::LibLinear::DataSet';

    my @feature_vectors = map { $_->{feature} } @{ $data_set->as_arrayref };
    my $last_index = max map { keys %$_ } @feature_vectors;
    my @min_max_values;
    for my $i (1 .. $last_index) {
        my ($min, $max) = minmax map { $_->{$i} // 0 } @feature_vectors;
        push @min_max_values, [ $min, $max ];
    }
    return \@min_max_values;
}

sub lower_bound { $_[0]->{lower_bound} }

sub min_max_values { $_[0]->{min_max_values} }

sub save {
    args
        my $self,
        my $fh => +{ isa => 'FileHandle', optional => 1, },
        my $filename => +{ isa => 'Str', optional => 1, };

    unless ($filename or $fh) {
        Carp::croak('Neither "filename" nor "fh" is given.');
    }
    open $fh, '>', $filename or Carp::croak($!) unless $fh;
    print $fh $self->as_string;
}

sub scale {
    args_pos
        my $self,
        my $target_type => 'Str',
        my $target;

    my $method = $self->can("scale_$target_type");
    unless ($method) {
        Carp::croak("Cannot scale such type of target: $target_type.");
    }
    $self->$method($target);
}

sub scale_data_set {
    args_pos
        my $self,
        my $data_set => 'Algorithm::LibLinear::DataSet';

    my @scaled_data_set =
        map { $self->scale_labeled_data($_) } @{ $data_set->as_arrayref };
    Algorithm::LibLinear::DataSet->new(data_set => \@scaled_data_set);
}

sub scale_feature {
    args_pos
        my $self,
        my $feature => 'Algorithm::LibLinear::Feature';

    my ($lower_bound, $upper_bound) = ($self->lower_bound, $self->upper_bound);
    my $min_max_values = $self->min_max_values;
    my %scaled_feature;
    for my $index (1 .. @$min_max_values) {
        my $unscaled = $feature->{$index} // 0;
        my ($min, $max) = @{ $min_max_values->[$index - 1] // [0, 0] };
        next if $min == $max;
        my $scaled;
        if ($unscaled == $min) {
            $scaled = $lower_bound;
        } elsif ($unscaled == $max) {
            $scaled = $upper_bound;
        } else {
            my $ratio = ($unscaled - $min) / ($max - $min);
            $scaled = $lower_bound + ($upper_bound - $lower_bound) * $ratio;
        }
        $scaled_feature{$index} = $scaled if $scaled != 0;
    }
    return \%scaled_feature;
}

sub scale_labeled_data {
    args_pos
        my $self,
        my $labeled_data => 'Algorithm::LibLinear::LabeledData';

    +{
        feature => $self->scale_feature($labeled_data->{feature}),
        label => $labeled_data->{label},
    };
}

sub upper_bound { $_[0]->{upper_bound} }

1;

__DATA__

=head1 NAME

Algorithm::LibLinear::FeatureScaling

=head1 SYNOPSIS

  use Algorithm::LibLinear::DataSet;
  use Algorithm::LibLinear::FeatureScaling;
  
  my $scale = Algorithm::LibLinear::FeatureScaling->new(
    data_set => Algorithm::LibLinear::DataSet->new(...),
    lower_bound => -10,
    upper_bound => 10,
  );
  my $scale = Algorithm::LibLinear::FeatureScaling->load(
    filename => '/path/to/file',
  );
  
  my $scaled_feature = $scale->scale(feature => +{ 1 => 30, 2 => - 25, ... });
  my $scaled_labeled_data = $scale->scale(
    labeled_data => +{ feature => +{ 1 => 30, ... }, label => 1 },
  );
  my $scaled_data_set = $scale->scale(
    data_set => Algorithm::LibLinear::DataSet->new(...),
  );
  
  say $scale->as_string;
  $scale->save(filename => '/path/to/another/file');

=head1 DESCRIPTION

Support vector classification is actually just a calculation of inner product of feature vector and normal vector of separation hyperplane. If some elements in feature vectors have greater dynamic range than others, they can have stronger influence on the final calculation result.

For example, consider a normal vector to be C<{ 1 1 1 }> and feature vectors to be classified are C<{ -2 10 5 }>, C<{ 5 -50 0 }> and C<{ 10 100 10 }>. Inner products of these normal vector and feature vectors are 13, -45 and 120 respectively. Obviously 2nd elements of the feature vectors have wider dynamic range than 1st and 3rd ones and dominate calculation result.

To avoid such a problem, scaling elements of vectors to make they have same dynamic range is very important. This module provides such vector scaling functionality. If you are familiar with the LIBSVM distribution, you can see this is a library version of C<svm-scale> command written in Perl.

=head1 METHODS

=head2 new(data_set => $data_set | min_max_values => \@min_max_values [, lower_bound => 0.0] [, upper_bound => 1.0])

Constructor. You can set some named parameters below. At least C<data_set> or C<min_max_values> is required.

=over 4

=item data_set

An instance of L<Algorithm::LibLinear::DataSet>. This is used to compute dynamic ranges of each vector element.

=item min_max_values

Pre-calculated dynamic ranges of each vector element. Its structure is like:

  my @min_max_values = (
    [ -10, 10 ],  # Dynamic range of 1st elements of vectors.
    [ 0, 1 ],     # 2nd
    [ -1, 1 ],    # 3rd
    ...
  );

=item lower_bound

=item upper_bound

The lower/upper limits of dynamic range for each element. Default values are 0.0 and 1.0 respectively.

=back

=head2 load(filename => $path | fh => \*FH | string => $content)

Class method. Creates new instance from dumped scaling parameter file.

Please note that this method can parse only a subset of C<svm-scale>'s file format at present.

=head2 as_string

Dump the scaling parameter as C<svm-scale>'s format.

=head2 save(filename => $path | fh => \*FH)

Writes result of C<as_string> out to a file.

=head2 scale(data_set => $data_set | feature => \%feature | labeled_data => \%labeled_data)

Scale the given feature, labeled data or data set.

=head1 SEE ALSO

L<A Practical Guide to Support Vector Classification|http://www.csie.ntu.edu.tw/~cjlin/papers/guide/guide.pdf> - For understanding importance of scaling, see Chapter 2.2, appendix A and B.

=cut
