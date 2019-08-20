# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec2;

plan(tests => 1);

my $c = new ConfigSpec2(expect => ['mandatory section [load * param] not present']);
ok($c->errors, 1);

__DATA__
[core]
    base = test
