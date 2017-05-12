#!/usr/bin/perl -w -I./t
use Test::More;
use strict;

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 8;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

use DBI qw(:sql_types);
use_ok('ODBCTEST');
#use_ok('Data::Dumper');

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
            $dbh->do(q/drop table PERL_DBD_rt_43384/);
        };
        $dbh->disconnect;
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
my $sth;

my $dbname = $dbh->get_info(17); # DBI::SQL_DBMS_NAME
SKIP: {
   skip "Microsoft Access tests not supported using $dbname", 7
       unless ($dbname =~ /Access/i);

   eval {
       local $dbh->{PrintWarn} = 0;
       local $dbh->{PrintError} = 0;
       $dbh->do(q/drop table PERL_DBD_rt_43384/);
   };
   pass('dropped test table');
   eval {$dbh->do(q/create table PERL_DBD_rt_43384 (unicode_varchar text(200), unicode_text memo)/);};
   my $ev = $@;
   ok(!$ev, 'created test table PERL_DBD_rt_43384');
   SKIP: {
       skip 'failed to create test table', 2 if $ev;

       my $sth = $dbh->prepare(q/insert into PERL_DBD_rt_43384 values(?,?)/);
       ok($sth, 'insert prepared');
     SKIP: {
           skip 'failed to prepare', 1 if !$sth;
           my $data = 'a' x 190;
           eval {$sth->execute($data, $data);};
           $ev = $@;
           ok(!$ev, 'inserted into test table');

           ok ($sth->bind_param(1, $data, {TYPE => SQL_VARCHAR}));
           ok ($sth->bind_param(2, $data, {TYPE => SQL_LONGVARCHAR}));
           eval {$sth->execute;};
           $ev = $@;
           ok(!$ev, "inserted into test table with VARCHAR and LONGVARCHAR");
       };
   };
};

exit 0;
