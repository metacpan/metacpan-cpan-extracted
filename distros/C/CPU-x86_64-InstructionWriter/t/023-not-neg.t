#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

subtest not => \&not;
sub not {
	my (@asm, @out);
	for my $r1 (@r64) {
		push @asm, "not $r1";
		push @out, new_writer->not64_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "not qword $_[0]" },
		\@out, sub { new_writer->not64_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'not64');

	@asm= (); @out= ();
	for my $r1 (@r32) {
		push @asm, "not $r1";
		push @out, new_writer->not32_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "not dword $_[0]" },
		\@out, sub { new_writer->not32_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'not32');

	@asm= (); @out= ();
	for my $r1 (@r16) {
		push @asm, "not $r1";
		push @out, new_writer->not16_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "not word $_[0]" },
		\@out, sub { new_writer->not16_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'not16');
	
	@asm= (); @out= ();
	for my $r1 (@r8) {
		push @asm, "not $r1";
		push @out, new_writer->not8_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "not byte $_[0]" },
		\@out, sub { new_writer->not8_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'not8');

	done_testing;
}

subtest neg => \&neg;
sub neg {
	my (@asm, @out);
	for my $r1 (@r64) {
		push @asm, "neg $r1";
		push @out, new_writer->neg64_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "neg qword $_[0]" },
		\@out, sub { new_writer->neg64_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'neg64');

	@asm= (); @out= ();
	for my $r1 (@r32) {
		push @asm, "neg $r1";
		push @out, new_writer->neg32_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "neg dword $_[0]" },
		\@out, sub { new_writer->neg32_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'neg32');

	@asm= (); @out= ();
	for my $r1 (@r16) {
		push @asm, "neg $r1";
		push @out, new_writer->neg16_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "neg word $_[0]" },
		\@out, sub { new_writer->neg16_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'neg16');
	
	@asm= (); @out= ();
	for my $r1 (@r8) {
		push @asm, "neg $r1";
		push @out, new_writer->neg8_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "neg byte $_[0]" },
		\@out, sub { new_writer->neg8_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'neg8');

	done_testing;
}

done_testing;
