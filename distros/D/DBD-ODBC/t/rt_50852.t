#!/usr/bin/perl -w -I./t
use Test::More;
use strict;

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 5;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

use DBI qw(:sql_types);
use_ok('ODBCTEST');             # 1

my $dbh;

BEGIN {
    plan skip_all => "DBI_DSN is undefined"
        if (!defined $ENV{DBI_DSN});
}
END {
    if ($dbh) {
        eval {
            local $dbh->{PrintWarn} = 0;
            local $dbh->{PrintError} = 0;
            $dbh->do(q/drop table PERL_DBD_RT_50852/);
        };
        $dbh->disconnect;
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings); # 6
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}

my $sth;
$dbh->{RaiseError} = 0;
#
# The odbc_force_bind_type should cover up the fact that most MS SQL Server
# ODBC drivers cannot successfully describe the parameter in the following
# SQL.
#
$dbh->{odbc_force_bind_type} = SQL_VARCHAR;
my $dbname = $dbh->get_info(17); # DBI::SQL_DBMS_NAME
SKIP: {
   skip "Microsoft SQL Server test not supported using $dbname", 4
       unless ($dbname =~ /Microsoft SQL Server/i);

   eval {
       local $dbh->{PrintWarn} = 0;
       local $dbh->{PrintError} = 0;
       $dbh->do(q/drop table PERL_DBD_RT_50852/);
   };
   pass('dropped test table');  # 2

   eval {
       $dbh->do(q{CREATE TABLE PERL_DBD_RT_50852 (name nvarchar(255))});
       $dbh->do(q{insert into PERL_DBD_RT_50852 values('frederick')});
   };
   my $ev = $@;
   ok(!$ev, 'set up test table'); # 3

 SKIP: {
       skip 'Failed to setup test table', 2 if $ev;

       $sth = $dbh->prepare(
           q/select name from PERL_DBD_RT_50852 where charindex(?, name) = 1/);
       ok($sth, 'prepared sql'); #4
     SKIP: {
           skip 'Failed to prepare SQL', 1 unless $sth;

           ok($sth->execute('fred'), 'execute sql') &&
               $sth->finish; #5
       };
   };
};

exit 0;
