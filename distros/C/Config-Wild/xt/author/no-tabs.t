use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Config/Wild.pm',
    't/00-compile.t',
    't/00-report-prereqs.t',
    't/Config-Wild.t',
    't/data/cfgs/blanks.cnf',
    't/data/cfgs/boolean.cnf',
    't/data/cfgs/include0-rel.cnf',
    't/data/cfgs/include0.cnf',
    't/data/cfgs/include1-rel.cnf',
    't/data/cfgs/include1.cnf',
    't/data/cfgs/include2.cnf',
    't/data/cfgs/test.cnf',
    't/data/cfgs/vars.cnf',
    't/data/cfgs/wildcard.cnf',
    't/data/include/decoy/l1/secondary.cnf',
    't/data/include/decoy/secondary.cnf',
    't/data/include/dir.cnf',
    't/data/include/l1/primary.cnf',
    't/data/include/l1/secondary.cnf',
    't/data/include/other0.cnf',
    't/data/include/other1.cnf',
    't/data/include/parent.cnf',
    't/data/include/secondary.cnf',
    't/data/method/a.cnf',
    't/data/method/b/b.cnf',
    't/data/method/b/c/c.cnf',
    't/data/method/b/c/conf',
    't/data/method/b/conf',
    't/data/method/conf',
    't/include.t',
    't/log.t',
    't/method.t'
);

notabs_ok($_) foreach @files;
done_testing;
