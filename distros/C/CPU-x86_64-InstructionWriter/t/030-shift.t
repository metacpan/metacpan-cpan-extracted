#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed32 @immed16 @immed8 );
use Test::More;

my @shift8=  (0, 1, 2, 4, 7);
my @shift16= (@shift8, 15, 16);
my @shift32= (@shift16, 30, 31);
my @shift64= (@shift32, 62, 63);

subtest shr_reg => \&shr_reg;
sub shr_reg {
	my (@asm, @out);
	for my $r1 (@r64) {
		for my $sh (@shift64) {
			push @asm, "shr $r1, $sh";
			push @out, new_writer->shr64_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shr $r1, cl";
		push @out, new_writer->shr64_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shr64_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r32) {
		for my $sh (@shift32) {
			push @asm, "shr $r1, $sh";
			push @out, new_writer->shr32_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shr $r1, cl";
		push @out, new_writer->shr32_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shr32_reg_imm' );
	
	@asm= (); @out= ();
	for my $r1 (@r16) {
		for my $sh (@shift16) {
			push @asm, "shr $r1, $sh";
			push @out, new_writer->shr16_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shr $r1, cl";
		push @out, new_writer->shr16_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shr16_reg_imm' );
	
	@asm= (); @out= ();
	for my $r1 (@r8, @r8h) {
		for my $sh (@shift8) {
			push @asm, "shr $r1, $sh";
			push @out, new_writer->shr8_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shr $r1, cl";
		push @out, new_writer->shr8_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shr8_reg_imm' );
	
	done_testing;
}

subtest shr_mem => \&shr_mem;
sub shr_mem {
	my (@asm, @out);
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shr qword $_[0], $sh" },
			\@out, sub { new_writer->shr64_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shr qword $_[0], cl" },
		\@out, sub { new_writer->shr64_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shr64_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shr dword $_[0], $sh" },
			\@out, sub { new_writer->shr32_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shr dword $_[0], cl" },
		\@out, sub { new_writer->shr32_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shr32_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shr word $_[0], $sh" },
			\@out, sub { new_writer->shr16_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shr word $_[0], cl" },
		\@out, sub { new_writer->shr16_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shr16_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shr byte $_[0], $sh" },
			\@out, sub { new_writer->shr8_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shr byte $_[0], cl" },
		\@out, sub { new_writer->shr8_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shr8_mem_imm' );
	
	done_testing;
}

subtest shl_reg => \&shl_reg;
sub shl_reg {
	my (@asm, @out);
	for my $r1 (@r64) {
		for my $sh (@shift64) {
			push @asm, "shl $r1, $sh";
			push @out, new_writer->shl64_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shl $r1, cl";
		push @out, new_writer->shl64_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shl64_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r32) {
		for my $sh (@shift32) {
			push @asm, "shl $r1, $sh";
			push @out, new_writer->shl32_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shl $r1, cl";
		push @out, new_writer->shl32_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shl32_reg_imm' );
	
	@asm= (); @out= ();
	for my $r1 (@r16) {
		for my $sh (@shift16) {
			push @asm, "shl $r1, $sh";
			push @out, new_writer->shl16_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shl $r1, cl";
		push @out, new_writer->shl16_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shl16_reg_imm' );
	
	@asm= (); @out= ();
	for my $r1 (@r8, @r8h) {
		for my $sh (@shift8) {
			push @asm, "shl $r1, $sh";
			push @out, new_writer->shl8_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "shl $r1, cl";
		push @out, new_writer->shl8_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'shl8_reg_imm' );
	
	done_testing;
}

subtest shl_mem => \&shl_mem;
sub shl_mem {
	my (@asm, @out);
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shl qword $_[0], $sh" },
			\@out, sub { new_writer->shl64_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shl qword $_[0], cl" },
		\@out, sub { new_writer->shl64_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shl64_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shl dword $_[0], $sh" },
			\@out, sub { new_writer->shl32_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shl dword $_[0], cl" },
		\@out, sub { new_writer->shl32_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shl32_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shl word $_[0], $sh" },
			\@out, sub { new_writer->shl16_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shl word $_[0], cl" },
		\@out, sub { new_writer->shl16_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shl16_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "shl byte $_[0], $sh" },
			\@out, sub { new_writer->shl8_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "shl byte $_[0], cl" },
		\@out, sub { new_writer->shl8_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'shl8_mem_imm' );
	
	done_testing;
}

subtest sar_reg => \&sar_reg;
sub sar_reg {
	my (@asm, @out);
	for my $r1 (@r64) {
		for my $sh (@shift64) {
			push @asm, "sar $r1, $sh";
			push @out, new_writer->sar64_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "sar $r1, cl";
		push @out, new_writer->sar64_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'sar64_reg' );
	
	@asm= (); @out= ();
	for my $r1 (@r32) {
		for my $sh (@shift32) {
			push @asm, "sar $r1, $sh";
			push @out, new_writer->sar32_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "sar $r1, cl";
		push @out, new_writer->sar32_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'sar32_reg_imm' );
	
	@asm= (); @out= ();
	for my $r1 (@r16) {
		for my $sh (@shift16) {
			push @asm, "sar $r1, $sh";
			push @out, new_writer->sar16_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "sar $r1, cl";
		push @out, new_writer->sar16_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'sar16_reg_imm' );
	
	@asm= (); @out= ();
	for my $r1 (@r8, @r8h) {
		for my $sh (@shift8) {
			push @asm, "sar $r1, $sh";
			push @out, new_writer->sar8_reg_imm($r1, $sh)->bytes;
		}
		push @asm, "sar $r1, cl";
		push @out, new_writer->sar8_reg_cl($r1)->bytes;
	}
	asm_ok( \@out, \@asm, 'sar8_reg_imm' );
	
	done_testing;
}

subtest sar_mem => \&sar_mem;
sub sar_mem {
	my (@asm, @out);
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "sar qword $_[0], $sh" },
			\@out, sub { new_writer->sar64_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "sar qword $_[0], cl" },
		\@out, sub { new_writer->sar64_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'sar64_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "sar dword $_[0], $sh" },
			\@out, sub { new_writer->sar32_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "sar dword $_[0], cl" },
		\@out, sub { new_writer->sar32_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'sar32_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "sar word $_[0], $sh" },
			\@out, sub { new_writer->sar16_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "sar word $_[0], cl" },
		\@out, sub { new_writer->sar16_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'sar16_mem_imm' );
	
	@asm= (); @out= ();
	for my $sh (@shift8) {
		iterate_mem_addr_combos(
			\@asm, sub { "sar byte $_[0], $sh" },
			\@out, sub { new_writer->sar8_mem_imm([@_], $sh)->bytes }
		);
	}
	iterate_mem_addr_combos(
		\@asm, sub { "sar byte $_[0], cl" },
		\@out, sub { new_writer->sar8_mem_cl([@_])->bytes }
	);
	asm_ok( \@out, \@asm, 'sar8_mem_imm' );
	
	done_testing;
}

done_testing;
