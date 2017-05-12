#!/usr/bin/perl -I./t -w

use Test::More;
$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 4;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

# use_ok('DBI', qw(:sql_types));
# can't seem to get the imports right this way
use DBI qw(:sql_types);
use_ok('ODBCTEST');
#use_ok('Data::Dumper');

# to help ActiveState's build process along by behaving (somewhat) if a dsn is not provided
BEGIN {
    plan skip_all => "DBI_DSN is undefined"
        if (!defined $ENV{DBI_DSN});
}
END {
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

my $dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}

my $dbname = $dbh->get_info(17); # DBI::SQL_DBMS_NAME
SKIP:
{
   skip "Oracle tests not supported using " . $dbname, 3 unless ($dbname =~ /Oracle/i);


   $dbh->do("create or replace function PERL_DBD_TESTFUNC(a in integer, b in integer) return integer is c integer; begin if b is null then c := 0; else c := b; end if; return a * c + 1; end;");
   my $sth = $dbh->prepare("{ ? = call PERL_DBD_TESTFUNC(?, ?) }");
   my $value = undef;
   my $b = 30;
   $sth->bind_param_inout(1, \$value, 50, SQL_INTEGER);
   $sth->bind_param(2, 10, SQL_INTEGER);
   $sth->bind_param(3, 30, SQL_INTEGER);
   $sth->execute;
   is($value, 301);

   $b = undef;
   $sth->bind_param_inout(1, \$value, 50, SQL_INTEGER);
   $sth->bind_param(2, 20, SQL_INTEGER);
   $sth->bind_param(3, undef, SQL_INTEGER);
   $sth->execute;
   is($value,1);

   eval{$dbh->do("drop function PERL_DBD_TESTFUNC");};

   $dbh->do("create or replace procedure PERL_DBD_TESTPROC(a in integer,b out integer) is begin b := a + 1; end;");
   $sth = $dbh->prepare("{call PERL_DBD_TESTPROC(?,?)}");
   $sth->bind_param(1, 10, SQL_INTEGER);
   $sth->bind_param_inout(2, \$value, 50, SQL_INTEGER);
   $sth->execute;
   is($value, 11);

   eval{$dbh->do("drop procedure PERL_DBD_TESTPROC");};
};

if (DBI->trace > 0) {
   DBI->trace(0);
}

$dbh->disconnect;
