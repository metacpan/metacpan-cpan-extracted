use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::DB::Taxonomy;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $community3, $member,
   $count, $fh1, $fh2);
my (@communities, @methods);


# Read generic format with arbitrary weights

open $fh1, '<', test_input_file('weights_1.txt') or die "Could not open file: $!\n";
open $fh2, '<', test_input_file('weights_2.txt') or die "Could not open file: $!\n";
ok $in = Bio::Community::IO->new(
   -file              => test_input_file('generic_table.txt'),
   -format            => 'generic',
   -weight_files      => [ $fh1, $fh2 ],
   -weight_assign     => 1,
   -weight_identifier => 'desc',
), 'Read generic format with arbitrary weights';
isa_ok $in, 'Bio::Community::IO::Driver::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
isa_ok $in->weight_files->[0], 'GLOB';  # filehandle
isa_ok $in->weight_files->[1], 'GLOB';
is $in->weight_assign, 1;
is $in->weight_identifier, 'desc';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

is $in->next_community, undef;

is_deeply $in->weight_names(), ['16S copy number', ''];

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is_deeply $member->weights, [1, 1];
delta_ok $community->get_rel_ab($member), 100.0;
is $community->get_member_by_rank(2), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 1];
delta_ok $community2->get_rel_ab($member), 49.6364165212;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 1];
delta_ok $community2->get_rel_ab($member), 48.5747527632;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 1.7888307155;
is $community2->get_member_by_rank(4), undef;


# Read generic format with file-average weights

ok $in = Bio::Community::IO->new(
   -file              => test_input_file('generic_table.txt'),
   -format            => 'generic',
   -weight_files      => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign     => 'file_average',
   -weight_identifier => 'desc',
), 'Read generic format with file-average weights';
isa_ok $in, 'Bio::Community::IO::Driver::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
isa_ok $in->weight_files->[0], 'GLOB';
isa_ok $in->weight_files->[1], 'GLOB';
is $in->weight_assign, 'file_average';
is $in->weight_identifier, 'desc';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is_deeply $member->weights, [1, 200];
delta_ok $community->get_rel_ab($member), 100.0;
is $community->get_member_by_rank(2), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 78.4613912544;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 200];
delta_ok $community2->get_rel_ab($member), 10.8857206647;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 200];
delta_ok $community2->get_rel_ab($member), 10.6528880809;
is $community2->get_member_by_rank(4), undef;


# Read generic format with file-average weights

ok $in = Bio::Community::IO->new(
   -file              => test_input_file('generic_table.txt'),
   -format            => 'generic',
   -weight_files      => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign     => 'file_average',
   -weight_identifier => 'id',
), 'Read generic format with file-average weights';

isa_ok $in, 'Bio::Community::IO::Driver::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
isa_ok $in->weight_files->[0], 'GLOB';
isa_ok $in->weight_files->[1], 'GLOB';
is $in->weight_assign, 'file_average';
is $in->weight_identifier, 'id';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
delta_ok $member->weights->[0], 1.36666666666667;
is       $member->weights->[1], 200;
delta_ok $community->get_rel_ab($member), 100.0;
is $community->get_member_by_rank(2), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
delta_ok $member->weights->[0], 1.36666666666667;
is       $member->weights->[1], 200;
delta_ok $community2->get_rel_ab($member), 69.1403876;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
delta_ok $member->weights->[0], 1.36666666666667;
is       $member->weights->[1], 200;
delta_ok $community2->get_rel_ab($member), 22.5538524;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
delta_ok $member->weights->[0], 1.36666666666667;
is       $member->weights->[1], 200;
delta_ok $community2->get_rel_ab($member), 8.3057600;
is $community2->get_member_by_rank(4), undef;


# Read generic format with community-average weights

ok $in = Bio::Community::IO->new(
   -file              => test_input_file('generic_table.txt'),
   -format            => 'generic',
   -weight_files      => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign     => 'community_average',
   -weight_identifier => 'desc',
), 'Read generic format with community-average weights';
isa_ok $in, 'Bio::Community::IO::Driver::generic';

