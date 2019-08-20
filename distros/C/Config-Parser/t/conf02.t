# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec;

plan(tests => 1);

my $c = new ConfigSpec(expect => ['mandatory variable "load.file" not set']);
ok($c->errors() == 1);
__DATA__
[core]
	number = 5
