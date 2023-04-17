#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

subtest inc => \&inc;
sub inc {
	my (@asm, @out);
	for my $r1 (@r64) {
		push @asm, "inc $r1";
		push @out, new_writer->inc64_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "inc qword $_[0]" },
		\@out, sub { new_writer->inc64_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'inc64');

	@asm= (); @out= ();
	for my $r1 (@r32) {
		push @asm, "inc $r1";
		push @out, new_writer->inc32_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "inc dword $_[0]" },
		\@out, sub { new_writer->inc32_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'inc32');

	@asm= (); @out= ();
	for my $r1 (@r16) {
		push @asm, "inc $r1";
		push @out, new_writer->inc16_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "inc word $_[0]" },
		\@out, sub { new_writer->inc16_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'inc16');
	
	@asm= (); @out= ();
	for my $r1 (@r8) {
		push @asm, "inc $r1";
		push @out, new_writer->inc8_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "inc byte $_[0]" },
		\@out, sub { new_writer->inc8_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'inc8');

	done_testing;
}

subtest dec => \&dec;
sub dec {
	my (@asm, @out);
	for my $r1 (@r64) {
		push @asm, "dec $r1";
		push @out, new_writer->dec64_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "dec qword $_[0]" },
		\@out, sub { new_writer->dec64_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'dec64');

	@asm= (); @out= ();
	for my $r1 (@r32) {
		push @asm, "dec $r1";
		push @out, new_writer->dec32_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "dec dword $_[0]" },
		\@out, sub { new_writer->dec32_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'dec32');

	@asm= (); @out= ();
	for my $r1 (@r16) {
		push @asm, "dec $r1";
		push @out, new_writer->dec16_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "dec word $_[0]" },
		\@out, sub { new_writer->dec16_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'dec16');
	
	@asm= (); @out= ();
	for my $r1 (@r8) {
		push @asm, "dec $r1";
		push @out, new_writer->dec8_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "dec byte $_[0]" },
		\@out, sub { new_writer->dec8_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'dec8');

	done_testing;
}

done_testing;