is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
isa_ok $in->weight_files->[0], 'GLOB';
isa_ok $in->weight_files->[1], 'GLOB';
is $in->weight_assign, 'community_average';
is $in->weight_identifier, 'desc';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';
is $community->get_average_weights->[0], 1;
is $community->get_average_weights->[1], 200;

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';
delta_ok $community2->get_average_weights->[0], 0.777252926;
is $community2->get_average_weights->[1], 100;

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is_deeply $member->weights, [1, 200];
delta_ok $community->get_rel_ab($member), 100.0;
is $community->get_member_by_rank(2), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 64.5567627;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 100];
delta_ok $community2->get_rel_ab($member), 17.9131895;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 100];
delta_ok $community2->get_rel_ab($member), 17.5300478;
is $community2->get_member_by_rank(4), undef;


# Read qiime format with ID-based weight assignment

ok $in = Bio::Community::IO->new(
   -file              => test_input_file('qiime_w_greengenes_taxo.txt'),
   -format            => 'qiime',
   -taxonomy          => Bio::DB::Taxonomy->new( -source => 'list' ), # on-the-fly taxonomy
   -weight_files      => [ test_input_file('weights_otuid.txt') ],
   -weight_assign     => 'community_average',
   -weight_identifier => 'id',
), 'Read qiime format with ancestor-based weights';
isa_ok $in->weight_files->[0], 'GLOB';
is $in->weight_assign, 'community_average';
is $in->weight_identifier, 'id';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, '20100302';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 1;
is $community2->name, '20100304';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, '20100823';

is $in->next_community, undef;

is_deeply $in->weight_names(), ['factor'];

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'No blast hit';
is $community->get_count($member), 41;
is_deeply $member->weights, [50];
delta_ok $community->get_rel_ab($member), 50.6172840;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community->get_count($member), 40;
is_deeply $member->weights, [50];
delta_ok $community->get_rel_ab($member), 49.3827160;
is $community->get_member_by_rank(3), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community2->get_count($member), 142;
is_deeply $member->weights, [69];
delta_ok $community2->get_rel_ab($member), 100;
is $community2->get_member_by_rank(2), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community3->get_count($member), 76;
is_deeply $member->weights, [50];
delta_ok $community3->get_rel_ab($member), 63.2565448;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'No blast hit';
is $community3->get_count($member), 43;
delta_ok $member->weights->[0], 50.3555389221557;
delta_ok $community3->get_rel_ab($member), 35.5371901;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community3->get_count($member), 2;
is_deeply $member->weights, [69];
delta_ok $community3->get_rel_ab($member), 1.2062652;
is $community3->get_member_by_rank(4), undef;


# Read qiime format with ancestor-based weights

ok $in = Bio::Community::IO->new(
   -file              => test_input_file('qiime_w_greengenes_taxo.txt'),
   -format            => 'qiime',
   -taxonomy          => Bio::DB::Taxonomy->new( -source => 'list' ), # on-the-fly taxonomy
   -weight_files      => [ test_input_file('weights_taxstring.txt') ],
   -weight_assign     => 'ancestor',
   -weight_identifier => 'desc',
), 'Read qiime format with ancestor-based weights';
isa_ok $in->weight_files->[0], 'GLOB';
is $in->weight_assign, 'ancestor';
is $in->weight_identifier, 'desc';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, '20100302';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 1;
is $community2->name, '20100304';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, '20100823';

is $in->next_community, undef;

is_deeply $in->weight_names(), ['factor'];

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'No blast hit';
is $community->get_count($member), 41;
is_deeply $member->weights, [100];
delta_ok $community->get_rel_ab($member), 50.6172840;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community->get_count($member), 40;
is_deeply $member->weights, [100];
delta_ok $community->get_rel_ab($member), 49.3827160;
is $community->get_member_by_rank(3), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community2->get_count($member), 142;
is_deeply $member->weights, [300];
delta_ok $community2->get_rel_ab($member), 100;
is $community2->get_member_by_rank(2), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community3->get_count($member), 76;
is_deeply $member->weights, [100];
delta_ok $community3->get_rel_ab($member), 63.9022637;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'No blast hit';
is $community3->get_count($member), 43;
delta_ok $member->weights->[0], 101.739130434783;
delta_ok $community3->get_rel_ab($member), 35.5371901;
ok $member = $community3->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community3->get_count($member), 2;
is_deeply $member->weights, [300];
delta_ok $community3->get_rel_ab($member), 0.5605462;
is $community3->get_member_by_rank(4), undef;


done_testing();

exit;
