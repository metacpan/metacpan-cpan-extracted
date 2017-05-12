#!perl -w

use strict;
use Test;
plan tests => 1;

use Data::Dump::PHP;

print "# ";
dd_php getlogin;
ddx_php localtime;
#ddx_php \%Exporter::;

ok(1);
