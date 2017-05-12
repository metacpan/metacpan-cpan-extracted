#!/usr/bin/perl -w -I./t
use Test::More;
use strict;

$| = 1;

my $has_test_nowarnings = 1;
eval "require Test::NoWarnings";
$has_test_nowarnings = undef if $@;
my $tests = 67;
$tests += 1 if $has_test_nowarnings;
plan tests => $tests;

my $dbh;

use DBI qw(:sql_types);
use DBI::Const::GetInfoType;

use_ok('ODBCTEST');

BEGIN {
    plan skip_all => "DBI_DSN is undefined" if (!defined $ENV{DBI_DSN});
}

END {
    # tidy up
    if ($dbh) {
        local $dbh->{PrintError} = 0;
        local $dbh->{PrintWarn} = 0;
        eval {
            $dbh->do(q/drop procedure PERL_DBD_PROC1/);
            $dbh->do(q/drop procedure PERL_DBD_PROC2/);
            $dbh->do(q/drop table PERL_DBD_TABLE1/);
        };
    }
    Test::NoWarnings::had_no_warnings()
          if ($has_test_nowarnings);
}

my $dbms_name;
my $dbms_version;
my $m_dbmsversion;
my $driver_name;

sub getinfo
{
    my $dbh = shift;

    $dbms_name = $dbh->get_info($GetInfoType{SQL_DBMS_NAME});
    ok($dbms_name, "got DBMS name: $dbms_name");
    $dbms_version = $dbh->get_info($GetInfoType{SQL_DBMS_VER});
    ok($dbms_version, "got DBMS version: $dbms_version");
    $m_dbmsversion = $dbms_version;
    $m_dbmsversion =~ s/^(\d+).*/$1/;
    ok($m_dbmsversion, "got DBMS major version: $m_dbmsversion");
    $driver_name = $dbh->get_info($GetInfoType{SQL_DRIVER_NAME});
    ok($driver_name, "got Driver Name: $driver_name");
}

sub varmax_test
{
    my ($dbh, $coltype) = @_;

  SKIP: {
        skip "SQL Server major version $m_dbmsversion too old", 4
            if $m_dbmsversion < 9;

        my $data = 'x' x 1000;
        my $datalen = length($data);
        local $dbh->{PrintError} = 0;
        local $dbh->{RaiseError} = 1;
        local $dbh->{LongReadLen} = length($data) * 2;

        eval {$dbh->do(q/drop table PERL_DBD_TABLE1/);};
        eval {
            $dbh->do(qq/create table PERL_DBD_TABLE1 (a int identity, b $coltype(MAX))/);
            # workaround freeTDS problem:
            if ($driver_name =~ /tdsodbc/) {
                $dbh->do( qq/insert into PERL_DBD_TABLE1 (b) values(CAST(? AS $coltype(MAX)))/, undef, $data);
            } else {
            $dbh->do(q/insert into PERL_DBD_TABLE1 (b) values(?)/,
                     undef, $data);
            }
        };
        diag($@) if $@;
        ok(!$@, "create PERL_DBD_TABLE1 and insert test data");
      SKIP: {
            skip "failed to create test table or insert data", 3 if $@;

            my $sth = $dbh->prepare(q/select a,b from PERL_DBD_TABLE1/);
            $sth->execute;
            my ($a, $b);
            eval {
                ($a, $b) = $sth->fetchrow_array;
            };
            diag($@) if $@;
            ok(!$@, "fetchrow for $coltype(max)");
          SKIP: {
                skip "fetchrow failed", 2 if $@;

                ok($b, "data received from $coltype(max)");
                is(length($b), $datalen,
                   'all data (' . length($b) . ") received from $coltype(max)");
            };
        };
    };
    eval {
        local $dbh->{PrintError} = 0;
        local $dbh->{RaiseError} = 0;
        $dbh->do(q/drop table PERL_DBD_TABLE1/);
    };
}

