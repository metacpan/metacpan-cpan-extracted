#!/usr/bin/perl -w -I./t
#
# rt 101579
#
# Between 1.43 and 1.50 DBD::ODBC changed to add check_for_unicode_param
# function which changes bound types of SQL_VARCHAR etc to their unicode
# equivalent if the perl scalar is unicode. Unfortunately, if the scalar was not unicode
# or the described type was not VARCHAR it returned the SQLDescribeParam
# described type ignoring the fact we map SQL_NUMERIC etc to SQL_VARCHAR.
# The result is the first call to execute works and subsequent calls often return
# string data, right truncated for numeric parameters.
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
        $dbh->do(q/drop table PERL_DBD_RT_101579/);
        $dbh->disconnect;
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

$dbh->do(q/create table PERL_DBD_RT_101579 (a varchar(500), val numeric(9,2))/)
    or BAIL_OUT("Failed to create test table " . $dbh->errstr);

my @vals = (8295.60, 181161.80, 6514.15);
my $sth = $dbh->prepare(q/insert into PERL_DBD_RT_101579 (a, val) values(?,?)/);
foreach my $val (@vals) {
    eval {
        $sth->execute('fred', $val);
    };
    my $ev = $@;
    ok(!$ev, "Inserted $val");
}
