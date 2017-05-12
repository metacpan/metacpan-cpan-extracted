#!/usr/bin/perl -w -I./t
#
# Test odbc_describe_parameters
# Should default to on but you can turn it off in the prepare or at the
# connection level.
#
use Test::More;
use strict;
$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 17;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

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
            $dbh->do(q/drop table PERL_DBD_drop_me/);
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
    $dbh->do('drop table PERL_DBD_drop_me');
};

eval {
    $dbh->do('create table PERL_DBD_drop_me (a integer)');
};
$ev = $@;
#2
diag($ev) if $ev;
ok(!$ev, 'create test table with integer');

BAIL_OUT("Failed to create test table") if $ev;

sub default
{
    eval {
        $sth = $dbh->prepare('INSERT into PERL_DBD_drop_me VALUES (?)');
    };
    $ev = $@;
    diag($ev) if $ev;
    #3
    ok($sth && !$@, "prepare insert");

  SKIP: {
        skip "Failed to prepare", 1 if ($ev);

        eval {
            $sth->execute(1);
        };
        $ev = $@;
        diag($ev) if $ev;
        #4
        ok(!$@, "execute ok");
    };

  SKIP: {
        skip "Failed to execute", 1 if ($ev);

        my $pts = $sth->{ParamTypes};
        #5
        is(ref($pts), 'HASH', 'ParamTypes is a hash');
        my @params = keys %$pts;
        #6
        is(scalar(@params), 1, 'one parameter');
        #use Data::Dumper;
        #diag(Dumper($pts->{$params[0]}));
        #7
        # for drivers which don't have SQLDescribeParam the type will
        # be defaulted to SQL_VARCHAR or SQL_WVARCHAR
        ok(($pts->{$params[0]}->{TYPE} == SQL_INTEGER) ||
           ($pts->{$params[0]}->{TYPE} == SQL_LONGVARCHAR) ||
           ($pts->{$params[0]}->{TYPE} == SQL_WLONGVARCHAR) ||
           ($pts->{$params[0]}->{TYPE} == SQL_WVARCHAR) ||
           ($pts->{$params[0]}->{TYPE} == SQL_VARCHAR), 'integer parameter')
            or diag("Param type: " . $pts->{$params[0]}->{TYPE});
    };


}

sub on_prepare
{
    eval {
        $sth = $dbh->prepare('INSERT into PERL_DBD_drop_me VALUES (?)',
                             {
                                 odbc_describe_parameters => 0});
    };
    $ev = $@;
    diag($ev) if $ev;
    #8
    ok($sth && !$@, "prepare insert");

  SKIP: {
        skip "Failed to prepare", 1 if ($ev);

        eval {
            $sth->execute(1);
        };
        $ev = $@;
        diag($ev) if $ev;
        #9
        ok(!$@, "execute ok");
    };

  SKIP: {
        skip "Failed to execute", 1 if ($ev);

        my $pts = $sth->{ParamTypes};
        #10
        is(ref($pts), 'HASH', 'ParamTypes is a hash');
        my @params = keys %$pts;
        #11
        is(scalar(@params), 1, 'one parameter');
        #use Data::Dumper;
        #diag(Dumper($pts->{$params[0]}));
        #12
        ok(($pts->{$params[0]}->{TYPE} == 12) ||
               ($pts->{$params[0]}->{TYPE} == -9), 'char parameter (prepare)') or
	       diag($pts->{$params[0]}->{TYPE});
    };
}

sub on_connect
{
    $dbh->{odbc_describe_parameters} = 0;

    eval {
        $sth = $dbh->prepare('INSERT into PERL_DBD_drop_me VALUES (?)');
    };
    $ev = $@;
    diag($ev) if $ev;
    #8
    ok($sth && !$@, "prepare insert");

  SKIP: {
        skip "Failed to prepare", 1 if ($ev);

        eval {
            $sth->execute(1);
        };
        $ev = $@;
        diag($ev) if $ev;
        #9
        ok(!$@, "execute ok");
    };

  SKIP: {
        skip "Failed to execute", 1 if ($ev);

        my $pts = $sth->{ParamTypes};
        #10
        is(ref($pts), 'HASH', 'ParamTypes is a hash');
        my @params = keys %$pts;
        #11
        is(scalar(@params), 1, 'one parameter');
        #use Data::Dumper;
        #diag(Dumper($pts->{$params[0]}));
        #12
        ok(($pts->{$params[0]}->{TYPE} == 12) ||
               ($pts->{$params[0]}->{TYPE} == -9), 'char parameter (connect)');
    };
}

default();
on_prepare();
on_connect();