sub _do_proc
{
    my ($dbh, $proc) = @_;

    my $sth;

    eval {$sth = $dbh->prepare($proc, {odbc_exec_direct => 1})};
    my $ev = $@;
    diag($ev) if $ev;
    ok(!$ev, "prepare for $proc");

  SKIP: {
        skip "prepare for $proc failed", 3 if $ev;
      SKIP: {
            eval {$sth->execute};
            $ev = $@;
            diag($ev) if $ev;
            ok(!$ev, "execute for $proc");

          SKIP: {
                skip "execute for $proc failed", 2 if $ev;

                my $fields;
                eval {$fields = $sth->{NUM_OF_FIELDS}};
                $ev = $@;
                diag($ev) if $ev;
                ok(!$ev, "NUM_OF_FIELDS for $proc");
                like($fields, qr|^\d+$|, "numeric fields");
            };
            $sth->finish;
        };
    };
}

sub procs_with_no_results
{
    my $dbh = shift;

    local $dbh->{PrintError} = 0;

    eval {$dbh->do(q/drop procedure PERL_DBD_PROC1/)};
    eval {$dbh->do(q/drop procedure PERL_DBD_PROC2/)};

    my $proc1 = <<EOT;
create procedure PERL_DBD_PROC1 as
begin
select * from master..sysprocesses
delete from #tmp
end
EOT

    my $proc2 = <<EOT;
create procedure PERL_DBD_PROC2 as
begin
select * into #tmp from master..sysprocesses
delete from #tmp
end
EOT

    eval {$dbh->do($proc1)};
    my $ev = $@;
    diag($ev) if $ev;
    ok(!$ev, 'create perl_dbd_proc1 procedure');
  SKIP: {
        skip 'failed to create perl_dbd_proc1 procedure', 9 if $ev;

      SKIP: {
            eval {$dbh->do($proc2)};
            $ev = $@;
            diag($ev) if $ev;
            ok(!$ev, 'create perl_dbd_proc2 procedure');

          SKIP: {
                skip 'failed to create perl_dbd_proc2 procedure', 8 if $ev;

                _do_proc($dbh, 'PERL_DBD_PROC1');

                _do_proc($dbh, 'PERL_DBD_PROC2');
            };
        };
    };
}

sub Multiple_concurrent_stmts {
   my ($dbh, $expect) = @_;
   my $sth = $dbh->prepare("select * from PERL_DBD_TABLE1");
   $dbh->{RaiseError} = 1;
   $sth->execute;
   my @row;
   eval {
       while (@row = $sth->fetchrow_array()) {
           my $sth2 = $dbh->prepare("select * from $ODBCTEST::table_name");
           $sth2->execute;
           my @row2;
           while (@row2 = $sth2->fetchrow_array()) {
           }
       }
   };

   if ($@) {
       diag($@) if (defined($expect) && ($expect == 1));
       return 0;
   }
   diag("Expected fail of MARS and it worked!")
       if (defined($expect) && ($expect == 0));
   return 1;
}

$dbh = DBI->connect();
unless($dbh) {
   BAIL_OUT("Unable to connect to the database $DBI::errstr\nTests skipped.\n");
   exit 0;
}
my $sth;

