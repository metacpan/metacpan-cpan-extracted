#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('App::Scheme79asm') };

sub run_test {
	my ($args, $input, $expected, $name) = @_;
	my $actual = '';
	open my $fh, '>', \$actual;
	my $asm = App::Scheme79asm->new(%$args);
	$asm->parse_and_print_verilog($input, $fh);
	close $fh;
	is $actual, $expected, $name
}

run_test {addr_bits => 5}, '(quoted (symbol 5))', <<'EOF', '(QUOTE 5)';
mem[0] <= 0;             // (cdr part of NIL)
mem[1] <= 0;             // (car part of NIL)
mem[2] <= 8'b00100000;   // (cdr part of T)
mem[3] <= 8'b00100000;   // (car part of T)
mem[4] <= 8'd8;          // (free storage pointer)
mem[5] <= 8'b11100111;   // QUOTED 7
mem[6] <= 0;             // (result of computation)
mem[7] <= 8'b00100101;   // SYMBOL 5
EOF

run_test {addr_bits => 13}, '(call (more (funcall 0) (proc (var -2))) (number 5))', <<'EOF', '((LAMBDA ID (X) X) 5)';
mem[ 0] <= 0;                     // (cdr part of NIL)
mem[ 1] <= 0;                     // (car part of NIL)
mem[ 2] <= 16'b0010000000000000;  // (cdr part of T)
mem[ 3] <= 16'b0010000000000000;  // (car part of T)
mem[ 4] <= 16'd12;                // (free storage pointer)
mem[ 5] <= 16'b1100000000000111;  // CALL 7
mem[ 6] <= 0;                     // (result of computation)
mem[ 7] <= 16'b0000000000001001;  // MORE 9
mem[ 8] <= 16'b0010000000000101;  // NUMBER 5
mem[ 9] <= 16'b1110000000000000;  // FUNCALL 0
mem[10] <= 16'b1000000000001011;  // PROC 11
mem[11] <= 16'b0101111111111110;  // VAR -2
EOF
