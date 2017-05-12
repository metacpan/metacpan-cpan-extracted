use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $meta);
my @methods;

 
# IO driver mechanism

ok $in = Bio::Community::IO->new(
   -format => 'dummy',
   -file   => $0,
), 'IO driver mechanism';
isa_ok $in, 'Bio::Root::RootI';
isa_ok $in, 'Bio::Root::IO';
isa_ok $in, 'Bio::Community::IO';
isa_ok $in, 'Bio::Community::IO::Driver::dummy';
is $in->format, 'dummy';
is $in->sort_members, 0;

@methods = qw( next_member write_member
               next_community _next_community_init _next_community_finish
               write_community _write_community_init _write_community_finish
               next_metacommunity _next_metacommunity_init _next_metacommunity_finish
               write_metacommunity _write_metacommunity_init _write_metacommunity_finish
               sort_members abundance_type missing_string multiple_communities explicit_ids
               weight_files weight_assign taxonomy );

for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $in->dummy('this is a test');
is $in->dummy, 'this is a test';
$in->close;


# Read / write metacommunity

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('generic_table.txt'),
), 'Read and write a metacommunity';

ok $meta = $in->next_metacommunity;
is $in->next_metacommunity, undef;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
is $meta->get_members_count, 1721.9;
is $meta->get_communities_count, 2;
is $meta->get_richness, 3;
$in->close;

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
);
ok $out->write_metacommunity($meta);
throws_ok { $out->write_metacommunity($meta) } qr/EXCEPTION/, 'Exception';
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
);
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
is $meta->get_members_count, 1721.9;
is $meta->get_communities_count, 2;
is $meta->get_richness, 3;
$in->close;


# Read / write communities

ok $in = Bio::Community::IO->new(
   -file     => test_input_file('gaas_compo.txt'),
   -format   => 'gaas',
), 'Read and write a community';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file     => '>'.$output_file,
   -format   => 'gaas',
);
ok $out->write_community($community);
$community->name('2nd community');
throws_ok {$out->write_community($community)} qr/EXCEPTION/, 'Exception';
$out->close;


# Files with Bio::Community-generated IDs

warning_is {
   $in = Bio::Community::IO->new(
      -file     => test_input_file('qiime_w_bc_ids.txt'),
      -format   => 'qiime',
   );
   $in->next_community;
} undef, 'No warnings reading Bio::Community IDs';


# -weight_files is tested in t/IO/weights.t


done_testing();

exit;
