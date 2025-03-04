#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r128 @r64 @r32 );
use Test::More;

subtest mov_xreg_xreg => sub {
	my (@asm, @out);
	for my $r1 (@r128) {
		for my $r2 (@r128) {
			push @asm, "movq $r1, $r2";
			push @out, new_writer->movq($r1, $r2)->bytes;
		}
		for my $r2 (@r128) {
			push @asm, "movss $r1, $r2";
			push @out, new_writer->movss($r1, $r2)->bytes;
		}
		for my $r2 (@r128) {
			push @asm, "movsd $r1, $r2";
			push @out, new_writer->movsd($r1, $r2)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'movq_xreg_xreg' );
	
	done_testing;
};

subtest mov_xreg_reg => sub {
	my (@asm, @out);
	for my $r1 (@r128) {
		for my $r2 (@r32) {
			push @asm, "movd $r1, $r2";
			push @out, new_writer->movd($r1, $r2)->bytes;
			push @asm, "movd $r2, $r1";
			push @out, new_writer->movd($r2, $r1)->bytes;
		}
		for my $r2 (@r64) {
			push @asm, "movq $r1, $r2";
			push @out, new_writer->movq($r1, $r2)->bytes;
			push @asm, "movq $r2, $r1";
			push @out, new_writer->movq($r2, $r1)->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'movd_xreg_reg' );
	
	done_testing;
};

subtest mov_xreg_mem => sub {
	my (@asm, @out);
	for my $r1 (@r128) {
		iterate_mem_addr_combos(
			\@asm, sub { "movd $_[0], $r1" },
			\@out, sub { new_writer->movd([@_], $r1)->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "movd $r1, $_[0]" },
			\@out, sub { new_writer->movd($r1, [@_])->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "movq $_[0], $r1" },
			\@out, sub { new_writer->movq([@_], $r1)->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "movq $r1, $_[0]" },
			\@out, sub { new_writer->movq($r1, [@_])->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "movss $_[0], $r1" },
			\@out, sub { new_writer->movss([@_], $r1)->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "movss $r1, $_[0]" },
			\@out, sub { new_writer->movss($r1, [@_])->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "movsd $_[0], $r1" },
			\@out, sub { new_writer->movsd([@_], $r1)->bytes }
		);
		iterate_mem_addr_combos(
			\@asm, sub { "movsd $r1, $_[0]" },
			\@out, sub { new_writer->movsd($r1, [@_])->bytes }
		);
	}
	# RIP-relative
	my $writer= new_writer;
	my $asm= '';
	my $label= "mydata";
	for my $op (qw( movd movq movss movsd )) {
		my ($mov_reg_mem, $mov_mem_reg)= ("${op}_xreg_mem", "${op}_mem_xreg");
		for (@r128) {
			$asm .= "$op $_, [ rel $label ]\n";
			$asm .= "$op [ rel $label ], $_\n";
			$writer->$mov_reg_mem($_, [ RIP => \$label ]);
			$writer->$mov_mem_reg([ RIP => \$label ], $_);
		}
	}
	push @asm, $asm . "$label: dq 42\n";
	push @out, $writer->label($label)->data_i64(42)->bytes;
	asm_ok( \@out, \@asm, 'movq_xreg_mem' );
	
	done_testing;
};

done_testing;
