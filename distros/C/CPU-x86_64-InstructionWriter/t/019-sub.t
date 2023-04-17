#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @immed32 @immed16 @immed8 );
use Test::More;

subtest sub_reg_reg => \&sub_reg_reg;
sub sub_reg_reg {
	my (@asm, @out);
	for my $r1 (@r64) {
		for my $r2 (@r64) {
			push @asm, "sub $r1, $r2";
			push @out, new_writer->sub64_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub64_reg_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r32) {
		for my $r2 (@r32) {
			push @asm, "sub $r1, $r2";
			push @out, new_writer->sub32_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub32_reg_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r16) {
		for my $r2 (@r16) {
			push @asm, "sub $r1, $r2";
			push @out, new_writer->sub16_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub16_reg_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r8) {
		for my $r2 (@r8) {
			push @asm, "sub $r1, $r2";
			push @out, new_writer->sub8_reg_reg($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub8_reg_reg' );
	
	done_testing;
}

subtest sub_reg_imm => \&sub_reg_imm;
sub sub_reg_imm {
	# Test immediate values of every bit length
	my (@asm, @out);
	for my $dst (@r64) {
		for my $val (@immed32) {
			push @asm, "sub $dst, $val";
			push @out, new_writer->sub64_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub64_reg_imm' );
	
	@asm= (); @out= ();
	for my $dst (@r32) {
		for my $val (@immed32) {
			push @asm, "sub $dst, $val";
			push @out, new_writer->sub32_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub32_reg_imm' );
	
	@asm= (); @out= ();
	for my $dst (@r16) {
		for my $val (@immed16) {
			push @asm, "sub $dst, $val";
			push @out, new_writer->sub16_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub16_reg_imm' );

	@asm= (); @out= ();
	for my $dst (@r8) {
		for my $val (@immed8) {
			push @asm, "sub $dst, $val";
			push @out, new_writer->sub8_reg_imm($dst, $val)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'sub8_reg_imm' );
}

subtest sub_mem => \&sub_mem;
sub sub_mem {
	my (@asm, @out);
	for my $dst (@r64) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub qword $dst, $_[0]" },
			\@out, sub { new_writer->sub64_reg_mem($dst, [@_])->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "sub qword $_[0], $dst" },
			\@out, sub { new_writer->sub64_mem_reg([@_], $dst)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub64_mem' );

	@asm= (); @out= ();
	for my $reg (@r32) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub dword $reg, $_[0]" },
			\@out, sub { new_writer->sub32_reg_mem($reg, [@_])->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "sub dword $_[0], $reg" },
			\@out, sub { new_writer->sub32_mem_reg([@_], $reg)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub32_mem' );
	
	@asm= (); @out= ();
	for my $reg (@r16) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub word $reg, $_[0]" },
			\@out, sub { new_writer->sub16_reg_mem($reg, [@_])->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "sub word $_[0], $reg" },
			\@out, sub { new_writer->sub16_mem_reg([@_], $reg)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub16_mem' );
	
	@asm= (); @out= ();
	for my $reg (@r8) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub byte $reg, $_[0]" },
			\@out, sub { new_writer->sub8_reg_mem($reg, [@_])->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "sub byte $_[0], $reg" },
			\@out, sub { new_writer->sub8_mem_reg([@_], $reg)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub8_mem' );

	done_testing;
}

subtest sub_const_mem => \&sub_const_mem;
sub sub_const_mem {
	my (@asm, @out);
	for my $immed (@immed32) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub qword $_[0], $immed" },
			\@out, sub { new_writer->sub64_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub64_mem_imm' );
	
	@asm= (); @out= ();
	for my $immed (@immed32) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub dword $_[0], $immed" },
			\@out, sub { new_writer->sub32_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub32_mem_imm' );
	
	@asm= (); @out= ();
	for my $immed (@immed16) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub word $_[0], $immed" },
			\@out, sub { new_writer->sub16_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub16_mem_imm' );
	
	@asm= (); @out= ();
	for my $immed (@immed8) {
		iterate_mem_addr_combos(
			\@asm, sub { "sub byte $_[0], $immed" },
			\@out, sub { new_writer->sub8_mem_imm([@_], $immed)->bytes }
		);
	}
	asm_ok( \@out, \@asm, 'sub8_mem_imm' );
	
	done_testing;
}

done_testing;
