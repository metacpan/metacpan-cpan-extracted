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
use Bio::DB::Big;
use FindBin '$Bin';

Bio::DB::Big->init();

note 'Testing opening bigwigs locally';
my $bw_file = "${Bin}/data/test.bw";
{
  my $big = Bio::DB::Big->open($bw_file);
  is($big->type(), 0, 'Type of file should be 0 i.e. a bigwig file');
}

{
  is(Bio::DB::Big::File->test_big_wig($bw_file), 1, 'Expect a bigwig file to report as being a bigwig');
  is(Bio::DB::Big::File->test_big_bed($bw_file), 0, 'Expect a bigwig file to report as not being a bigbed');
  my $big = Bio::DB::Big::File->open_big_wig($bw_file);
  ok($big, 'Testing we have an object');
  is($big->type(), 0, 'Type of file should be 0 i.e. a bigwig file');
}

note 'Testing opening bigbeds locally';
my $bb_file = "${Bin}/data/test.bb";
{
  my $big = Bio::DB::Big->open($bb_file);
  is($big->type(), 1, 'Type of file should be 0 i.e. a bigbed file');
}

{
  is(Bio::DB::Big::File->test_big_wig($bb_file), 0, 'Expect a bigbed file to report as being a bigbed');
  is(Bio::DB::Big::File->test_big_bed($bb_file), 1, 'Expect a bigbed file to report as not being a bigbed');
  my $big = Bio::DB::Big::File->open_big_bed($bb_file);
  ok($big, 'Testing we have an object');
  is($big->type(), 1, 'Type of file should be 0 i.e. a bigbed file');
}

done_testing();