#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('App::Scheme79asm') };

sub run_test {
	my ($args, $input, $expected, $name) = @_;
	my $actual = '';
	open my $fh, '>', \$actual;
	my $asm = App::Scheme79asm->new(%$args);
	$asm->parse_and_print($input, $fh);
	close $fh;
	is $actual, $expected, $name
}

run_test {addr_bits => 5}, '(quoted . (symbol . 5))', <<'', '(QUOTE 5)';
mem[0] <= 0;
mem[1] <= 0;
mem[2] <= 8'b00100000;
mem[3] <= 8'b00100000;
mem[4] <= 8'd8;
mem[5] <= 8'b11100111;
mem[6] <= 0;
mem[7] <= 8'b00100101;
