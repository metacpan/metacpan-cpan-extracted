=head1 LICENSE

Copyright [2015-2017] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Bio::DB::Big;
use FindBin '$Bin';

Bio::DB::Big->init();

note 'Query local bigwig';
my $file = "${Bin}/data/test.bw";

my $bw = Bio::DB::Big->open($file);
my $h = $bw->header();

is($h->{version}, 4, 'Checking header: version');
is($h->{nLevels}, 1, 'Checking header: nLevels');
is($h->{nBasesCovered}, 154, 'Checking header: nBasesCovered');
is_num($h->{minVal}, 0.1, 0.1, 'Checking header: minVal');
is_num($h->{maxVal}, 2.0, 0.1, 'Checking header: maxVal');
is_num($h->{sumData}, 272.1, 0.1, 'Checking header: sumData');
is_num($h->{sumSquared}, 500.3, 0.1, 'Checking header: sumSquared');

my $chroms = $bw->chroms;
my $chr1_len = 195471971;
my $chr10_len = 130694993;
is_deeply([sort keys %{$chroms}], [qw/1 10/], 'Checking we have two chromosomes in the test bigwig file'); 
is($chroms->{1}->{length}, $chr1_len, 'Length of chrom 1 is as expected');
is($chroms->{1}->{name}, "1", 'Name of chrom 1 is as expected');
is($chroms->{10}->{length}, $chr10_len, 'Length of chrom 10 is as expected');
is($chroms->{10}->{name}, "10", 'Name of chrom 10 is as expected');

is($bw->chrom_length('1'), $chr1_len, 'Checking we can get chromosome 1 length as expected');
is($bw->chrom_length('10'), $chr10_len, 'Checking we can get chromosome 10 length as expected');
is($bw->chrom_length('bogus'), 0, 'Bogus chromosome has zero length');

ok($bw->has_chrom('1'), 'We have chromosome "1" in the file');
ok(! $bw->has_chrom('bogus'), 'We do not have chromosome "bogus" in the file');

#Checking summary stats (uses zooms)
{
  my @stats_params = ($bw, '1', 1, 1000, 2);
  my $summary = 0;
  is_stats(@stats_params, 'mean', $summary, [[1.35, 0.1],[undef]]);
  is_stats(@stats_params, 'std', $summary, [[0.22, 0.01],[undef]]);
  is_stats(@stats_params, 'dev', $summary, [[0.22, 0.01],[undef]]);
  is_stats(@stats_params, 'min', $summary, [[0.20, 0.01],[undef]]);
  is_stats(@stats_params, 'max', $summary, [[1.5, 0.01],[undef]]);
}

# Checking full stats
{
  my $full = 1;
  my @stats_params = ($bw, '1', 1, $chr1_len, 3);
  is_stats(@stats_params, 'mean', $full, [[1.35, 0.1],[undef],[undef]]);
  is_stats(@stats_params, 'std', $full, [[0.27, 0.01],[undef],[undef]]);
  is_stats(@stats_params, 'dev', $full, [[0.27, 0.01],[undef],[undef]]);
  is_stats(@stats_params, 'min', $full, [[0.10, 0.01],[undef],[undef]]);
  is_stats(@stats_params, 'max', $full, [[1.5, 0.01],[undef],[undef]]);
}

throws_ok { $bw->get_stats('bogus', 1, 1000); } qr/Invalid chromosome/, 'Caught exception get_stats when we give a bogus chromosome';
throws_ok { $bw->get_stats('1', 1, 1000, 1, q{stdev}); } qr/Invalid type/, 'Caught exception get_stats about bogus summary type stdev';
throws_ok { $bw->get_stats('1', 1, $chr1_len+100); } qr/Invalid bounds/, 'Caught exception get_stats specifying something too long';
throws_ok { $bw->get_stats('1', 1000, 10); } qr/Invalid bounds/, 'Caught exception get_stats when start exceeds end';

##### Start testing get_values
{
  my $v = $bw->get_values('1', 0, 1000);
  is(scalar(@{$v}), 1000, 'Checking we have 1000 elements for the specified range');
  is_num($v->[0], 0.10, 0.01, 'Checking first base value');
  is_num($v->[1], 0.20, 0.01, 'Checking second base value');
  is_num($v->[2], 0.30, 0.01, 'Checking third base value');
}
throws_ok { $bw->get_values('bogus', 1, 1000); } qr/Invalid chromosome/, 'Caught exception get_values when we give a bogus chromosome';
throws_ok { $bw->get_values('1', 1, $chr1_len+100); } qr/Invalid bounds/, 'Caught exception get_values specifying something too long';
throws_ok { $bw->get_values('1', 1000, 10); } qr/Invalid bounds/, 'Caught exception get_values when start exceeds end';

