use strict;
use warnings;

use Code::DRY;
use Test::More;
use Config;
#########################

if ($Config{'useperlio'}) {
	plan tests => 9+11+10+12+3+7+4+5;
} else {
	plan tests => 9+10;
}
can_ok('Code::DRY', 'enter_files');
can_ok('Code::DRY', 'offset2fileindex');
can_ok('Code::DRY', 'offsetAndFileindex2line');
can_ok('Code::DRY', 'offset2line');
can_ok('Code::DRY', 'offset2filename');
can_ok('Code::DRY', 'clearData');
can_ok('Code::DRY', 'clip_lcp_to_fileboundaries');
can_ok('Code::DRY', 'get_line_offsets_of_fileindex');
can_ok('Code::DRY', 'get_concatenated_text');

is(!defined Code::DRY::offset2fileindex(undef),1,"offset2fileindex(undef): undefined without files");
is(!defined Code::DRY::offset2fileindex(0),1,"offset2fileindex(0):undefined for offset 0 without files");
is(!defined Code::DRY::offset2fileindex(-1),1,"offset2fileindex(-1):undefined for offset 0 without files");
is(!defined Code::DRY::offset2fileindex(99999999),1,"offset2fileindex(99999999): undefined for big offset without files");
is(!defined Code::DRY::offset2filename(undef), 1, "offset2filename(undef): undefined without files");
is(!defined Code::DRY::offset2filename(0), 1, "offset2filename(0): undefined for offset 0 without files");
is(!defined Code::DRY::offset2filename(99999999), 1, "offset2filename(99999999): undefined for big offset without files");
is(!defined Code::DRY::offsetAndFileindex2line(undef, undef, undef, undef), 1, "offsetAndFileindex2line(undef): undefined without files");
is(!defined Code::DRY::offsetAndFileindex2line(0, undef, undef, undef), 1, "offsetAndFileindex2line(0): undefined for offset 0 without files");
is(!defined Code::DRY::offsetAndFileindex2line(99999999,undef,undef,undef), 1, "offsetAndFileindex2line(99999999): undefined for big offset without files");
is(!defined Code::DRY::get_concatenated_text(0, 999999999), 1,"check, if concatenated text is undef");

