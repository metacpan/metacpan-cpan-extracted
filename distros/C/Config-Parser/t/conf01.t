# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec;

plan(tests => 1);

my $c = new ConfigSpec(expect => ['keyword "output" is unknown']);
ok($c->errors() == 1);

__DATA__
[core]
	number = 5
	output = file;
[load]
	file = /etc/passwd
