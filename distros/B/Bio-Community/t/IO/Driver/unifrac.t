use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::DB::Taxonomy;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $meta, $community, $community2, $community3,
   $member, $count, $taxonomy);
my (@communities, @methods, @members);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative.txt'),
), 'Format detection';
is $in->format, 'unifrac';


# Read UniFrac metacommunity

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative.txt'),
   -format => 'unifrac',
), 'Read Unifrac metacommunity';
ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
is $meta->get_members_count, 36;
is $meta->get_communities_count, 3;
is $meta->get_richness, 6;
$in->close;


# Write UniFrac metacommunity with name

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'unifrac',
), 'Write Unifrac metacommunity with a name';
ok $out->write_metacommunity($meta);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'unifrac',
);
ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
is $meta->get_members_count, 36;
is $meta->get_communities_count, 3;
is $meta->get_richness, 6;
$in->close;


# Read Unifrac quantitative format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative.txt'),
   -format => 'unifrac',
), 'Read Unifrac quantitative format';
isa_ok $in, 'Bio::Community::IO::Driver::unifrac';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
is $in->multiple_communities, 1;
is $in->explicit_ids, 0;

@methods = qw(
  _next_metacommunity_init _next_community_init next_member _next_community_finish _next_metacommunity_finish
  _write_metacommunity_init _write_community_init write_member _write_community_finish _write_metacommunity_finish)
;
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 4;
is $community->name, 'Sample.1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'Sample.2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 2;
is $community3->name, 'Sample 3';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community->get_count($member), 15;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community->get_count($member), 4;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence 3';
delta_ok $community->get_count($member), 2;
ok $member = $community->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 1;
is $community->get_member_by_rank(5), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.4';
delta_ok $community2->get_count($member), 8;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community2->get_count($member), 2;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
is $community2->get_member_by_rank(4), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community3->get_count($member), 1;
is $community3->get_member_by_rank(3), undef;

# Write Unifrac quantitative format

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'unifrac',
), 'Write Unifrac quantitative format';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'unifrac',
), 'Re-read Unifrac quantitative format';

ok $community = $in->next_community;
is $community->name, 'Sample.1';
ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community->get_count($member), 15;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community->get_count($member), 4;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.3'; # space replaced by underscore
delta_ok $community->get_count($member), 2;
ok $member = $community->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 1;
is $community->get_member_by_rank(5), undef;

ok $community2 = $in->next_community;
is $community2->name, 'Sample.2';
ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.4';
delta_ok $community2->get_count($member), 8;
ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community2->get_count($member), 2;
ok $member = $community2->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
is $community2->get_member_by_rank(4), undef;

ok $community3 = $in->next_community;
is $community3->name, 'Sample.3'; # space replaced by dot
ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community3->get_count($member), 2;
ok $member = $community3->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community3->get_count($member), 1;
is $community3->get_member_by_rank(3), undef;

$in->close;


# Read Unifrac qualitative format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_qualitative.txt'),
   -format => 'unifrac',
), 'Read Unifrac qualitative format';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 4;
is $community->name, 'Sample.1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'Sample.2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 1;
is $community3->name, 'Sample.3';

is $in->next_community, undef;

$in->close;

@members = sort {$a->desc cmp $b->desc} @{$community->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.1', 'Sequence.2', 'Sequence.3', 'Sequence.5'];
is_deeply [map {$community->get_count($_)} @members], [1,1,1,1];

@members = sort {$a->desc cmp $b->desc} @{$community2->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.1', 'Sequence.4', 'Sequence.6'];
is_deeply [map {$community2->get_count($_)} @members], [1, 1, 1];

@members = sort {$a->desc cmp $b->desc} @{$community3->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.6'];
is_deeply [map {$community3->get_count($_)} @members], [1];

# Write Unifrac qualitative format

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'unifrac',
), 'Write Unifrac qualitative format';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'unifrac',
), 'Re-read Unifrac qualitative format';

ok $community = $in->next_community;
@members = sort {$a->desc cmp $b->desc} @{$community->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.1', 'Sequence.2', 'Sequence.3', 'Sequence.5'];
is_deeply [map {$community->get_count($_)} @members], [1,1,1,1];

ok $community2 = $in->next_community;
@members = sort {$a->desc cmp $b->desc} @{$community2->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.1', 'Sequence.4', 'Sequence.6'];
is_deeply [map {$community2->get_count($_)} @members], [1, 1, 1];

ok $community3 = $in->next_community;
@members = sort {$a->desc cmp $b->desc} @{$community3->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.6'];
is_deeply [map {$community3->get_count($_)} @members], [1];

is $in->next_community, undef;

$in->close;


# Read Unifrac quantitative format (with relative abundances)

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative_relab.txt'),
   -format => 'unifrac',
), 'Read Unifrac quantitative format (relative abundances)';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 4;
is $community->name, 'Sample.1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'Sample.2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 1;
is $community3->name, 'Sample.3';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community->get_count($member), 0.15;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.3';
delta_ok $community->get_count($member), 0.20;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 0.25;
ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community->get_count($member), 0.4;
is $community->get_member_by_rank(5), undef;

ok $member = $community2->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 0.1;
ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.4';
delta_ok $community2->get_count($member), 0.9;
is $community2->get_member_by_rank(3), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community3->get_count($member), 1.0;
is $community3->get_member_by_rank(2), undef;

# Write Unifrac Unifrac quantitative format (with relative abundances)

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'unifrac',
), 'Write Unifrac quantitative format (relative abundances)';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'unifrac',
), 'Re-read Unifrac quantitative format (relative abundances)';

ok $community = $in->next_community;
@members = sort {$a->desc cmp $b->desc} @{$community->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.1', 'Sequence.2', 'Sequence.3', 'Sequence.5'];
is_deeply [map {$community->get_count($_)} @members], [0.25, 0.15, 0.20, 0.4];

ok $community2 = $in->next_community;
@members = sort {$a->desc cmp $b->desc} @{$community2->get_all_members};
is_deeply [map {$_->desc} @members], ['Sequence.4', 'Sequence.6'];
is_deeply [map {$community2->get_count($_)} @members], [0.9, 0.1];

ok $community3 = $in->next_community;
@members = sort {$a->desc cmp $b->desc} @{$community3->get_all_members};
is_deeply [sort map {$_->desc} @members], ['Sequence.6'];
is_deeply [map {$community3->get_count($_)} @members], [1.0];

is $in->next_community, undef;

$in->close;


# Read Unifrac quantitative format (with some missing values)

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative_tricky.txt'),
   -format => 'unifrac',
), 'Read a tricky Unifrac file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 4;
is $community->name, 'Sample.1';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 1;
is $community2->name, 'Sample.2';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 1;
is $community3->name, 'Sample.3';

is $in->next_community, undef;

$in->close;

ok $member = $community->get_member_by_rank(4);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 1;
ok $member = $community->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community->get_count($member), 15;
ok $member = $community->get_member_by_rank(3);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.3';
delta_ok $community->get_count($member), 2;
ok $member = $community->get_member_by_rank(2);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community->get_count($member), 4;
is $community->get_member_by_rank(5), undef;

ok $member = $community2->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
is $community2->get_member_by_rank(2), undef;

ok $member = $community3->get_member_by_rank(1);
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community3->get_count($member), 1;
is $community3->get_member_by_rank(2), undef;


done_testing();

exit;
