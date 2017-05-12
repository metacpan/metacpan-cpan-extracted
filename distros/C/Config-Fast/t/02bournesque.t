#!/usr/bin/perl -I. -I.. -w

# 01bournesque - read the second config file, which is Bourne style

use strict;
use Test;

# use a BEGIN block so we print our plan before module is loaded
BEGIN { plan tests => 12 }

use FindBin;

my $conf = "$FindBin::Bin/config.cf2";

use Config::Fast;

my %cf = fastconfig($conf, '=');

ok($cf{one}, 1);
ok($cf{two}, 2);
ok($cf{three}, 3);
ok($cf{oracle_user}, 'oracle');
ok($cf{oracle_home}, '/oracle/orahome1');
ok($cf{oracle_data}, '/oracle/orahome1/oradata');
ok($cf{spacing}, '    pre-spaces');
ok($cf{trailing}, 'end-spaces     ');
ok($cf{reuse}, '    pre-spaces');
ok($cf{'if you say so'},    '   No! Now go away!   ');
ok($ENV{ORACLE_HOME}, $cf{oracle_home});

my @n = keys %cf;
my $n = @n;
ok($n, 14);