# tests use in-memory files (dependent on Perl configuration useperlio)
if ($Config{'useperlio'}) {
	my (@files, @filerefs);
	push @files, join '', (map{ $_.";\n" } ('0'));
	push @files, '';
	@filerefs = map { \$_ } @files;
	Code::DRY::enter_files(\@filerefs);

	is(!defined Code::DRY::offset2fileindex(undef),1,"offset2fileindex(undef): 0 with one file");
	is(Code::DRY::offset2fileindex(0),0,"offset2fileindex(0): 0 for offset 0 with one file");
	is(Code::DRY::offset2fileindex(-1),0,"offset2fileindex(-1): 0 for offset 0 with one file");
	is(Code::DRY::offset2fileindex(99999999),0,"offset2fileindex(99999999): 0 for too big offset with one file");
	is(!defined Code::DRY::offset2filename(undef), 1, "offset2filename(undef): undefined with one file");
	is(!defined Code::DRY::offset2filename(0), 1, "offset2filename(0): undefined for offset 0 with one file");
	is(!defined Code::DRY::offset2filename(99999999), 1, "offset2filename(99999999): undefined for big offset with one file");
	is(!defined Code::DRY::offsetAndFileindex2line(undef, 0, undef, undef), 1, "offsetAndFileindex2line(undef): 0 with one file");
	is(Code::DRY::offsetAndFileindex2line(0, 0, undef, undef), 0, "offsetAndFileindex2line(0): undefined for offset 0 with one file");
	is(Code::DRY::offsetAndFileindex2line(99999999,0,undef,undef), 0, "offsetAndFileindex2line(99999999): undefined for big offset with one file");

	# create some more memory files
	push @files, join '', (map{ $_.";\n" } '0'..'1');
	push @files, '';
	@filerefs = map { \$_ } @files;
	Code::DRY::enter_files(\@filerefs);

	is(!defined Code::DRY::offset2fileindex(undef),1,"offset2fileindex(undef): 0 with two files");
	is(Code::DRY::offset2fileindex(0),0,"offset2fileindex(0): 0 for offset 0 with two files");
	is(Code::DRY::offset2fileindex(-1),0,"offset2fileindex(-1): 0 for offset 0 with two files");
	is(!defined Code::DRY::offset2fileindex(99999999),1,"offset2fileindex(99999999): 0 for too big offset with two files");
	is(!defined Code::DRY::offset2filename(undef), 1, "offset2filename(undef): undefined with two files");
	is(!defined Code::DRY::offset2filename(0), 1, "offset2filename(0): undefined for offset 0 with two files");
	is(!defined Code::DRY::offset2filename(99999999), 1, "offset2filename(99999999): undefined for big offset with two files");
	is(!defined Code::DRY::offsetAndFileindex2line(undef, 1, undef, undef), 1, "offsetAndFileindex2line(undef): undefined with two files");
	is(Code::DRY::offsetAndFileindex2line(0, 1, undef, undef), 1, "offsetAndFileindex2line(0): undefined for offset 0 with two files");
	is(!defined Code::DRY::offsetAndFileindex2line(99999999,1,undef,undef), 1, "offsetAndFileindex2line(99999999): undefined for big offset with two files");

	push @files, join '', (map{ $_.";\n" } '0'..'9');
	@filerefs = map { \$_ } @files;

	# add an empty file
	my $emptytmpfilename = 't/empty';
	push @filerefs, $emptytmpfilename;

	eval { Code::DRY::enter_files([ 't/nonexistant' ]); };
	# TODO check exception

	Code::DRY::enter_files(\@filerefs);
	is(scalar @filerefs, scalar @files - 2, 'enter_files(): filenames for empty files are deleted from the array');

	# Link file tests
	SKIP: {
		my $can_hardlink = link 't/00_lowlevel.t', 'xt/hardlink';

		skip('this OS does not seem to support hard links', 1) if (!$can_hardlink);

		# add a file and its hard link
		@filerefs = ( 't/00_lowlevel.t', 'xt/hardlink' );
		Code::DRY::enter_files(\@filerefs);
		is(scalar @filerefs, 1, 'enter_files(): filenames for hard linked files are deleted from the array');

		# cleanup
		unlink 'xt/hardlink';
	}
	SKIP: {
		my $can_symlink = eval { symlink '../t/00_lowlevel.t', 'xt/symlink'; 1 };

		skip('this OS does not seem to support symbolic links', 1) if (!$can_symlink);

		# add a file and its sym link
		@filerefs = ( 't/00_lowlevel.t', 'xt/symlink' );
		Code::DRY::enter_files(\@filerefs);
		is(scalar @filerefs, 1, 'enter_files(): filenames for symbolically linked files are deleted from the array');

		# cleanup
		unlink 'xt/symlink';
	}
	# create some memory files
	@files = ();
	my $codetotal = '';
	for my $i (0 .. 4) {
		push @files, join '', (map{ $_.";\n" } '0'..'9');
		$codetotal .= $files[-1];
	}
	@filerefs = map { \$_ } @files;

	Code::DRY::enter_files(\@filerefs);

	is_deeply(Code::DRY::get_concatenated_text(0, length $codetotal), $codetotal,"check, if concatenated text is correct");
	is_deeply(\@Code::DRY::fileoffsets, [29,59,89,119,149], "check, if file offsets are correct");
	is_deeply(\@Code::DRY::file_lineoffsets, [
		[2,5,8,11,14,17,20,23,26,29],
		[2,5,8,11,14,17,20,23,26,29],
		[2,5,8,11,14,17,20,23,26,29],
		[2,5,8,11,14,17,20,23,26,29],
		[2,5,8,11,14,17,20,23,26,29],
	], "check, if line offsets are correct");
	my @fileLineOffsets;
	for my $fo (0 .. $#Code::DRY::fileoffsets) {
		push @fileLineOffsets, Code::DRY::get_line_offsets_of_fileindex($fo);
	}
	is_deeply(\@Code::DRY::file_lineoffsets, \@fileLineOffsets, "check, if line offsets are returned correctly by getter function");

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
	# note: underscore in suffices denote a file boundary
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
}
