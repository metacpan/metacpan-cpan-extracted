#!/usr/bin/perl -w
# Asm::X86 - a test for intel-syntax instructions.
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
use Asm::X86 qw(@instr_intel is_instr_intel is_instr);

my @valid_intel_instr = ('MOV', 'ADD', 'Pxor', 'fcmovne', 'cmpunordps',
	'jnz', 'prefetchnta', 'setna', 'vmwrite', 'xorpd'
);

my @invalid_intel_instr = ('aMOV', 'MOVa', 'ADDt', 'bADD', 'Pxorl', 'lPxor',
	'fcmovnek', 'kfcmovne', 'bcmpunordps', 'cmpunordpsb', 'jnbz', 'jnzb',
	'bjnz', 'cprefetchnta', 'prefetchntac', 'setnab', 'setnba', 'bsetna',
	'axvmwrite', 'vmwriteax', 'pxorpd', 'xorpdp', '[eax]'
);

# Test::More:
plan tests => 1 + @valid_intel_instr * 2 + @invalid_intel_instr;

cmp_ok ( $#instr_intel, '>', 0, 'Non-empty instruction list' );

foreach (@valid_intel_instr) {

	is ( is_instr_intel ($_), 1, "'$_' is a valid Intel-syntax instruction" );
	is ( is_instr ($_), 1, "'$_' is a valid instruction" );
}

foreach (@invalid_intel_instr) {

	is ( is_instr_intel ($_), 0, "'$_' is not a valid Intel-syntax instruction" );
}
