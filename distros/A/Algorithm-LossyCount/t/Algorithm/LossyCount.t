use v5.10;
use List::Util qw/shuffle sum/;
use Test::Exception::LessClever;
use Test::More;

use_ok 'Algorithm::LossyCount';

sub zipf_distribution {
  my ($num_samples) = @_;

  my $partition_function = sum map { 1 / $_ } 1 .. $num_samples;
  return sub {
    my ($i) = @_;
    1 / ($i * $partition_function);
  };
}

throws_ok {
  Algorithm::LossyCount->new;
} qr/max_error_ratio/, 'max_error_ratio is a mandatory parameter.';

my $num_samples = 20000;
my $distribution = zipf_distribution($num_samples);
my %sample_frequencies;
for my $i (1 .. $num_samples) {
  my $probability = $distribution->($i);
  my $frequency = int ($probability * $num_samples);
  next if $frequency == 0;
  $sample_frequencies{$i} = $frequency;
}

subtest 'Basic' => sub {
  my $counter = new_ok 'Algorithm::LossyCount' => [ max_error_ratio => 0.005 ];

  my @samples =
    shuffle map { ($_) x $sample_frequencies{$_} } keys %sample_frequencies;
  $counter->add_sample($_) for @samples;

  my $frequencies = $counter->frequencies;
  my @frequent_samples = (
    sort { $frequencies->{$b} <=> $frequencies->{$a} } keys %$frequencies
  )[0 .. keys(%$frequencies) / 100];
  for my $sample (@frequent_samples) {
    my $errors = $sample_frequencies{$sample} - $frequencies->{$sample};
    my $error_ratio = $errors / $sample_frequencies{$sample};
    cmp_ok $error_ratio, '<=', $counter->max_error_ratio;
  }
};

done_testing;
