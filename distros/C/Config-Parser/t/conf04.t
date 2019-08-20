# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec;

plan(tests => 1);

my $c = new ConfigSpec(expect => ['not an absolute pathname',
		       'mandatory variable "load.file" not set']);
ok($c->errors() == 2);

__DATA__
[core]
        
[load]
	file = test
