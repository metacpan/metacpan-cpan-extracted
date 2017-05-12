package Algorithm::LossyCount;

# ABSTRACT: Memory-efficient approximate frequency count.

use v5.10;
use Algorithm::LossyCount::Entry;
use Carp;
use POSIX qw//;

our $VERSION = 0.03;

sub new {
  my ($class, %params) = @_;

  my $max_error_ratio = delete $params{max_error_ratio}
    // Carp::croak('Missing mandatory parameter: "max_error_ratio"');
  if (%params) {
    Carp::croak(
      'Unknown parameter(s): ',
      join ', ', map { qq/"$_"/ } sort keys %params,
    )
  }

  Carp::croak('max_error_ratio must be positive.') if $max_error_ratio <= 0;

  my $self = bless +{
    bucket_size => POSIX::ceil(1 / $max_error_ratio),
    current_bucket => 1,
    entries => +{},
    max_error_ratio => $max_error_ratio,
    num_samples => 0,
    num_samples_in_current_bucket => 0,
  } => $class;

  return $self;
}

sub add_sample {
  my ($self, $sample) = @_;

  Carp::croak('add_sample() requires 1 parameter.') unless defined $sample;

  if (defined (my $entry = $self->entries->{$sample})) {
    $entry->increment_frequency;
    $entry->num_allowed_errors($self->current_bucket - 1);
  } else {
    $self->entries->{$sample} = Algorithm::LossyCount::Entry->new(
      num_allowed_errors => $self->current_bucket - 1,
    );
  }

  ++$self->{num_samples};
  ++$self->{num_samples_in_current_bucket};
  $self->clear_bucket if $self->bucket_is_full;
}

sub bucket_is_full {
  my ($self) = @_;

  $self->num_samples_in_current_bucket >= $self->bucket_size;
}

sub bucket_size { $_[0]->{bucket_size} }

sub clear_bucket {
  my ($self) = @_;

  for my $sample (keys %{ $self->entries }) {
    my $entry = $self->entries->{$sample};
    unless ($entry->survive_in_bucket($self->current_bucket)) {
      delete $self->entries->{$sample};
    }
  }
  ++$self->{current_bucket};
  $self->{num_samples_in_current_bucket} = 0;
}

sub current_bucket { $_[0]->{current_bucket} }

sub entries { $_[0]->{entries} }

sub frequencies {
  my ($self, %params) = @_;

  my $support = delete $params{support} // 0;
  if (%params) {
    Carp::croak(
      'Unknown parameter(s): ',
      join ', ', map { qq/"$_"/ } sort keys %params,
    )
  }

  my $threshold = ($support - $self->max_error_ratio) * $self->num_samples;
  my %frequencies = map {
    my $frequency = $self->entries->{$_}->frequency;
    $frequency < $threshold ? () : ($_ => $frequency);
  } keys %{ $self->entries };
  return \%frequencies;
}

sub max_error_ratio { $_[0]->{max_error_ratio} }

sub num_samples { $_[0]->{num_samples} }

sub num_samples_in_current_bucket { $_[0]->{num_samples_in_current_bucket} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Algorithm::LossyCount - Memory-efficient approximate frequency count.

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Algorithm::LossyCount;
  
  my @samples = qw/a b a c d f a a d b b c a a .../;
  
  my $counter = Algorithm::LossyCount->new(max_error_ratio => 0.005);
  $counter->add_sample($_) for @samples;
  
  my $frequencies = $counter->frequencies;
  say $frequencies->{a};  # Approximate freq. of 'a'.
  say $frequencies->{b};  # Approximate freq. of 'b'.
  ...

=head1 DESCRIPTION

Lossy-Counting is a approximate frequency counting algorithm proposed by Manku and Motwani in 2002 (refer L<SEE ALSO> section below.)

The main advantage of the algorithm is memory efficiency. You can get approximate count of appearance of items with very low memory footprint, compared with total inspection.
Furthermore, Lossy-Counting is an online algorithm. It is applicable to data set such that the size is unknown, and you can take intermediate result anytime.

=head1 METHODS

=head2 new(max_error_ratio => $num)

Construcotr. C<max_error_ratio> is the only mandatory parameter, that specifies acceptable error ratio. It is an error that give zero or a negative number as the value.

=head2 add_sample($sample)

Add given C<$sample> to count.

=head2 frequencies([support => $num])

Returns current result as HashRef. Its keys and values are samples and corresponding counts respectively.

If optional named parameter C<support> is specified, returned HashRef will contain only samples having frequency greater than C<($support - $max_error_ratio) * $num_samples>.

=head2 max_error_ratio

Returns C<max_error_ratio> you've given to the constructor.

=head2 num_samples

Returns the total number of samples you've added.

=head1 SEE ALSO

=over 4

=item Manku, Gurmeet Singh, and Rajeev Motwani. "Approximate frequency counts over data streams." Proceedings of the 28th international conference on Very Large Data Bases. VLDB Endowment, 2002.

=back

=head1 AUTHOR

Koichi SATOH <sekia@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Koichi SATOH.

This is free software, licensed under:

  The MIT (X11) License

=cut
