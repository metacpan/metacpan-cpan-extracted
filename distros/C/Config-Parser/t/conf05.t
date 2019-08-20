# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec;

plan(tests => 1);

my $c = new ConfigSpec;
ok($c->canonical, q{core.base="null" load.file="/test"});

__DATA__
[load]
	file = /test
