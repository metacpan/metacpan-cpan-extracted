#!/usr/bin/perl -w -I./t
#
# test for rt 39897. DBD::ODBC 1.17 was accidentally changed to apply
# LongReadLen to SQL_VARCHAR columns. 1.16 and earlier only use LongTruncOk
# and LongReadLen on long columns e.g. SQL_LONGVARCHAR. As a result, if you
# had a table with a varchar(N) where N > 80 (80 being the default for
# LongReadLen) and moved from 1.16 to 1.17 then you'd suddenly get data
# truncated errors for rows where the SQL_VARCHAR was > 80 chrs.
#
use Test::More;
use strict;
$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 6;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

# can't seem to get the imports right this way
use DBI qw(:sql_types);
#1
use_ok('ODBCTEST');

my $dbh;

BEGIN {
   if (!defined $ENV{DBI_DSN}) {
      plan skip_all => "DBI_DSN is undefined";
   }
}

END {
    if ($dbh) {
        eval {
            local $dbh->{PrintWarn} = 0;
            local $dbh->{PrintError} = 0;
            $dbh->do(q/drop table PERL_DBD_rt_39897/);
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


my ($ev, $sth);

eval {
    local $dbh->{PrintWarn} = 0;
    local $dbh->{PrintError} = 0;
    $dbh->do('drop table PERL_DBD_rt_39897');
};

eval {
    $dbh->do('create table PERL_DBD_rt_39897 (a VARCHAR(100))');
};
$ev = $@;
#2
diag($ev) if $ev;
ok(!$ev, 'create test table with varchar');

SKIP: {
    skip "Failed to create test table", 1 if ($ev);
    eval {
        $sth = $dbh->prepare('INSERT into PERL_DBD_rt_39897 VALUES (?)');
    };
    $ev = $@;
    diag($ev) if $ev;
    #3
    ok($sth && !$@, "prepare insert");
};

SKIP: {
    skip "Failed to prepare", 1 if ($ev);
    eval {$sth->execute('x' x 100)};
    $ev = $@;
    diag($ev) if $ev;
    #4
    ok(!$ev, "execute insert");
};

SKIP: {
    skip "Failed to execute", 2 if ($ev);

    eval {
        $sth = $dbh->prepare(q/select a from PERL_DBD_rt_39897/);
        $sth->execute;
    };
    $ev = $@;
    diag($ev) if $ev;
    ok(!$ev, 'issue select on test table');
};

SKIP: {
    my @row;

    eval {
        local $sth->{RaiseError} = 1;
        local $sth->{PrintError} = 0;
        @row = $sth->fetchrow_array;
    };
    $ev = $@;
    diag($ev) if $ev;
    ok(!$ev, 'fetch varchar(100) from test table');
};