##### Start testing get_intervals
# Start, end, value, discrepency allowed
my $intervals_expected = [
[0, 1, 0.1, 0.01],
[1, 2, 0.2, 0.01],
[2, 3, 0.3, 0.01],
[100, 150, 1.39, 0.01],
[150, 151, 1.5, 0.1]
];
{
  my $i = $bw->get_intervals('1', 0, 1000);
  is(scalar(@{$i}), scalar(@{$intervals_expected}), 'Checking we have the expected number of intervals');
  my $index = 0;
  is_interval($i->[$index], @{$intervals_expected->[$index]}, 'Test interval pos '.$index);
  $index++;
  is_interval($i->[$index], @{$intervals_expected->[$index]}, 'Test interval pos '.$index);
  $index++;
  is_interval($i->[$index], @{$intervals_expected->[$index]}, 'Test interval pos '.$index);
  $index++;
  is_interval($i->[$index], @{$intervals_expected->[$index]}, 'Test interval pos '.$index);
  $index++;
  is_interval($i->[$index], @{$intervals_expected->[$index]}, 'Test interval pos '.$index);
}
throws_ok { $bw->get_intervals('bogus', 1, 1000); } qr/Invalid chromosome/, 'Caught exception get_intervals when we give a bogus chromosome';
throws_ok { $bw->get_intervals('1', 1, $chr1_len+100); } qr/Invalid bounds/, 'Caught exception get_intervals specifying something too long';
throws_ok { $bw->get_intervals('1', 1000, 10); } qr/Invalid bounds/, 'Caught exception get_intervals when start exceeds end';

##### Test iteration
{
  my $iter = $bw->get_intervals_iterator('1', 0, 1000, 1);
  my $index = 0;
  while(my $array = $iter->next()) {
    foreach my $i (@{$array}) {
      is_interval($i, @{$intervals_expected->[$index]}, 'Test iterator interval pos '.$index);
      $index++;
    }
  }
  is(($index), scalar(@{$intervals_expected}), 'Checking we have the expected number of intervals');
}
throws_ok { $bw->get_intervals_iterator('bogus', 1, 1000); } qr/Invalid chromosome/, 'Caught exception get_intervals_iterator when we give a bogus chromosome';
throws_ok { $bw->get_intervals_iterator('1', 1, $chr1_len+100); } qr/Invalid bounds/, 'Caught exception get_intervals_iterator specifying something too long';
throws_ok { $bw->get_intervals_iterator('1', 1000, 10); } qr/Invalid bounds/, 'Caught exception get_intervals_iterator when start exceeds end';

####### Test the all stats methods

{
  my @stats_params = ('1', 1, 1000, 2);
  my $stats = $bw->get_all_stats(@stats_params);
  my $s = $stats->[0];
  is_num($s->{mean}, 1.35, 0.01, 'Checking mean as expected from all stats');
  is_num($s->{min}, 0.20, 0.01, 'Checking min as expected from all stats');
  is_num($s->{max}, 1.5, 0.1, 'Checking max as expected from all stats');
  is_num($s->{cov}, 0.106, 0.01, 'Checking cov as expected from all stats');
  is_num($s->{dev}, 0.22, 0.01, 'Checking dev as expected from all stats');
  is_deeply($stats->[1], {}, 'Checking second element is an empty set of statistics');
}

{
  my @stats_params = ('1', 1, $chr1_len, 3, 1);
  my $stats = $bw->get_all_stats(@stats_params);
  my $s = $stats->[0];
  is_num($s->{mean}, 1.35, 0.01, 'Checking mean as expected from all stats full');
  is_num($s->{min}, 0.20, 0.01, 'Checking min as expected from all stats full');
  is_num($s->{max}, 1.5, 0.1, 'Checking max as expected from all stats full');
  is_num($s->{cov}, 8e-7, 1e-7, 'Checking cov as expected from all stats full');
  is_num($s->{dev}, 0.22, 0.01, 'Checking dev as expected from all stats full');
  is_deeply($stats->[1], {}, 'Checking second element is an empty set of statistics full');
  is_deeply($stats->[2], {}, 'Checking third element is an empty set of statistics full');
}


sub is_num {
  my ($got, $expected, $tolerance, $msg) = @_;
  my $diff = abs($got - $expected);
  if($diff > $tolerance) {
    fail("$msg: Difference between '$got' and expected '$expected'. Was greater than tolerance '$tolerance'");
  }
  else {
    ok(1, $msg);
  }
  return;
}

sub is_stats {
  my ($bigwig, $chrom, $start, $end, $bins, $mode, $full, $expected_values) = @_;
  my $stats = $bigwig->get_stats($chrom, $start, $end, $bins, $mode);
  my $len = scalar(@{$expected_values});
  is(scalar(@{$stats}), $len, 'Checking we have the expected number of results');
  for (my $i = 0; $i < $len; $i++) {
    my $actual = $stats->[$i];
    my $expected = $expected_values->[$i];
    if(! defined $expected->[0]) {
      ok(! defined $actual, "Checking index $i of $mode statistics is undefined");
    }
    else {
      is_num($actual, @{$expected}, "Checking index $i of $mode statistics");
    }
  }
  return;
}

sub is_interval {
  my ($interval, $start, $end, $value, $tolerance, $msg) = @_;
  is($interval->{start}, $start, "${msg} interval start");
  is($interval->{end}, $end, "${msg} interval end");
  is_num($interval->{value}, $value, $tolerance, "${msg} interval value");
  return;
}

done_testing();