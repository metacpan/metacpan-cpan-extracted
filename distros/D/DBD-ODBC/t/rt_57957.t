#!/usr/bin/perl -w -I./t
use Test::More;
use strict;
#
# Test rt57957 - comments in SQL were not ignored so placeholders like :name
# and ? were seen.
# Also tests for placeholders in literals.
#

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 8;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

use DBI qw(:sql_types);
use_ok('ODBCTEST');             # 1
#use_ok('Data::Dumper');         # 2

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
            $dbh->do(q/drop table PERL_DBD_rt_46597/);
        };
        $dbh->disconnect;
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings); # 8
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
my $dbname = $dbh->get_info(17); # DBI::SQL_DBMS_NAME
my $driver_name = $dbh->get_info(6);
diag("\nSome of these tests may fail for your driver - please let me know if they do along with the strings $dbname/$driver_name");
# the point about the SQL in the next line is that if DBD::ODBC was
# ignoring comments everything between /* and */ would be ignored but
# if it is not ignored it looks like you have used the same placeholder
# (:00) twice.
$dbh->{PrintError} = 0;
$dbh->{RaiseError} = 0;
eval {
     my $sth = $dbh->prepare('select 1 /* $Date: 2010/05/01 12:00:00 */');
};
ok(!$@, "Prepare with trailing comment and named placeholder") or diag($@);

eval {
     my $sth = $dbh->prepare('/* $Date: 2010/05/01 12:00:00 */ select 1');
};
ok(!$@, "Prepare with leading comment and named placeholder") or diag($@);

eval {
    my $sth = $dbh->prepare(<<'EOT');
select -- $Date: 2010/05/01 12:00:00
1
EOT
};
ok(!$@, "Prepare with line comment named placeholder") or diag($@);

eval {
     my $sth = $dbh->prepare('/* placeholder ? in comment */ select 1');
};
ok(!$@, "Prepare with leading comment and ? placeholder") or diag($@);

eval {
    my $sth = $dbh->prepare(<<'EOT');
select -- placeholder ? in a comment
1
EOT
};
ok(!$@, "Prepare with line comment and ? placeholder") or diag($@);

eval {
     my $sth = $dbh->prepare(q/select '?'/);
};
ok(!$@, "Prepare with ? placeholder in literal") or diag($@);

eval {
     my $sth = $dbh->prepare(q/select ':named'/);
};
ok(!$@, "Prepare with named placeholder in literal") or diag($@);

