#!/usr/bin/perl -w -I./t
#
# rt 81911
#
# New odbc_rows method and change to silently truncating affected rows
# from execute. Can't think of a reasonable way of testing the latter as
# I cannot imagine anyone wants millions of rows inserting into their
# database during testing.
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
    if ($dbh) {
        local $dbh->{PrintWarn} = 0;
        local $dbh->{PrintError} = 0;
        $dbh->do(q/drop table PERL_DBD_RT_81911/);
    }
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

$dbh->do(q/create table PERL_DBD_RT_81911 (a int)/)
    or BAIL_OUT("Failed to create test table " . $dbh->errstr);

# insert one row and check
my $s = $dbh->prepare(q/insert into PERL_DBD_RT_81911 values(?)/)
    or BAIL_OUT("Failed to prepare insert " . $dbh->errstr);

my $affected = $s->execute(1) or BAIL_OUT("Failed to execute insert " . $dbh->errstr);

is($affected, 1, "affected from execute insert");
is($s->odbc_rows, $affected, "execute and odbc_rows agree on insert");

# insert a second row and check
$affected = $s->execute(2) or BAIL_OUT("Failed to execute insert 2 " . $dbh->errstr);

is($affected, 1, "affected from execute insert");
is($s->odbc_rows, $affected, "execute and odbc_rows agree on insert 2 ");

# test update with no rows affected
$s = $dbh->prepare(q/update PERL_DBD_RT_81911 set a = 1 where a = ?/)
    or BAIL_OUT("Failed to prepare update " . $dbh->errstr);
$affected = $s->execute(3) or BAIL_OUT("Failed to execute update " . $dbh->errstr);

is($affected, '0E0', "affected from execute update none");
is($s->odbc_rows, $affected, "execute and odbc_rows agree on update none");

# test update with 1 row affected
$affected = $s->execute(1) or BAIL_OUT("Failed to execute update " . $dbh->errstr);

is($affected, 1, "affected from execute update 1");
is($s->odbc_rows, $affected, "execute and odbc_rows agree on update 1");

# test update with 2 rows affected
$s = $dbh->prepare(q/update PERL_DBD_RT_81911 set a = 1 where a > 0/)
    or BAIL_OUT("Failed to prepare update 2 " . $dbh->errstr);
$affected = $s->execute or BAIL_OUT("Failed to execute update 2" . $dbh->errstr);

is($affected, 2, "affected from execute update 2");
is($s->odbc_rows, $affected, "execute and odbc_rows agree on update 2");
