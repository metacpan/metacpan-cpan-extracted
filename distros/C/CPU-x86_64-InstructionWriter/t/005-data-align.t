#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer iterate_mem_addr_combos asm_ok @r64 @r32 @r16 @r8 @r8h @immed32 @immed16 @immed8 );
use Test::More;

subtest data => \&test_data;
sub test_data {
	my $w= new_writer;
	$w->data("\x01\x02\x03");
	is( $w->bytes, "\x01\x02\x03", 'string of bytes' );
	$w->data_i8(4);
	is( $w->bytes, "\x01\x02\x03\x04", 'i8' );
	$w->data_i16(4);
	is( $w->bytes, "\x01\x02\x03\x04\x04\x00", 'i16' );
	$w->data_i32(4);
	is( $w->bytes, "\x01\x02\x03\x04\x04\x00\x04\x00\x00\x00", 'i32' );
	
	$w= new_writer;
	$w->data_i8(ord('A'));
	$w->align2('X');
	is( $w->bytes, "AX", 'align2' );
	$w->align4('X');
	is( $w->bytes, "AXXX", 'align4' );
	$w->align8;
	is( $w->bytes, "AXXX\x90\x90\x90\x90", 'align8' );
	$w->align(16, "\x00");
	is( $w->bytes, "AXXX\x90\x90\x90\x90" . ("\x00" x 8), 'align(16)' );
}

done_testing;
