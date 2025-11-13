#!/usr/bin/perl -w
# Asm::X86 - a test for mixed syntax instructions.
#
#	Copyright (C) 2008-2025 Bogdan 'bogdro' Drozdowski,
#	  bogdro (at) users . sourceforge . net
#	  bogdro /at\ cpan . org
#
# This file is part of Project Asmosis, a set of tools related to assembly
#  language programming.
# Project Asmosis homepage: https://asmosis.sourceforge.io/
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#

use strict;
use warnings;

use Test::More;
use Asm::X86 qw(@instr is_instr);

my @valid_instr = ('MOV', 'ADD', 'MOVW', 'ADDL', 'Pxor', 'cmpxchg8b',
	'fldln2', 'cmpeqps', 'jge', 'prefetcht2', 'setc', 'ud2', 'xorps',
	'fistp', 'fistps', 'fstp', 'fstpl', 'Por', 'cmpunordpd', 'rep',
	'prefetchnta', 'setna', 'vmwrite', 'xorpd'
);

my @invalid_instr = ('aMOV', 'MOVa', 'ADDt', 'bADD', 'Pxorl', 'lPxor',
	'fcmovnes', 'fcmovneq', 'kfcmovne', 'bcmpunordps', 'cmpunordpsb',
	'jnbz', 'jnzb', 'bjnz', 'cprefetchnta', 'prefetchntac', 'setnab',
	'setnba', 'bsetna', 'axvmwrite', 'vmwriteax', 'pxorpd', 'xorpdp',
	'fcmovnel'
);

# Test::More:
plan tests => 1 + @valid_instr + @invalid_instr;

cmp_ok ( $#instr, '>', 0, 'Non-empty instruction list' );

foreach (@valid_instr) {

	is ( is_instr ($_), 1, "'$_' is a valid instruction" );
}

foreach (@invalid_instr) {

	is ( is_instr ($_), 0, "'$_' is not a valid instruction" );
}
