#!/usr/bin/perl -w -I./t
#
# rt 79190
#
# If you use a connection string like 'dbi:ODBC:DSN=xxx' DBD::ODBC
# should append the username and password to it from the other args to
# connect as UID=xxx;PWD=yyy
#
use Test::More;
use strict;

use DBI;
use_ok('ODBCTEST');
eval "require Test::NoWarnings";
my $has_test_nowarnings = ($@ ? undef : 1);

my $dbh;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
       plan skip_all => "DBI_DSN is undefined";
   }
   if (!defined $ENV{DBI_USER}) {
       plan skip_all => "DBI_USER is undefined";
   }
   if (!defined $ENV{DBI_PASS}) {
       plan skip_all => "DBI_PASS is undefined";
   }
}

END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
    done_testing();
}

my $dsn = $ENV{DBI_DSN};
if ($dsn !~ /dbi:ODBC:DSN=/i && $dsn !~ /dbi:ODBC:DRIVER=/i) {
    $dsn =~ s/dbi:ODBC:(.*)/dbi:ODBC:DSN=$1/;
}

$dbh = DBI->connect($dsn, $ENV{DBI_USER}, $ENV{DBI_PASS});
ok($dbh, "User/pass appended to DSN");


