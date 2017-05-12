#!perl -w

use Test::More;
use strict;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 6;

$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

require DBI;
require_ok('DBI');

import DBI;
pass("import DBI");

my $switch = DBI->internal;
is(ref $switch, 'DBI::dr', "DBI->internal is DBI::dr");

my $drh;
eval {
    $drh = DBI->install_driver('ODBC');
};
my $ev = $@;
diag($ev) if ($ev);
ok(!$ev, 'install ODBC');

SKIP: {
    skip "driver could not be loaded", 2 if $ev;

    is(ref $drh, 'DBI::dr', "Install ODBC driver OK");

    ok($drh->{Version}, "Version is not empty");
}

END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

exit 0;
