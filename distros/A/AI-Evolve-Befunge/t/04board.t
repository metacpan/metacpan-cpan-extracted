#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Output;

use AI::Evolve::Befunge::Util qw(v);
use aliased 'AI::Evolve::Befunge::Board' => 'Board';

my $num_tests;
BEGIN { $num_tests = 0; };

# constructor
my $size = v(5, 5);
my $board = Board->new(Size => $size);
is(ref($board), 'AI::Evolve::Befunge::Board', "new returned right object type");
is($board->size, "(5,5)", "size argument passed through");
is($board->dimensions, 2, "dimensions value derived from Size vector");
$board = Board->new(Size => 5, Dimensions => 2);
is(ref($board), 'AI::Evolve::Befunge::Board', "new returned right object type");
is($board->size, "(5,5)", "size argument passed through");
is($board->dimensions, 2, "dimensions value derived from Size vector");
dies_ok( sub { Board->new(); }, "Board->new dies without Size argument");
like($@, qr/Usage: /, "died with usage message");
dies_ok( sub { Board->new(Size => 2); }, "Board->new dies without Dimensions argument");
like($@, qr/No Dimensions argument/, "died with proper message");
dies_ok( sub { Board->new(Size => $size, Dimensions => 3); }, "Board->new dies with dimensional mismatch");
like($@, qr/doesn't match/, "died with proper message");
lives_ok( sub { Board->new(Size => $size, Dimensions => 2); }, "Board->new lives with dimensional match");
$size = v(0, 2);
dies_ok( sub { Board->new(Size => $size); }, "Board->new dies with zero-length side");
like($@, qr/must be at least 1/, "died with proper message");
$size = v(2, 2, 2);
dies_ok( sub { Board->new(Size => $size); }, "Board->new dies with dimensional overflow");
like($@, qr/isn't smart enough/, "died with proper message");
$size = v(2, 2, 1);
lives_ok( sub { Board->new(Size => $size); }, "Board->new makes an exception for d(2+) == 1");
BEGIN { $num_tests += 18 };

# set_value
# fetch_value
is($board->fetch_value(v(0,0)), 0, "default value is 0");
$board->set_value(v(2,2),2);
is($board->fetch_value(v(2,2)), 2, "fetch_value returns value set by set_value");
is($board->fetch_value(v(4,4)), 0, "default value is 0");
dies_ok( sub { $board->fetch_value(0)  }, 'fetch_value with no vector');
dies_ok( sub { $board->set_value(0, 1) }, 'set_value with no vector');
dies_ok( sub { $board->fetch_value(v(-1,0)) }, 'fetch_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->fetch_value(v(5,0))  }, 'fetch_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->fetch_value(v(0,-1)) }, 'fetch_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->fetch_value(v(0,5))  }, 'fetch_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->set_value(v(-1,0), 1)  }, 'set_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->set_value(v(5,0),  1)  }, 'set_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->set_value(v(0,-1), 1)  }, 'set_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->set_value(v(0,5),  1)  }, 'set_value out of range');
like($@, qr/out of range/, "died with proper message");
dies_ok( sub { $board->set_value(v(0,0), -1)  }, 'set_value out of range');
like($@, qr/data '-1' out of range/, "died with proper message");
dies_ok( sub { $board->set_value(v(0,0), 40)  }, 'set_value out of range');
like($@, qr/data '40' out of range/, "died with proper message");
dies_ok( sub { $board->set_value(v(0,0), undef)  }, 'set_value with undef value');
like($@, qr/undef value/, "died with proper message");
is($board->fetch_value(v(0,0)), 0, "above deaths didn't affect original value");
BEGIN { $num_tests += 28 };

# copy
my $board2 = $board->copy();
is($board->fetch_value(v(2,2)), 2, "old copy has same values");
is($board->fetch_value(v(4,4)), 0, "old copy has same values");
is($board2->fetch_value(v(2,2)), 2, "new copy has same values");
is($board2->fetch_value(v(4,4)), 0, "new copy has same values");
$board2->set_value(v(2,2),0);
$board2->set_value(v(4,4),2);
is($board->fetch_value(v(2,2)), 2, "old copy has old values");
is($board->fetch_value(v(4,4)), 0, "old copy has old values");
is($board2->fetch_value(v(2,2)), 0, "new copy has new values");
is($board2->fetch_value(v(4,4)), 2, "new copy has new values");
$board->set_value(v(2,2),1);
$board->set_value(v(4,4),1);
is($board->fetch_value(v(2,2)), 1, "old copy has new values");
is($board->fetch_value(v(4,4)), 1, "old copy has new values");
is($board2->fetch_value(v(2,2)), 0, "new copy still has its own values");
is($board2->fetch_value(v(4,4)), 2, "new copy still has its own values");
BEGIN { $num_tests += 12 };

# clear
is($board->fetch_value(v(0,0)), 0, "board still has old values");
$board->clear();
is($board->fetch_value(v(2,2)), 0, "board has been cleared");
is($board->fetch_value(v(4,4)), 0, "board has been cleared");
is($board->fetch_value(v(0,0)), 0, "board has been cleared");
BEGIN { $num_tests += 4 };

# as_string
is($board2->as_string(), <<EOF, "as_string");
.....
.....
.....
.....
....o
EOF
BEGIN { $num_tests += 1 };

# as_binary_string
is($board2->as_binary_string(), ("\x00"x5 . "\n")x4 . "\x00\x00\x00\x00\x02\n", "as_binary_string");
BEGIN { $num_tests += 1 };

# output
stdout_is(sub { $board2->output() }, <<EOF, "output");
   01234
 0 .....
 1 .....
 2 .....
 3 .....
 4 ....o
EOF
BEGIN { $num_tests += 1 };


BEGIN { plan tests => $num_tests };
