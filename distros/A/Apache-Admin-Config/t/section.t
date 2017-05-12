use strict;
use Test;
plan test => 7;

use Apache::Admin::Config;
ok(1);

my $apache = new Apache::Admin::Config ('t/httpd.conf-dist');
ok(defined $apache);

my @seclist = $apache->section;
ok(@seclist, 6);

my @secvals = $apache->section('directory');
ok(@secvals, 4);

@secvals = $apache->section('DirectorY');
ok(@secvals, 4);

my $obj = $secvals[0];
ok(defined $obj);

my $root = $apache->section(directory=>'/');
ok(defined $root);
