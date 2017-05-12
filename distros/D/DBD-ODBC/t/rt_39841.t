#!/usr/bin/perl -w -I./t
#
# Test fix for rt 39841 - problem with SQLDecribeParam in MS SQL Server
#
use Test::More;
use strict;
#use Data::Dumper;
$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 28;
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
            $dbh->do(q/drop table PERL_DBD_rt_39841a/);
            $dbh->do(q/drop table PERL_DBD_rt_39841b/);
        };
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
$dbh->{RaiseError} = 1;
my $dbms_name = $dbh->get_info(17);
#2
ok($dbms_name, "got DBMS name: $dbms_name");
my $dbms_version = $dbh->get_info(18);
#3
ok($dbms_version, "got DBMS version: $dbms_version");
my $driver_name = DBI::neat($dbh->get_info(6));

my ($ev, $sth);

SKIP: {
    skip "not SQL Server", 25 if $dbms_name !~ /Microsoft SQL Server/;
    skip "not SQL Server ODBC or native client driver", 25
        if ($driver_name !~ /SQLSRV32.DLL/oi) &&
            ($driver_name !~ /sqlncli10.dll/oi) &&
                ($driver_name !~ /SQLNCLI>DLL/oi);

    my $major_version = $dbms_version;

    eval {
        local $dbh->{PrintWarn} = 0;
        local $dbh->{PrintError} = 0;
        $dbh->do('drop table PERL_DBD_39841a');
        $dbh->do('drop table PERL_DBD_39841b');
    };

    test_1($dbh);       # 16 tests
    test_2($dbh);       # 9 tests
};

#
# A bug in the SQL Server OBDC driver causes SQLDescribeParam to
# report the parameter as an integer of column_size 10 instead of
# a varchar of column size 10. Thus when you execute with 'bbbbbb'
# SQL Server will complain that an unsupported conversion has occurred.
# We can work around this by specifically telling DBD::ODBC to bind
# as a VARCHAR.
# The bug is due to SQL Server rearranging the SQL above to:
# select a1 from PERL_DBD_38941a where 1 = 2
# and it should have run
# select b2 from PERL_DBD_38941b where 1 = 2
#
sub test_1
{
    $dbh = shift;
    my $sth;

    eval {
        $dbh->do('create table PERL_DBD_39841a (a1 integer, a2 varchar(20))');
        $dbh->do('create table PERL_DBD_39841b (b1 double precision, b2 varchar(8))');
    };
    $ev = $@;
    #1
    ok(!$ev, 'create test tables');

  SKIP: {
        skip "Failed to create test table", 10 if ($ev);
        eval {
            $dbh->do(q/insert into PERL_DBD_39841a values(1, 'aaaaaaaaaa')/);
            $dbh->do(q/insert into PERL_DBD_39841b values(1, 'bbbbbbbb')/);
        };
        $ev = $@;
        #2
        ok(!$ev, "populate tables");

        eval {
            $sth = $dbh->prepare(q/select b1, ( select a2 from PERL_DBD_39841a where a1 = b1 ) from PERL_DBD_39841b where b2 = ?/);
        };
        $ev = $@;
        #3
        ok(!$ev, 'prepare select');

      SKIP: {			# 13
	  skip 'cannot prepare SQL for test', 13 if $ev;
	  eval {
	      local $sth->{PrintError} = 0;
	      $sth->execute('bbbbbb');
	  };
	  my $ev = $@;

        SKIP: {			# 5
	    if ($ev) {
                diag($dbh->errstr);
		diag($dbh->state);
		if ($dbh->state eq '22018') {
                    diag("\nNOTE: Your SQL Server ODBC driver has a bug which can describe parameters\n");
                    diag("in SQL using sub selects incorrectly. In this case a VARCHAR(8) parameter\n");
                    diag("is described as an INTEGER\n\n");
		    skip 'test_1 execute failed - bug in SQL Server ODBC Driver', 5;
		} else {
		    skip 'test_1 execute failed with unexpected error', 5;
		}
            }
	    #1
            pass('test_1 execute');
	    #2
	    is($sth->{NUM_OF_PARAMS}, 1, 'correct number of parameters');
	    #diag(Dumper($sth->{ParamTypes}));
	    #3
	    is($sth->{NUM_OF_FIELDS}, 2, 'fields in result-set');
	    my $count;
	    eval {
		while($sth->fetchrow_array) {
		    $count = 0 if !defined($count);
		    $count++};
	    };
	    #4
	    ok(!$ev, "fetchrow_array");
	    #5
	    ok(!defined($count), "no rows returned");
	  };

	SKIP: {			# 8
	    skip "no bug found", 8 if !$ev;
	    skip "unexpected error this test is not checking for", 8
		if ($dbh->state ne '22018');
	    diag("Checking you can work around bug in SQL Server ODBC Driver");
	    eval {
		$sth->bind_param(1, 'bbbbbb', SQL_VARCHAR);
		$sth->execute;
	    };
	    $ev = $@;
	    if ($ev) {
		diag("No you cannot");
		skip "Cannot work around bug", 4;
	    } else {
		diag("Yes you can");
		#1
		is($sth->{NUM_OF_PARAMS}, 1, 'correct number of parameters');
		#2
		is($sth->{NUM_OF_FIELDS}, 2, 'fields in result-set');
		#diag(Dumper($sth->{ParamTypes}));
		my $pv = $sth->{ParamValues};
		#3
		ok(defined($pv), "Parameter values");
	      SKIP: {
          	  skip "no parameter values", 3 if !$pv;
		  #1
          	  is(ref($pv), 'HASH', 'parameter value hash');
		  #2
          	  ok(exists($pv->{1}), 'parameter 1 exists');
          	  SKIP: {
		      skip "no p1", 1 if !exists($pv->{1});
		      #1
		      is($pv->{1}, 'bbbbbb', 'parameter has right value');
          	  };
		};
		my $count;
		eval {
		    while($sth->fetchrow_array) {
			$count = 0 if !defined($count);
			$count++};
		};
		#4
		ok(!$ev, "fetchrow_array");
		#5
		ok(!defined($count), "no rows returned");
	    }
	  };
	};
    }
    eval {
        local $dbh->{PrintWarn} = 0;
        local $dbh->{PrintError} = 0;
        $dbh->do('drop table PERL_DBD_39841a');
        $dbh->do('drop table PERL_DBD_39841b');
    };
}