my $dbname = $dbh->get_info($GetInfoType{SQL_DBMS_NAME});
SKIP: {
   skip "Microsoft SQL Server tests not supported using $dbname", 66
       unless ($dbname =~ /Microsoft SQL Server/i);

   getinfo($dbh);

   varmax_test($dbh, 'varchar');
   varmax_test($dbh, 'varbinary');
   varmax_test($dbh, 'nvarchar');

   procs_with_no_results($dbh);

   # the times chosen below are VERY specific to NOT cause rounding errors,
   # but may cause different errors on different versions of SQL Server.
   my @data = (
	       [undef, "z" x 13 ],
	       ["2001-01-01 01:01:01.110", "a" x 12],   # "aaaaaaaaaaaa"
	       ["2002-02-02 02:02:02.123", "b" x 114],
	       ["2003-03-03 03:03:03.333", "c" x 251],
	       ["2004-04-04 04:04:04.443", "d" x 282],
	       ["2005-05-05 05:05:05.557", "e" x 131]
	      );

   eval {
      local $dbh->{PrintError} = 0;
      $dbh->do("DROP TABLE PERL_DBD_TABLE1");
   };

   $dbh->{RaiseError} = 1;
   $dbh->{LongReadLen} = 800;

   my @types = (SQL_TYPE_TIMESTAMP, SQL_TIMESTAMP);
   my $row = $dbh->type_info(\@types);
   BAIL_OUT("Unable to find a suitable test type for date field") if !$row;
   my $datetype = $row->{TYPE_NAME};
   $dbh->do("CREATE TABLE PERL_DBD_TABLE1 (i INTEGER, time $datetype, str VARCHAR(4000))");


   # Insert records into the database:
   my $sth1 = $dbh->prepare("INSERT INTO PERL_DBD_TABLE1 (i,time,str) values (?,?,?)");
   for (my $i=0; $i<@data; $i++) {
      my ($time,$str) = @{$data[$i]};
      # print "Inserting:  $i, ";
      # print  $time if (defined($time));
      # print " string length " . length($str) . "\n";
      $sth1->bind_param (1, $i,    SQL_INTEGER);
      $sth1->bind_param (2, $time, SQL_TIMESTAMP);
      $sth1->bind_param (3, $str,  SQL_LONGVARCHAR);
      $sth1->execute  or die ($DBI::errstr);
   }

   # Retrieve records from the database, and see if they match original data:
   my $sth2 = $dbh->prepare("SELECT i,time,str FROM PERL_DBD_TABLE1");
   $sth2->execute  or die ($DBI::errstr);
   my $iErrCount = 0;
   while (my ($i,$time,$str) = $sth2->fetchrow_array()) {
       if (defined($time)) {
           $time =~ s/0000$//o;
       }
      if ((defined($time) && $time ne $data[$i][0]) ||
              defined($time) != defined($data[$i][0])) {
	 diag("Retrieving: $i, $time string length: " . length($str) . "\t!time ");
	 $iErrCount++;
      }

      if ($str  ne $data[$i][1]) {
	 diag("Retrieving: $i, $time string length: " . length($str) . "\t!string ");
	 $iErrCount++;
      }
      # print "\n";
   }
   is($iErrCount, 0, "errors on data comparison");


   eval {
      local $dbh->{RaiseError} = 0;
      $dbh->do("DROP TABLE PERL_DBD_TABLE1");
   };

   my $sql = 'CREATE TABLE #PERL_DBD_TABLE1 (id INT PRIMARY KEY, val VARCHAR(4))';
   $dbh->do($sql);
   # doesn't work with prepare, etc...hmmm why not?
   # $sth = $dbh->prepare($sql);
   # $sth->execute;
   # $sth->finish;
   # See http://technet.microsoft.com/en-US/library/ms131667.aspx
   # which says
   # "Prepared statements cannot be used to create temporary objects on SQL
   # Server 2000 or later..."
   #
   $sth = $dbh->prepare("INSERT INTO #PERL_DBD_TABLE1 (id, val) VALUES (?, ?)");
   $sth2 = $dbh->prepare("INSERT INTO #PERL_DBD_TABLE1 (id, val) VALUES (?, ?)");
   my @data2 = (undef, 'foo', 'bar', 'blet', undef);
   my $i = 0;
   my $val;
   foreach $val (@data2) {
      $sth2->execute($i++, $val);
   }
   $i = 0;
   $sth = $dbh->prepare("Select id, val from #PERL_DBD_TABLE1");
   $sth->execute;
   $iErrCount = 0;
   while (my @row = $sth->fetchrow_array) {
      unless ((!defined($row[1]) && !defined($data2[$i])) || ($row[1] eq $data2[$i])) {
	 $iErrCount++ ;
	 print "$row[1] ne $data2[$i]\n";
      }
      $i++;
   }

   is($iErrCount, 0, "temporary table handling");
   diag("Please upgrade your ODBC drivers to the latest SQL Server drivers available.  For example, 2000.80.194.00 is known to be problematic.  Use MDAC 2.7, if possible\n") if ($iErrCount != 0);

   $dbh->{PrintError} = 0;
   eval {$dbh->do("DROP TABLE PERL_DBD_TABLE1");};
   eval {$dbh->do("CREATE TABLE PERL_DBD_TABLE1 (i INTEGER)");};

   eval {$dbh->do("DROP PROCEDURE PERL_DBD_PROC1");};
   eval {$dbh->do("CREATE PROCEDURE PERL_DBD_PROC1 \@inputval int AS ".
		  "INSERT INTO PERL_DBD_TABLE1 VALUES (\@inputval); " .
		  "	return \@inputval;");};


   $sth1 = $dbh->prepare ("{? = call PERL_DBD_PROC1(?) }");
   my $output = undef;
   $i = 1;
   $iErrCount = 0;
   while ($i < 4) {
      $sth1->bind_param_inout(1, \$output, 50, DBI::SQL_INTEGER);
      $sth1->bind_param(2, $i, DBI::SQL_INTEGER);

      $sth1->execute();
      # print "$output";
      if (!defined($output) || ($output !~ /\d+/) || ($output != $i)) {
	 $iErrCount++;
	 diag("output='$output' error, expected $i\n");
      }
      # print "\n";
      $i++;
   }

   is($iErrCount, 0, "bind param in out with insert result set");
   $iErrCount = 0;
   eval {$dbh->do("DROP PROCEDURE PERL_DBD_PROC1");};
   my $proc1 =
	      "CREATE PROCEDURE PERL_DBD_PROC1 (\@i int, \@result int OUTPUT) AS ".
	      "BEGIN ".
	      "    SET \@result = \@i+1;".
	      "END ";
   # print "$proc1\n";
   $dbh->do($proc1);

   # $dbh->{PrintError} = 1;
   $sth1 = $dbh->prepare ("{call PERL_DBD_PROC1(?, ?)}");
   $i = 12;
   $output = undef;
   $sth1->bind_param(1, $i, DBI::SQL_INTEGER);
   $sth1->bind_param_inout(2, \$output, 100, DBI::SQL_INTEGER);
   $sth1->execute;
   is($i, $output-1, "test output params accurate");

   $iErrCount = 0;
   $sth = $dbh->prepare("select * from PERL_DBD_TABLE1 order by i");
   $sth->execute;
   $i = 1;
   while (my @row = $sth->fetchrow_array) {
      if ($i != $row[0]) {
	 diag(join(', ', @row), " ERROR!\n");
	 $iErrCount++;
      }
      $i++;
   }


   is($iErrCount, 0, "verify select data");

   eval {$dbh->do("DROP TABLE PERL_DBD_TABLE1");};
   eval {$dbh->do("CREATE TABLE PERL_DBD_TABLE1 (d DATETIME)");};
   $sth = $dbh->prepare ("INSERT INTO PERL_DBD_TABLE1 (d) VALUES (?)");
   $sth->bind_param (1, undef, SQL_TYPE_TIMESTAMP);
   $sth->execute();
   $sth->bind_param (1, "2002-07-12 05:08:37.350", SQL_TYPE_TIMESTAMP);
   $sth->execute();
   $sth->bind_param (1, undef, SQL_TYPE_TIMESTAMP);
   $sth->execute();

   $iErrCount = 0;
   $sth2 = $dbh->prepare("select * from PERL_DBD_TABLE1 where d is not null");
   $sth2->execute;
   while (my @row = $sth2->fetchrow_array) {
      if ($row[0] ne "2002-07-12 05:08:37.350") {
	 $iErrCount++ ;
	 diag(join(", ", @row), "\n");
      }
   }
   is($iErrCount, 0, "timestamp handling");

   eval {$dbh->do('DROP TABLE PERL_DBD_TABLE1');};
   eval {$dbh->do('DROP PROCEDURE PERL_DBD_PROC1');};

   eval {$dbh->do('CREATE TABLE PERL_DBD_TABLE1 (i INTEGER, j integer)')}
   or diag($@);

   $proc1 = <<EOT;
CREATE PROCEDURE PERL_DBD_PROC1 (\@i INT) AS
DECLARE \@result INT;
BEGIN
   SET \@result = \@i;
   IF (\@i = 99)
      BEGIN
	 UPDATE PERL_DBD_TABLE1 SET i=\@i;
	 SET \@result = \@i + 1;
      END;
   SELECT \@result;
END
EOT
   $dbh->{RaiseError} = 0;
   # NOTE: MS SQL native client for linux fails this test because
   # SQLExecute returns SQL_NO_DATA even though the proc never did
   # a searched update/delete - AND it works on the same Windows driver.
   eval {$dbh->do($proc1)} or diag($@);
   my $sth = $dbh->prepare ('{call PERL_DBD_PROC1 (?)}');
   my $success = -1;

   $sth->bind_param (1, 99, SQL_INTEGER);
   my $cres = $sth->execute();
   ok(defined($cres), "execute for non searched update via procedure");
   if (!defined($cres)) {
       note("Your driver has a bug which means it is probably incorrectly returning SQL_NO_DATA from a non-searched update");
   }
 SKIP: {
       skip "execute failed - probably SQL_NO_DATA bug", 4 if !defined($cres);
       ok($cres eq '0E0' || $cres == -1, "0/unknown rows updated");

       $success = -1;
       while (my @data = $sth->fetchrow_array()) {($success) = @data;}
       is($success, 100, 'procedure outputs results as result set');

       $sth->bind_param (1, 10, SQL_INTEGER);
       $sth->execute();
       $success = -1;
       while (my @data = $sth->fetchrow_array()) {($success) = @data;}
       is($success,10, 'procedure outputs results as result set2');

       $sth->bind_param (1, 111, SQL_INTEGER);
       $sth->execute();
       $success = -1;
       do {
           my @data;
           while (@data = $sth->fetchrow_array()) {
               if ($#data == 0) {
                   ($success) = @data;
               }
           }
       } while ($sth->{odbc_more_results});
       is($success, 111, 'procedure outputs results as result set 3');
   };

   #
   # special tests for even stranger cases...
   #
   eval {$dbh->do("DROP PROCEDURE PERL_DBD_PROC1");};
   $proc1 = <<EOT;
   CREATE PROCEDURE PERL_DBD_PROC1 (\@i INT) AS
   DECLARE \@result INT;
   BEGIN
   SET \@result = \@i;
   IF (\@i = 99)
      BEGIN
	 UPDATE PERL_DBD_TABLE1 SET i=\@i;
	 SET \@result = \@i + 1;
      END;
   IF (\@i > 100)
      BEGIN
	 INSERT INTO PERL_DBD_TABLE1 (i, j) VALUES (\@i, \@i);
	 SELECT i, j from PERL_DBD_TABLE1;
      END;
   SELECT \@result;
   END
EOT

   eval {$dbh->do($proc1);};

   # set the required attribute and check it.
   $dbh->{odbc_force_rebind} = 1;
   is($dbh->{odbc_force_rebind}, 1, "setting force_rebind");
   $dbh->{odbc_force_rebind} = 0;
   is($dbh->{odbc_force_rebind}, 0, "resetting force_rebind");

   $sth = $dbh->prepare ("{call PERL_DBD_PROC1 (?)}");
   is($sth->{odbc_force_rebind}, 0, "testing force rebind after procedure call");
   $success = -1;

   $sth->bind_param (1, 99, SQL_INTEGER);
   $cres = $sth->execute();
   ok(defined($cres), "execute for non searched update via procedure, force_rebind");
   if (!defined($cres)) {
       note("Your driver has a bug which means it is probably incorrectly returning SQL_NO_DATA from a non-searched update");
   }
 SKIP: {
       skip "execute failed - probably SQL_NO_DATA bug", 3 if !defined($cres);
       $success = -1;
       while (my @data = $sth->fetchrow_array()) {($success) = @data;}
       is($success, 100, "force rebind test part 2");

       $sth->bind_param (1, 10, SQL_INTEGER);
       $sth->execute();
       $success = -1;
       while (my @data = $sth->fetchrow_array()) {($success) = @data;}
       is($success, 10, "force rebind test part 3");

       $sth->bind_param (1, 111, SQL_INTEGER);
       $sth->execute();
       $success = -1;
       do {
           my @data;
           while (@data = $sth->fetchrow_array()) {
               if ($#data == 0) {
                   ($success) = @data;
               } else {
                   # diag("Data: ", join(',', @data), "\n");
               }
           }
       } while ($sth->{odbc_more_results});
       is($success, 111, "force rebind test part 4");

       # ensure the attribute is automatically set.
       # the multiple result sets will trigger this.
       is($sth->{odbc_force_rebind}, 1, "forced rebind final");
   }

   #
   # more special tests
   # make sure output params are being set properly when
   # multiple result sets are available.  Also, ensure fetchrow_hashref
   # works with multiple statements.
   #
   eval {$dbh->do("DROP PROCEDURE PERL_DBD_PROC1");};
   $dbh->do("CREATE PROCEDURE  PERL_DBD_PROC1
\@parameter1 int = 22
AS
	/* SET NOCOUNT ON */
	select 1 as some_data
	select isnull(\@parameter1, 0) as parameter1, 3 as some_more_data
	RETURN(\@parameter1 + 1)");

   my $queryInputParameter1 = 2222;
   my $queryOutputParameter = 0;

   $sth = $dbh->prepare('{? = call PERL_DBD_PROC1(?) }');
   $sth->bind_param_inout(1, \$queryOutputParameter, 30, { TYPE => DBI::SQL_INTEGER });
   $sth->bind_param(2, $queryInputParameter1, { TYPE => DBI::SQL_INTEGER });

   $sth->execute();

   do {
      for(my $rowRef; $rowRef = $sth->fetchrow_hashref('NAME'); )  {
	 my %outputData = %$rowRef;
	 if (defined($outputData{some_data})) {
	    is($outputData{some_data},1,"Select data available");
	    ok(!defined($outputData{parameter1}), "output param not yet available");
	    ok(!defined($outputData{some_more_data}), "output param not yet available2");
	 } else {
	    is($outputData{parameter1},2222, "Output param data available");
	    is($outputData{some_more_data},3, "Output param data available 2");
	    ok(!defined($outputData{some_data}), "select data done");
	 }
	 # diag('outputData ', Dumper(\%outputData), "\n");
      }
      # print "out of for loop\n";
   } while($sth->{odbc_more_results});
   # print "out of while loop\n";
   is($queryOutputParameter, $queryInputParameter1 + 1, "valid output data");

   # test a procedure with no parameters
   eval {$dbh->do("DROP PROCEDURE PERL_DBD_PROC1");};
   eval {$dbh->do("CREATE PROCEDURE PERL_DBD_PROC1 AS return 1;");};

   $sth1 = $dbh->prepare ("{ ? = call PERL_DBD_PROC1 }");
   $output = undef;
   $iErrCount = 0;
   $sth1->bind_param_inout(1, \$output, 50, DBI::SQL_INTEGER);

   $sth1->execute();
   is($output, 1, "test procedure with no input params");
   $sth1 = undef;		# could still be active with some drivers

   $dbh->{odbc_async_exec} = 1;
   # print "odbc_async_exec is: $dbh->{odbc_async_exec}\n";
   is($dbh->{odbc_async_exec}, 1, "test odbc_async_exec attribute set");

   # not sure if this should be a test.  May have permissions problems, but
   # it's the only sample of the error handler stuff I have.
   my $testpass = 0;
   my $lastmsg;

   sub err_handler {
      my ($state, $msg, $nativeerr) = @_;
      # Strip out all of the driver ID stuff
      # normally something like [SQL Server Native Client 10.0][SQL Server]
      $msg =~ s/^(\[[\w\s:\.]*\])+//;
      $lastmsg = $msg;
      #diag "===> state: $state msg: $msg nativeerr: $nativeerr\n";
      $testpass++;
      return 0;
   }

   $dbh->{odbc_err_handler} = \&err_handler;

   $sth = $dbh->prepare("dbcc TRACESTATUS(0)");
   $sth->execute;
   cmp_ok($testpass, '>', 0, "dbcc messages being returned");
   $testpass = 0;
   $dbh->{odbc_async_exec} = 0;
   is($dbh->{odbc_async_exec}, 0, "reset async exec");

   $dbh->do(q/delete from PERL_DBD_TABLE1/);
   $dbh->do(q/insert into PERL_DBD_TABLE1 values(1, 1)/);
   $dbh->{odbc_exec_direct} = 1;
   is($dbh->{odbc_exec_direct}, 1, "test setting odbc_exec_direct");
   $sth2 = $dbh->prepare("print 'START' select count(*) from PERL_DBD_TABLE1 print 'END'");
   $sth2->execute;
   do {
      while (my @row = $sth2->fetchrow_array) {
	 is($row[0], 1, "Valid select results with print statements");
      }
   } while ($sth2->{odbc_more_results});

   is($testpass,2, "ensure 2 error messages from two print statements");
   is($lastmsg, 'END', "validate error messages being retrieved");

   # need the finish if there are print statements (for now)
   #$sth2->finish;
   $dbh->{odbc_err_handler} = undef;
   # We need to make sure there is sufficient data returned to
   # overflow the TDS buffer. If all the results fit into one buffer
   # the tests checking for MAS not working work succeed.
   for (my $i = 1; $i < 1000; $i += 2) {
       $dbh->do('insert into PERL_DBD_TABLE1 (i, j) values (?, ?)', undef, $i, $i+1);
   }
   #$dbh->do("insert into PERL_DBD_TABLE1 (i, j) values (1, 2)");
   #$dbh->do("insert into PERL_DBD_TABLE1 (i, j) values (3, 4)");

   $dbh->disconnect;

   my $dsn = $ENV{DBI_DSN};
   if ($dsn !~ /^dbi:ODBC:DSN=/ && $dsn !~ /DRIVER=/i) {
       my @a = split(q/:/, $ENV{DBI_DSN});
       $dsn = join(q/:/, @a[0..($#a - 1)]) . ":DSN=" . $a[-1];
   }
   my $base_dsn = $dsn;
   $dsn .= ";MARS_Connection=no";
   $dbh = DBI->connect($dsn, $ENV{DBI_USER}, $ENV{DBI_PASS}, {PrintError => 0});
   ok($dbh, "Connected with MARS_Connection");
   diag("$DBI::errstr\n$dsn\n") if !$dbh;
 SKIP: {
       skip "could not connect with MARS_Connection attribute", 1 if !$dbh;

       ok(!&Multiple_concurrent_stmts($dbh, 0), "Multiple concurrent statements should fail");
       $dbh->disconnect;
   };

   $dbh = DBI->connect($dsn, $ENV{DBI_USER}, $ENV{DBI_PASS}, { odbc_cursortype => 2, PrintError => 0 });
   # $dbh->{odbc_err_handler} = \&err_handler;
   ok(&Multiple_concurrent_stmts($dbh, 1), "Multiple concurrent statements succeed (odbc_cursortype set)");

 SKIP: {
       skip "MS SQL Server version < 9", 1 if ($m_dbmsversion < 9);
       $dbh->disconnect; # throw away non-mars connection
       $dsn = "$base_dsn;MARS_Connection=yes;";
       $dbh = DBI->connect($dsn, $ENV{DBI_USER}, $ENV{DBI_PASS}, {PrintError => 0});
       my $tst = "Multiple concurrent statements succeed with MARS";
       if (&Multiple_concurrent_stmts($dbh,1)) {
           pass($tst);
       } else {
           diag("DSN=$dsn\n");
           diag("\nNOTE: You failed this test because your SQL Server driver\nis too old to handle the MARS_Connection attribute. This test cannot\neasily skip this test for old drivers as there is no definite SQL Server\ndriver version it can check.\n\n");
           skip 'WARNING: driver does NOT support MARS_Connection', 1;
       }
       $dbh->disconnect; # throw away mars connection
       $dbh = DBI->connect;
   }

   # clean up test table and procedure
   # reset err handler
   # $dbh->{odbc_err_handler} = undef;
   eval {$dbh->do("DROP TABLE PERL_DBD_TABLE1");};
   eval {$dbh->do("DROP PROCEDURE PERL_DBD_PROC1");};

   eval { local $dbh->{PrintError} = 0; $dbh->do("drop table perl_dbd_test1"); };
   $dbh->do("create table perl_dbd_test1 (i integer primary key, t varchar(30))");
   $dbh->{AutoCommit} = 0;
   $dbh->do("insert into perl_dbd_test1 (i, t) values (1, 'initial')");
   $dbh->commit;
   $dbh->do("update perl_dbd_test1 set t = 'second' where i = 1");

   my $dbh2 = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, {odbc_query_timeout => 2, PrintError=>0});
   # $dbh2->{odbc_query_timeout} = 5;
   $dbh2->{AutoCommit} = 0;
   $dbh2->do("update perl_dbd_test1 set t = 'bad' where i = ?",undef,1);
   $dbh2->rollback;
   # should timeout and get to here.  if so, test will pass
   pass("passed timeout on query using odbc_query_timeout using do with bind params");
   $dbh2->do("update perl_dbd_test1 set t = 'bad' where i = 1");
   $dbh2->rollback;
   $dbh2->disconnect;
   pass("passed timeout on query using odbc_query_timeout using do without bind params");
   $dbh->commit;
   $dbh->do("drop table perl_dbd_test1");
   $dbh->commit;

};

$dbh->disconnect;


exit 0;
# get rid of use once warnings
print $DBI::errstr;
print $ODBCTEST::table_name;
