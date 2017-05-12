use strict;
use warnings;

use Code::DRY;
use Test::More tests => 7+1+6+5+5;
#########################

can_ok('Code::DRY', 'enter_files');
can_ok('Code::DRY', 'offset2fileindex');
can_ok('Code::DRY', 'offsetAndFileindex2line');
can_ok('Code::DRY', 'offset2line');
can_ok('Code::DRY', 'offset2filename');
can_ok('Code::DRY', 'clearData');
can_ok('Code::DRY', 'clip_lcp_to_fileboundaries');

# create some memory files
my @files;
push @files, join '', (map{ $_.";\n" } '0'..'9');
push @files, '';
push @files, join '', (map{ $_.";\n" } '0'..'9');
push @files, '';
push @files, join '', (map{ $_.";\n" } '0'..'9');
my @filerefs = map { \$_ } @files;

Code::DRY::enter_files(\@filerefs);
is(scalar @filerefs, scalar @files - 2, "enter_files(): filenames for empty files are deleted from the array");

# create some memory files
@files = ();
for my $i (0 .. 4) {
	push @files, join '', (map{ $_.";\n" } '0'..'9');
}
@filerefs = map { \$_ } @files;

Code::DRY::enter_files(\@filerefs);

is_deeply(\@Code::DRY::fileoffsets, [29,59,89,119,149], "check, if file offsets are correct");
is_deeply(\@Code::DRY::file_lineoffsets, [
	[2,5,8,11,14,17,20,23,26,29],
	[2,5,8,11,14,17,20,23,26,29],
	[2,5,8,11,14,17,20,23,26,29],
	[2,5,8,11,14,17,20,23,26,29],
	[2,5,8,11,14,17,20,23,26,29],
], "check, if line offsets are correct");

subtest 'check file index for all offsets' => sub {
	plan tests => 150 + 1;

	is(Code::DRY::offset2fileindex( $_ ), int($_ / 30), "check file index for offset $_...") for (0..149);
	is (Code::DRY::offset2fileindex( 150 ), undef, "offset outside range results in undef");
};

subtest 'check line number for all offsets' => sub {
	plan tests => 150 + 1;

	for (0 .. 149) {
		is(Code::DRY::offset2line( $_ ), 1 + (int($_ / 3) % 10), "check line number for offset $_...");
	}
	is (Code::DRY::offset2line( 150 ), undef, "offset outside range results in undef");
};

subtest 'check rounded line number for all offsets' => sub {
	plan tests => 450 + 3;

	my ($res, $up, $down);
	for (0 .. 149) {
		is($res = Code::DRY::offsetAndFileindex2line( $_, Code::DRY::offset2fileindex( $_ ), \$up, \$down ), 1 + (int($_ / 3) % 10), "check line number for offset $_...");
		is($up,    ($_ % 3) == 0                   ? $res : $res + 1, "check uprounded linenumbers");
		is($down, (($_ % 3) == 2 || ($_ % 30) < 3) ? $res : $res - 1, "check downrounded linenumbers");
	}
	$up = $down = undef;
	is ($res = Code::DRY::offsetAndFileindex2line( 150, Code::DRY::offset2fileindex( 150 ), \$up, \$down ), undef, "offset outside range results in undef");
	is($up,   undef, "check uprounded linenumbers");
	is($down, undef, "check downrounded linenumbers");
};

subtest 'check the clearData function' => sub {
	plan tests => 5;

	Code::DRY::clearData();

	is(Code::DRY::get_offset_at(0), 0xffffffff, 'suffix array should have been cleared in after calling clearData()');
	is(Code::DRY::get_len_at(0), 0xffffffff, 'longest common prefix array should have been cleared in after calling clearData()');
	is(Code::DRY::get_size(), 0, "size of data should be 0 after calling clearData()");
	is(scalar @Code::DRY::fileoffsets, 0, "file offsets should be empty after calling clearData()");
	is(scalar @Code::DRY::file_lineoffsets, 0, "line offsets should be empty after calling clearData()");
};


