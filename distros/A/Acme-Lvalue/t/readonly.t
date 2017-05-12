#!perl
use warnings FATAL => 'all';
use strict;

use Config;

use Test::More
	$Config{usethreads}
		? (skip_all => q{read-only constants aren't read-only under threads})
		: (tests => 3);

use Acme::Lvalue qw(:builtins), [succ => sub { $_[0] + 1 }, sub { $_[0] - 1 }];

ok !eval { succ(0) = 1; 1 };
ok !eval { sqrt(succ(0)) = 2; 1 };
ok !eval { succ(sqrt(0)) = 3; 1 };
