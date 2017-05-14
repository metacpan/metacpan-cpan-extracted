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

note 'Query local bigbed';
my $file = "${Bin}/data/test.bb";

my $bb = Bio::DB::Big->open($file);
my $h = $bb->header();
is($h->{version}, 1, 'Checking header: version');
is($h->{nLevels}, 5, 'Checking header: nLevels');
is($h->{fieldCount}, 3, 'Checking header: fieldCount');
is($h->{definedFieldCount}, 3, 'Checking header: definedFieldCount');

my $chroms = $bb->chroms;
my $chr21_len = 48129895;
is_deeply([sort keys %{$chroms}], [qw/chr21/], 'Checking we have one chromosome in the test bigbed file');

is($chroms->{chr21}->{length}, $chr21_len, 'Length of chrom 21 is as expected');
is($chroms->{chr21}->{name}, "chr21", 'Name of chrom 21 is as expected');

#### Start testing the bigbed entries code
my $start = 9430000;
my $end = 10000000;
my $string = 1;

my $entries = $bb->get_entries('chr21', $start, $end, $string);
my $entries_length = scalar(@{$entries});
is($entries_length, 11, 'Expect 11 entries');
my @bed_entries;
{
  open my $fh, '<', "${Bin}/data/test.bed";
  @bed_entries = map {[split(/\t/, $_)]} map { chomp; $_ } <$fh>;
  close $fh;
}
for(my $i = 0; $i < $entries_length; $i++) {
  is($entries->[$i]->{start}, $bed_entries[$i][1], "Checking start for element $i of BigBed");
  is($entries->[$i]->{end}, $bed_entries[$i][2], "Checking end for element $i of BigBed");
}

throws_ok { $bb->get_entries('bogus', 1, 1000); } qr/Invalid chromosome/, 'Caught exception get_entries when we give a bogus chromosome';
throws_ok { $bb->get_entries('chr21', 1, $chr21_len+100); } qr/Invalid bounds/, 'Caught exception get_entries specifying something too long';
throws_ok { $bb->get_entries('chr21', 1000, 10); } qr/Invalid bounds/, 'Caught exception get_entries when start exceeds end';

#### Test iterator
{
  my $iter = $bb->get_entries_iterator('chr21', $start, $end, $string, 1);
  my $index = 0;
  while(my $array = $iter->next()) {
    foreach my $i (@{$array}) {
      is($i->{start}, $bed_entries[$index][1], "Checking start for element $index of BigBed iterator");
      is($i->{end}, $bed_entries[$index][2], "Checking end for element $index of BigBed iterator");
      $index++;
    }
  }
  is($index, 11, 'Checking we have the expected number of intervals iteratored over');
}
throws_ok { $bb->get_entries_iterator('bogus', 1, 1000); } qr/Invalid chromosome/, 'Caught exception get_entries_iterator when we give a bogus chromosome';
throws_ok { $bb->get_entries_iterator('chr21', 1, $chr21_len+100); } qr/Invalid bounds/, 'Caught exception get_entries_iterator specifying something too long';
throws_ok { $bb->get_entries_iterator('chr21', 1000, 10); } qr/Invalid bounds/, 'Caught exception get_entries_iterator when start exceeds end';

#### Now AutoSQL
my $as = $bb->get_autosql_string;
ok(! defined $as, 'Checking this BigBed file lacks autosql');
ok(! defined $bb->get_autosql(), 'Checking that this returns an undefined AutoSQL refernce as well');

done_testing();
