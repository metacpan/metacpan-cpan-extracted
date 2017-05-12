#!/usr/bin/perl -w -I./t
#
# rt 78838
#
# DBD::ODBC was stringifying input bound parameters.
# This script creates an object with an overriden stringifcation method
# and tests it is stringified when bound.
#
use strict;
use warnings;
use Test::More;
use DBI;

use_ok('ODBCTEST');
eval "require Test::NoWarnings";
my $has_test_nowarnings = ($@ ? undef : 1);

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

my $dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
$dbh->{RaiseError} = 0;

my $dbms_name = $dbh->get_info(17);
ok($dbms_name, "got DBMS name: $dbms_name"); # 2

# this needs to be MS SQL Server
if ($dbms_name !~ /Microsoft SQL Server/) {
    note('Not Microsoft SQL Server');
    exit 0;
}

my $obj = new Object();

my $sth = $dbh->prepare(q/select ? AS result/);
ok($sth, "statement prepared");

$sth->bind_param(1, $obj);

SKIP: {
    skip "Failed to prepare statement", 4 if !$sth;

    $sth->execute();
    my $fetched = $sth->fetchrow_arrayref->[0];
    is($fetched, 'Object', "bound parameter correctly stringified"); # 1

    bless $obj, 'Subject';
    $sth->execute();
    $fetched = $sth->fetchrow_arrayref->[0];
    is($fetched, 'Object', "bound parameter copied and not a reference"); # 2

    $sth->bind_param(1, 'fred');
    $sth->execute();
    $fetched = $sth->fetchrow_arrayref->[0];
    is($fetched, 'fred', "rebound parameter correctly retrieved"); # 3

    eval {
        $sth->bind_param(1, $obj);
    };
    ok($@, "cannot bind a plain reference"); # 4

    $sth = undef;
}
$dbh->disconnect;

package Object;
use overload '""' => 'to_s';
sub new() { bless { }, shift };
sub to_s() { my $self = shift; ref($self); }
