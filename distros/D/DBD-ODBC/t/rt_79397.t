#!/usr/bin/perl -w -I./t
#
# rt 79397
#
# Code that came from perl monks in node http://perlmonks.org/?node_id=989136
# If you bind an output parameter as undef initially then change it
# the changed value may not get to the database.
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
}

END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
    done_testing();
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
$dbh->{RaiseError} = 0;

my $dbms_name = $dbh->get_info(17);
ok($dbms_name, "got DBMS name: $dbms_name"); # 2
my $dbms_version = $dbh->get_info(18);
ok($dbms_version, "got DBMS version: $dbms_version"); # 3
my $driver_name = $dbh->get_info(6);
ok($driver_name, "got DRIVER name: $driver_name"); # 4
my $driver_version = $dbh->get_info(7);
ok($driver_version, "got DRIVER version $driver_version"); # 5

# this needs to be MS SQL Server
if ($dbms_name !~ /Microsoft SQL Server/) {
    note('Not Microsoft SQL Server');
    exit 0;
}
my $sth = $dbh->prepare(q/SELECT :foo, :bar/);
ok($sth, "statement prepared");

SKIP: {
    skip "Failed to prepare statement", 6 if !$sth;

    my @cols = qw(foo bar);
    my %hsh;
    for (@cols) {               # 2
        ok($sth->bind_param_inout( "$_" => \$hsh{$_}, 0 ), "$_ bound");
    }

    $hsh{foo} = 'abc';
    $hsh{bar} = 123;
    my $r;
    ok($r = $sth->execute(), "execute first time"); # 3
    SKIP: {
        skip "Failed to execute", 4 if !$r;

        my @arr = $sth->fetchrow_array;
        is($arr[0], 'abc', "p1 ok"); # 4
        is($arr[1], '123', "p2 ok"); # 5

        $hsh{bar} = 456;
        $sth->execute();

        @arr = $sth->fetchrow_array;
        is($arr[0], 'abc', "p1 ok"); # 6
        is($arr[1], '456', "p2 ok"); # 7
    };
};


