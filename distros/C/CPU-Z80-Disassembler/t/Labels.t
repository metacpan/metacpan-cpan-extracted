#!perl

use strict;
use warnings;

use Test::More;

use_ok 'CPU::Z80::Disassembler::Labels';

sub by_addr { $a->addr <=> $b->addr }

isa_ok my $labels = CPU::Z80::Disassembler::Labels->new,
		'CPU::Z80::Disassembler::Labels';

# index is empty
is $labels->search_name('hello'), undef;
is $labels->search_addr(34), undef;
is_deeply [sort by_addr $labels->search_all], [];
is $labels->max_length, 0;
is $labels->next_label, undef;
is $labels->next_label(0xFFFF), undef;

# add one label
isa_ok my $hello = $labels->add(34, 'hello', 23),
		'CPU::Z80::Disassembler::Label';
is $hello->name, 		'hello';
is $hello->addr,		34;
is_deeply [$hello->refer_from], [23];
is $labels->max_length, 5;
is $labels->next_label, $hello;
is $labels->next_label(33), $hello;
is $labels->next_label(34), $hello;
is $labels->next_label(35), undef;

is $labels->search_name('hello'), $hello;
is $labels->search_addr(34), $hello;
is_deeply [sort by_addr $labels->search_all], [sort by_addr ($hello)];

# add same label, other reference
isa_ok my $hello2 = $labels->add(34, 'hello', 27),
		'CPU::Z80::Disassembler::Label';
is $hello2, $hello;
is $hello->name, 		'hello';
is $hello->addr,		34;
is_deeply [$hello->refer_from], [23, 27];
is $labels->max_length, 5;
is $labels->next_label, $hello;
is $labels->next_label(33), $hello;
is $labels->next_label(34), $hello;
is $labels->next_label(35), undef;

is $labels->search_name('hello'), $hello;
is $labels->search_addr(34), $hello;
is_deeply [sort by_addr $labels->search_all], [sort by_addr ($hello)];

# add label with same name, other address
eval { $labels->add(33, 'hello') };
like $@, qr/^Label 'hello' with addresses 0x0022 and 0x0021 at t.*Labels\.t line \d+/;

# add another on same address, no reference address
eval { $labels->add(34, 'world') };
like $@, qr/^Labels 'hello' and 'world' at the same address 0x0022 at t.*Labels\.t line \d+/;

is $labels->search_name('hello'), $hello;
is $labels->search_addr(34), $hello;
is_deeply [sort by_addr $labels->search_all], [sort by_addr ($hello)];
is $labels->max_length, 5;

# add another on different address
isa_ok my $earth = $labels->add(35, 'earth', 21),
		'CPU::Z80::Disassembler::Label';
is $earth->name, 		'earth';
is $earth->addr,		35;
is_deeply [$earth->refer_from], [21];
is $labels->max_length, 5;
is $labels->next_label, $hello;
is $labels->next_label(33), $hello;
is $labels->next_label(34), $hello;
is $labels->next_label(35), $earth;
is $labels->next_label(36), undef;

is $labels->search_name('earth'), $earth;
is $labels->search_addr(34), $hello;
is $labels->search_addr(35), $earth;
is_deeply [sort by_addr $labels->search_all], 
		  [sort by_addr ($hello, $earth)];

# create a temporary label
isa_ok my $t1 = $labels->add(0x0036, undef), 'CPU::Z80::Disassembler::Label';

is $labels->search_name("L_0036"), $t1;
is $labels->search_addr(34), $hello;
is $labels->search_addr(35), $earth;
is $labels->search_addr(0x36), $t1;
is_deeply [sort by_addr $labels->search_all], 
		  [sort by_addr ($hello, $earth, $t1)];
is $labels->max_length, 6;
is $labels->next_label, $hello;
is $labels->next_label(33), $hello;
is $labels->next_label(34), $hello;
is $labels->next_label(35), $earth;
is $labels->next_label(36), $t1;
is $labels->next_label(0x36), $t1;
is $labels->next_label(0x37), undef;

isa_ok my $t2 = $labels->add(0x0036, "T2345678"), 'CPU::Z80::Disassembler::Label';
is $t1, $t2;

is $labels->search_name("L_0036"), undef;
is $labels->search_name("T2345678"), $t1;
is $labels->search_addr(34), $hello;
is $labels->search_addr(35), $earth;
is $labels->search_addr(0x36), $t1;
is_deeply [sort by_addr $labels->search_all], 
		  [sort by_addr ($hello, $earth, $t1)];
is $labels->max_length, 8;
is $labels->next_label, $hello;
is $labels->next_label(33), $hello;
is $labels->next_label(34), $hello;
is $labels->next_label(35), $earth;
is $labels->next_label(36), $t1;
is $labels->next_label(0x36), $t1;
is $labels->next_label(0x37), undef;



done_testing;
