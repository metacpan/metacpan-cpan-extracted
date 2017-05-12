use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;
use File::Temp qw(tempdir);
use File::Basename qw(dirname);
use Apache::SWIT::Test::Utils;

my $td = tempdir("/tmp/pltemp_910_XXXXXX", CLEANUP => 1);
chdir(dirname($0) . "/../");
my $res = `perl Makefile.PL 2>&1 && make install SITEPREFIX=$td/inst 2>&1`;
is($?, 0) or diag($res);
isnt(-d "$td/inst/share/perl", undef) or diag($res);
isnt(-f "$td/inst/bin/swit_init", undef) or ASTU_Wait("$td");

