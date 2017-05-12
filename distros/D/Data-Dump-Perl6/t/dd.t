#!perl -w

use strict;
use Test;
plan tests => 1;

use Data::Dump::Perl6;

print "# ";
dd_perl6 getlogin;
ddx_perl6 localtime;
ddx_perl6 \%Exporter::;

ok(1);
