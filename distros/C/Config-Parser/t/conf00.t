# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec;

plan(tests => 1);

my $c = new ConfigSpec;
ok($c->canonical,
   q{core.base=4 core.number=[5,10] core.size="10 k" load.file="/etc/passwd" load.foobar="baz"});

__DATA__
[core]
	number = 5
	base = 4
	size = 10 k
	number = 10
[load]
	file = /etc/passwd
	foobar = baz
    
