#!/usr/bin/perl -w
# Asm::X86 - a test for AT&T-syntax instructions.
#
#	Copyright (C) 2008-2024 Bogdan 'bogdro' Drozdowski,
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
use Asm::X86 qw(@instr_att is_instr_att is_instr);

my @valid_att_instr = ('MOVW', 'ADDL', 'Pxor', 'fcmovne',
	'cmpunordps', 'jnz', 'prefetchnta', 'setna', 'vmwrite', 'xorpd',
	'fistps', 'fstpl', 'movzbw', 'movzbl', 'movzwl', 'movzbq',
	'movzwq', 'movsbw', 'movsbl', 'movswl', 'movsbq', 'movswq'
);

my @invalid_att_instr = ('MOV', 'ADD', 'aMOV', 'MOVa', 'ADDt', 'bADD',
	'Pxorl', 'lPxor', 'fcmovnek', 'kfcmovne', 'bcmpunordps',
	'cmpunordpsb', 'jnbz', 'jnzb', 'bjnz', 'cprefetchnta',
	'prefetchntac', 'setnab', 'setnba', 'bsetna', 'axvmwrite',
	'vmwriteax', 'pxorpd', 'xorpdp', 'fistp', 'fstp', '(%eax)'
);

# Test::More:
plan tests => 1 + @valid_att_instr * 2 + @invalid_att_instr;

cmp_ok ( $#instr_att, '>', 0, 'Non-empty instruction list' );

foreach (@valid_att_instr) {

	is ( is_instr_att ($_), 1, "'$_' is a valid AT&T-syntax instruction" );
	is ( is_instr ($_), 1, "'$_' is a valid instruction" );
}

foreach (@invalid_att_instr) {

	is ( is_instr_att ($_), 0, "'$_' is not a valid AT&T-syntax instruction" );
}
