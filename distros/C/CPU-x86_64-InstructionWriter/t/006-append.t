#! /usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestASM qw( new_writer asm_ok @r64 );
use Test::More;

my $inner= new_writer(debug=>1)->cmp('rax', [rip => \"test"])
	->jne('.done')
	->add('rax', 'rdx')
	->label('.done');
my $outer= new_writer(debug=>1)->cmp('rax', 0)->jne('.done')
	->append($inner, '.inner')
	->push('rax')->label('.done')
	->label("test")->data_i64(42);

my $asm= <<__;
	cmp rax, 0
	jne .done
	cmp rax, [rel test]
	jne .done2
	add rax, rdx
.done2:
	push rax
.done:
test:
	dq 42
__

asm_ok([$outer->bytes], [$asm], 'nested jump to .done');

done_testing;
