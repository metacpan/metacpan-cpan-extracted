#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

subtest rep_scas => \&test_rep_scas;
sub test_rep_scas {
	my (@asm, @out);
	for my $r (qw( repne repnz repe repz )) {
		for my $op (qw( scasb scasw scasd scasq )) {
			push @asm, "$r $op\n";
			push @out, new_writer->$r->$op->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'scas' );
}

subtest rep_cmps => \&test_rep_cmps;
sub test_rep_cmps {
	my (@asm, @out);
	for my $r (qw( repne repnz repe repz )) {
		for my $op (qw( cmpsb cmpsw cmpsd cmpsq )) {
			push @asm, "$r $op\n";
			push @out, new_writer->$r->$op->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'cmps' );
}
subtest rep_movs => \&test_rep_movs;
sub test_rep_movs {
	my (@asm, @out);
	for my $r (qw( repne repnz repe repz )) {
		for my $op (qw( movsb movsw movsd movsq )) {
			push @asm, "$r $op\n";
			push @out, new_writer->$r->$op->bytes;
		}
	}
	asm_ok( \@out, \@asm, 'movs' );
}

done_testing;
