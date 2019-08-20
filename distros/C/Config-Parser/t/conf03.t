# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec;

plan(tests => 1);

my $c = new ConfigSpec(expect => ['invalid value for size']);
ok($c->errors() == 1);

__DATA__
[core]
        size = 11
[load]
	file = /etc/passwd
