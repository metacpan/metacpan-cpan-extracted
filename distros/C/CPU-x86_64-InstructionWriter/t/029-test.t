#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

subtest test_reg_reg => \&test_reg_reg;
sub test_reg_reg {
	my (@asm, @out);
	for my $r1 (@r64) {
		for my $r2 (@r64) {
			push @asm, "test $r1, $r2";
			push @out, new_writer->test64_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test64_reg_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r32) {
		for my $r2 (@r32) {
			push @asm, "test $r1, $r2";
			push @out, new_writer->test32_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test32_reg_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r16) {
		for my $r2 (@r16) {
			push @asm, "test $r1, $r2";
			push @out, new_writer->test16_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test16_reg_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r8) {
		for my $r2 (@r8) {
			push @asm, "test $r1, $r2";
			push @out, new_writer->test8_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test8_reg_reg' );
	
	done_testing;
}

subtest test_reg_imm => \&test_reg_imm;
sub test_reg_imm {
	# Test immediate values of every bit length
	my (@asm, @out);
	for my $dst (@r64) {
		for my $val (@immed32) {
			push @asm, "test $dst, $val";
			push @out, new_writer->test64_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test64_reg_imm' );
	
	@asm= (); @out= ();
	for my $dst (@r32) {
		for my $val (@immed32) {
			push @asm, "test $dst, $val";
			push @out, new_writer->test32_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test32_reg_imm' );
	
	@asm= (); @out= ();
	for my $dst (@r16) {
		for my $val (@immed16) {
			push @asm, "test $dst, $val";
			push @out, new_writer->test16_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test16_reg_imm' );

	@asm= (); @out= ();
	for my $dst (@r8) {
		for my $val (@immed8) {
			push @asm, "test $dst, $val";
			push @out, new_writer->test8_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'test8_reg_imm' );
}

subtest test_reg_mem => \&test_reg_mem;
sub test_reg_mem {
	my (@asm, @out);
	for my $reg (@r64) {
		iterate_mem_addr_combos(
			\@asm, sub { "test $reg, $_[0]" },
			\@out, sub { new_writer->test64_reg_mem($reg, [@_])->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test64_reg_mem' );

	@asm= (); @out= ();
	for my $reg (@r32) {
		iterate_mem_addr_combos(
			\@asm, sub { "test $reg, $_[0]" },
			\@out, sub { new_writer->test32_reg_mem($reg, [@_])->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test32_reg_mem' );
	
	@asm= (); @out= ();
	for my $reg (@r16) {
		iterate_mem_addr_combos(
			\@asm, sub { "test $reg, $_[0]" },
			\@out, sub { new_writer->test16_reg_mem($reg, [@_])->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test16_reg_mem' );
	
	@asm= (); @out= ();
	for my $reg (@r8) {
		iterate_mem_addr_combos(
			\@asm, sub { "test $reg, $_[0]" },
			\@out, sub { new_writer->test8_reg_mem($reg, [@_])->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test8_reg_mem' );

	done_testing;
}

subtest test_mem_imm => \&test_mem_imm;
sub test_mem_imm {
	my (@asm, @out);
	for my $immed (@immed32) {
		iterate_mem_addr_combos(
			\@asm, sub { "test qword $_[0], $immed" },
			\@out, sub { new_writer->test64_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test64_mem_imm' );
	
	@asm= (); @out= ();
	for my $immed (@immed32) {
		iterate_mem_addr_combos(
			\@asm, sub { "test dword $_[0], $immed" },
			\@out, sub { new_writer->test32_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test32_mem_imm' );
	
	@asm= (); @out= ();
	for my $immed (@immed16) {
		iterate_mem_addr_combos(
			\@asm, sub { "test word $_[0], $immed" },
			\@out, sub { new_writer->test16_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test16_mem_imm' );
	
	@asm= (); @out= ();
	for my $immed (@immed8) {
		iterate_mem_addr_combos(
			\@asm, sub { "test byte $_[0], $immed" },
			\@out, sub { new_writer->test8_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'test8_mem_imm' );
	
	done_testing;
}

done_testing;
