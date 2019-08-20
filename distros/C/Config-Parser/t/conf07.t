# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec2;

plan(tests => 1);

my $c = new ConfigSpec2;
ok($c->canonical,
   q{core.base="test" load.test.param.mode="0644" load.test.param.owner="nobody"});

__DATA__
[core]
    base = test
[load test param]
    mode = 0644
    owner = nobody
