#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 17;
BEGIN { use_ok('App::Scheme79asm') };

sub run_test {
	my ($args, $input, $expected_verilog, $expected_binary16, $name) = @_;
	my ($actual, $fh, $asm);
	open $fh, '>', \$actual;
	$asm = App::Scheme79asm->new(%$args);
	$asm->parse_and_print_binary16($input, $fh);
	close $fh;
	$actual = uc join ' ', unpack '(H2)*', $actual;
	is $actual, $expected_binary16, "print_binary16 $name";

	open $fh, '>', \$actual;
	$asm = App::Scheme79asm->new(%$args);
	$asm->parse_and_print_verilog($input, $fh);
	close $fh;
	is $actual, $expected_verilog, "print_verilog $name";
}

my $expbin;

$expbin = '00 07 00 00 00 00 01 00 01 00 00 07 01 03 00 00';

run_test {}, '(number 3)', <<'EOF', $expbin, '3';
mem[0] <= 0;                // (cdr part of NIL)
mem[1] <= 0;                // (car part of NIL)
mem[2] <= 11'b00100000000;  // (cdr part of T)
mem[3] <= 11'b00100000000;  // (car part of T)
mem[4] <= 11'd7;            // (free storage pointer)
mem[5] <= 11'b00100000011;  // NUMBER 3
mem[6] <= 0;                // (result of computation)
EOF

$expbin = '00 08 00 00 00 00 00 20 00 20 00 08 00 E7 00 00 00 25';

run_test {addr_bits => 5}, '(quoted (symbol 5))', <<'EOF', $expbin, '(QUOTE 5)';
mem[0] <= 0;             // (cdr part of NIL)
mem[1] <= 0;             // (car part of NIL)
mem[2] <= 8'b00100000;   // (cdr part of T)
mem[3] <= 8'b00100000;   // (car part of T)
mem[4] <= 8'd8;          // (free storage pointer)
mem[5] <= 8'b11100111;   // QUOTED 7
mem[6] <= 0;             // (result of computation)
mem[7] <= 8'b00100101;   // SYMBOL 5
EOF

$expbin = '00 0C 00 00 00 00 20 00 20 00 00 0C C0 07 00 00 00 09 20 05 E0 00 80 0B 5F FE';
run_test {addr_bits => 13}, '(call (more (funcall 0) (proc (var -2))) (number 5))', <<'EOF', $expbin, '((LAMBDA ID (X) X) 5)';
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

my %test = (
	addr_bits => 13,
	type_bits => 3,
	memory => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
	freeptr => 9
);

$expbin = '00 0E 00 00 00 01 00 02 00 03 00 0E C0 0A 00 06 00 07 00 08 00 09 00 0C 20 0A 60 00 20 0B';

run_test \%test, '(call (more (cons 0) (number 11)) (number 10))', <<'EOF', $expbin, '(CONS 10 11)';
mem[ 0] <= 0;                     // (cdr part of NIL)
mem[ 1] <= 16'b0000000000000001;  // (car part of NIL)
mem[ 2] <= 16'b0000000000000010;  // (cdr part of T)
mem[ 3] <= 16'b0000000000000011;  // (car part of T)
mem[ 4] <= 16'd14;                // (free storage pointer)
mem[ 5] <= 16'b1100000000001010;  // CALL 10
mem[ 6] <= 16'b0000000000000110;  // (result of computation)
mem[ 7] <= 16'b0000000000000111;
mem[ 8] <= 16'b0000000000001000;
mem[ 9] <= 16'b0000000000001001;
mem[10] <= 16'b0000000000001100;  // MORE 12
mem[11] <= 16'b0010000000001010;  // NUMBER 10
mem[12] <= 16'b0110000000000000;  // CONS 0
mem[13] <= 16'b0010000000001011;  // NUMBER 11
EOF

sub expect_error_like (&$) {
	my ($block, $error_re) = @_;
	my $name = "test error like /$error_re/";
	my $result = eval { $block->(); 1 };
	if ($result) {
		note 'Block did not throw an exception, failing test';
		fail $name;
	} else {
		like $@, qr/$error_re/, $name;
	}
}

expect_error_like { run_test {}, 'symbol' } 'Toplevel is not a list';
expect_error_like { run_test {}, '((type is a list) 5)'} 'Type of toplevel is not atom';
expect_error_like { run_test {}, '(badtype 5)'} 'No such type';
expect_error_like { run_test {}, '(number)'} 'Computed addr is not a number';
expect_error_like { run_test {}, '(70000 5)'} 'Type too large';
expect_error_like { run_test {}, '(5 700000)'} 'Addr too large';
expect_error_like { run_test {addr_bits => 20}, '(list 0)' } 'addr_bits ';
expect_error_like { App::Scheme79asm->new->process([5, {}]) } 'Addr of toplevel is not atom';