#
# Here SQL Server gets confused and rearranges the SQL to find out about
# PERL_DBD_39841a.a2 when it should have returned information about
# PERL_DBD_39841b.b2. This used to lead to DBD::ODBC binding p1 as
# 'bbbbbbbbbbbbbbbbbbbb' but specifying a column size of 10 - hence
# data truncation error.
#
sub test_2
{
    $dbh = shift;
    my $sth;

    eval {
	local $dbh->{PrintError} = 1;
        $dbh->do('create table PERL_DBD_39841a (a1 integer, a2 varchar(10))');
        $dbh->do('create table PERL_DBD_39841b (b1 varchar(10), b2 varchar(20))');
    };
    $ev = $@;
    #1
    ok(!$ev, 'create test tables');

  SKIP: {                       # 8
        skip "Failed to create test table", 8 if ($ev);
        eval {
            $dbh->do(q/insert into PERL_DBD_39841a values(1, 'aaaaaaaaaa')/);
            $dbh->do(q/insert into PERL_DBD_39841b values('aaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbbb')/);
        };
        $ev = $@;
        #1 1
        ok(!$ev, "populate tables");

        eval {
            $sth = $dbh->prepare(q/select b1, ( select a2 from PERL_DBD_39841a where a2 = b1 ) from PERL_DBD_39841b where b2 = ?/);
        };
        $ev = $@;
        #1 2
        ok(!$ev, 'prepare select');

      SKIP: {			# 6
	  skip 'cannot prepare SQL for test', 6 if $ev;
	  eval {
	      local $sth->{PrintError} = 0;
	      $sth->execute('bbbbbbbbbbbbbbbbbbbb');
	  };
	  my $ev = $@;

        SKIP: {			# 5 + 1
	    if ($ev) {
                diag($dbh->errstr);
		diag($dbh->state);
		if ($dbh->state eq '22001') {
		    diag("Bug 39841 is back in some unexpected way");
		    diag("Please report this via rt");
		    #1
		    fail('test_1 execute');
		    skip 'Bug 39841 is back', 5;
		} else {
		    diag("Unexpected error - please report this via rt");
		    fail('test_1 execute');
		    #1
		    skip 'unexpected error', 5;
		}
            } else {
		#1
		pass('test_1 execute');
	    }
	    #2
	    is($sth->{NUM_OF_PARAMS}, 1, 'correct number of parameters');
	    #diag(Dumper($sth->{ParamTypes}));
	    #3
	    is($sth->{NUM_OF_FIELDS}, 2, 'fields in result-set');
	    my $count;
	    eval {
		while($sth->fetchrow_array) {
		    $count = 0 if !defined($count);
		    $count++};
	    };
	    #4
	    ok(!$ev, "fetchrow_array");
	    #5
	    ok(defined($count), "rows returned");
	  SKIP: {               # 1
	      skip "no rows returned", 1 if !defined($count);
	      # 6
	      is($count, 1, 'correct number of rows returned');
	    };
	  };
	};
    }
    eval {
        local $dbh->{PrintWarn} = 0;
        local $dbh->{PrintError} = 0;
        $dbh->do('drop table PERL_DBD_39841a');
        $dbh->do('drop table PERL_DBD_39841b');
    };
}


