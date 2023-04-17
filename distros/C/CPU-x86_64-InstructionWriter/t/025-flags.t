#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer asm_ok @r64 @r32 @r16 @r8 @r8h @immed64 @immed32 @immed16 @immed8 );
use Test::More;

my (@asm, @out);

my %alias= (
	clc => [ flag_carry => 0 ],
	cmc => [ flag_carry => -1 ],
	stc => [ flag_carry => 1 ],
	cld => [ flag_direction => 0 ],
	std => [ flag_direction => 1 ],
);
for my $op (sort keys %alias) {
	my ($method, $arg)= @{ $alias{$op} };
	push @asm, $op."\n".$op;
	push @out, new_writer->$op->$method($arg)->bytes;
}

asm_ok(\@out, \@asm, 'flag modifiers');

done_testing;