@files = ();
my $teststring = 'abcississississississi';
for my $i (0 .. 4) {
	push @files, substr($teststring, 5*$i, 5);
}
@filerefs = map { \$_ } @files;

Code::DRY::enter_files(\@filerefs);
Code::DRY::build_suffixarray_and_lcp(substr($teststring,0, 22));
#
# note: underscore in suffces denote a file boundary
# pos
# |  off
# |  |   lcp overlapping
# |  |   |  lcp limited to file
# |  |   |  | suffices
# |  |   |  | |
# 0  0:  -  - abcis_sissi_ssiss_issis_si
# 1  1:  0  0 bcis_sissi_ssiss_issis_si
# 2  2:  0  0 cis_sissi_ssiss_issis_si
# 3 21:  0  0 i
# 4 18:  1  1 is_si
# 5 15:  4  2 issis_si
# 6 12:  7  3 iss_issis_si
# 7  9: 10  1 i_ssiss_issis_si
# 8  6: 13  1 issi_ssiss_issis_si
# 9  3: 16  2 is_sissi_ssiss_issis_si
#10 20:  0  0 si
#11 17:  2  2 sis_si
#12 14:  5  1 s_issis_si
#13 11:  8  1 siss_issis_si
#14  8: 11  2 si_ssiss_issis_si
#15  5: 14  2 sissi_ssiss_issis_si
#16 19:  1  1 s_si
#17 16:  3  1 ssis_si
#18 13:  6  2 ss_issis_si
#19 10:  9  2 ssiss_issis_si
#20  7: 12  3 ssi_ssiss_issis_si
#21  4: 15  1 s_sissi_ssiss_issis_si



is_deeply([ map { Code::DRY::get_offset_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 1 2 21 18 15 12 9 6 3 20 17 14 11 8 5 19 16 13 10 7 4)], "case matches across files: check SA values");
is_deeply([ map { Code::DRY::get_isa_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 1 2 9 21 15 8 20 14 7 19 13 6 18 12 5 17 11 4 16 10 3)], "case matches across files: check ISA values");
is_deeply([ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 0 0 0 1 4 7 10 13 16 0 2 5 8 11 14 1 3 6 9 12 15)], "case matches across files: check unbounded LCP values");
Code::DRY::clip_lcp_to_fileboundaries(\@Code::DRY::fileoffsets);
is_deeply([ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 0 0 0 1 2 3 1 1 2 0 2 1 1 2 2 1 1 2 2 3 1)], "check if LCP values are limited now to its file offset range");
Code::DRY::reduce_lcp_to_nonoverlapping_lengths();
is_deeply([ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 0 0 0 1 2 3 1 1 2 0 2 1 1 2 2 1 1 2 2 3 1)], "check if LCP values are limited to non overlapping matches");

@filerefs = map { \$_ } ("1234", "1235", "235");
Code::DRY::enter_files(\@filerefs);
$teststring = join '', map { ${$_} } @filerefs;
Code::DRY::build_suffixarray_and_lcp($teststring);
is_deeply([ map { Code::DRY::get_offset_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 4 1 8 5 2 9 6 3 10 7)], "case no matches across files: check SA values not crossing files");
is_deeply([ map { Code::DRY::get_isa_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 2 5 8 1 4 7 10 3 6 9)], "case no matches across files: check ISA values not crossing files");
is_deeply([ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 3 0 2 3 0 1 2 0 0 1)], "case no matches across files: check unbounded LCP values");
Code::DRY::reduce_lcp_to_nonoverlapping_lengths();
is_deeply([ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 3 0 2 3 0 1 2 0 0 1)], "case no matches across files: check if LCP values limited to non overlapping matches");
Code::DRY::clip_lcp_to_fileboundaries(\@Code::DRY::fileoffsets);
is_deeply([ map { Code::DRY::get_len_at($_) } (0 .. Code::DRY::get_size()-1)],
          [qw(0 3 0 2 3 0 1 2 0 0 1)], "case no matches across files: check if LCP values are not limited");
