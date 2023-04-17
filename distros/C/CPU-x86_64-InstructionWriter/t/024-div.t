#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer asm_ok iterate_mem_addr_combos @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

	my (@asm, @out);
	for my $r1 (@r64) {
		push @asm, "div $r1";
		push @out, new_writer->div64_reg($r1)->bytes;
		push @asm, "idiv $r1";
		push @out, new_writer->idiv64_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "div qword $_[0]" },
		\@out, sub { new_writer->div64_mem([@_])->bytes }
	);
	iterate_mem_addr_combos(
		\@asm, sub { "idiv qword $_[0]" },
		\@out, sub { new_writer->idiv64_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'div64');

	@asm= (); @out= ();
	for my $r1 (@r32) {
		push @asm, "div $r1";
		push @out, new_writer->div32_reg($r1)->bytes;
		push @asm, "idiv $r1";
		push @out, new_writer->idiv32_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "div dword $_[0]" },
		\@out, sub { new_writer->div32_mem([@_])->bytes }
	);
	iterate_mem_addr_combos(
		\@asm, sub { "idiv dword $_[0]" },
		\@out, sub { new_writer->idiv32_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'div32');

	@asm= (); @out= ();
	for my $r1 (@r16) {
		push @asm, "div $r1";
		push @out, new_writer->div16_reg($r1)->bytes;
		push @asm, "idiv $r1";
		push @out, new_writer->idiv16_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "div word $_[0]" },
		\@out, sub { new_writer->div16_mem([@_])->bytes }
	);
	iterate_mem_addr_combos(
		\@asm, sub { "idiv word $_[0]" },
		\@out, sub { new_writer->idiv16_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'div16');

	@asm= (); @out= ();
	for my $r1 (@r8) {
		push @asm, "div $r1";
		push @out, new_writer->div8_reg($r1)->bytes;
		push @asm, "idiv $r1";
		push @out, new_writer->idiv8_reg($r1)->bytes;
	}
	iterate_mem_addr_combos(
		\@asm, sub { "div byte $_[0]" },
		\@out, sub { new_writer->div8_mem([@_])->bytes }
	);
	iterate_mem_addr_combos(
		\@asm, sub { "idiv byte $_[0]" },
		\@out, sub { new_writer->idiv8_mem([@_])->bytes }
	);
	asm_ok(\@out, \@asm, 'div8');
	
subtest sign_extend => \&sign_extend;
sub sign_extend {
	@asm= (); @out= ();
	for (qw( cbw cwde cdqe cwd cdq cqo )) {
		push @asm, $_;
		push @out, new_writer->$_()->bytes;
	}
	asm_ok(\@out, \@asm, 'sign-extend for div');
}

done_testing;
