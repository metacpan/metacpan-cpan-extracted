# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use ConfigSpec3;

plan(tests => 1);

my $c = new ConfigSpec3;
ok($c->canonical,q{core.root="/var" dir.diag="/var/log" dir.store="/var/spool" dir.temp="/var/tmp"});

__DATA__
[core]
	root = /var
[dir]
	temp = tmp
	store = spool
	diag = log
