#!perl -w

use strict;
use Test;
plan tests => 1;

use Data::Dump::Ruby;

print "# ";
dd_ruby getlogin;
ddx_ruby localtime;
#ddx_ruby \%Exporter::;

ok(1);
