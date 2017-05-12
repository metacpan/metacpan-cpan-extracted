#!/usr/bin/perl
#
#   @(#)$Id: TestHarness.pm,v 2015.1 2015/08/26 05:26:09 jleffler Exp $
#
#   Pure Perl Test Harness for Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01)
#
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2002-03 IBM
#   Copyright 2004-15 Jonathan Leffler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

# Exploit this by saying "use DBD::Informix::TestHarness;"
{
    package DBD::Informix::TestHarness;

    use strict;
    use warnings;
    use vars qw( @ISA @EXPORT $VERSION );
    require Exporter;

    @ISA = qw(Exporter);
    @EXPORT = qw(
        all_ok
        cleanup_database
        connect_controllably
        connect_to_test_database
        connect_to_primary
        connect_to_secondary
        connect_to_tertiary
        get_date_as_string
        is_shared_memory_connection
        memory_leak_test
        primary_connection
        print_dbinfo
        print_sqlca
        smart_blob_space_name
        secondary_connection
        select_zero_data
        set_verbosity
        stmt_comment
        stmt_err
        stmt_fail
        stmt_note
        stmt_ok
        stmt_nok
        stmt_counter
        stmt_retest
        stmt_test
        stmt_skip
        test_for_ius
        tertiary_connection
        validate_unordered_unique_data
        );

    use DBI;
    use Carp;
    use Config;

    my
    $VERSION = "2015.1101";
    # our $VERSION = "2015.1101"; # But 'our' not acceptable to Perl 5.005_03!
    $VERSION = "0.97002" if ($VERSION =~ m%[:]VERSION[:]%);

    # Report on the connect command and any attributes being set.
    sub print_connection
    {
        my ($dbase, $user, $pass, $attr) = @_;
        my ($xxpass) = (defined $pass) ? 'X' x length($pass) : "";

        &stmt_note("# DBI->connect('dbi:Informix:$dbase', '$user', '$xxpass');\n");
        if (defined $attr)
        {
            my ($key);
            foreach $key (keys %$attr)
            {
                &stmt_note("#\tConnect Attribute: $key => $$attr{$key}\n");
            }
        }
    }

    sub primary_connection
    {
        # This section may need rigging for some versions of Informix.
        # It will should be OK for 6.0x and later versions of OnLine.
        # You may run into problems with SE and 5.00 systems.
        # If you do, send details to the maintenance team.
        my ($dbname) = $ENV{DBD_INFORMIX_DATABASE};
        my ($dbuser) = $ENV{DBD_INFORMIX_USERNAME};
        my ($dbpass) = $ENV{DBD_INFORMIX_PASSWORD};

        # Clear undefs
        $dbpass = "" unless ($dbpass);
        $dbuser = "" unless ($dbuser);
        # Either both username and password are set or neither are set
        $dbpass = "" unless ($dbuser && $dbpass);
        $dbuser = "" unless ($dbuser && $dbpass);

        # Respect $DBI_DBNAME since the esqltest code does.
        # Problem reported by Paul Watson <paulw@wfsoftware.com>
        $dbname = $ENV{DBI_DBNAME} if (!$dbname);
        $dbname = "stores" if (!$dbname);
        return ($dbname, $dbuser, $dbpass);
    }

    sub secondary_connection
    {
        my ($dbname) = $ENV{DBD_INFORMIX_DATABASE2};
        my ($dbuser) = $ENV{DBD_INFORMIX_USERNAME2};
        my ($dbpass) = $ENV{DBD_INFORMIX_PASSWORD2};

        if (!defined $dbname || !defined $dbuser || !defined $dbpass)
        {
            my ($dbname1, $dbuser1, $dbpass1) = &primary_connection();
            $dbname = $dbname1 unless defined $dbname;
            $dbuser = $dbuser1 unless defined $dbuser;
            $dbpass = $dbpass1 unless defined $dbpass;
        }

        # Clear undefs
        $dbpass = "" unless ($dbpass);
        $dbuser = "" unless ($dbuser);
        # Either both username and password are set or neither are set
        $dbpass = "" unless ($dbuser && $dbpass);
        $dbuser = "" unless ($dbuser && $dbpass);

        return ($dbname, $dbuser, $dbpass);
    }

    sub tertiary_connection
    {
        my ($dbname) = $ENV{DBD_INFORMIX_DATABASE3};
        my ($dbuser) = $ENV{DBD_INFORMIX_USERNAME3};
        my ($dbpass) = $ENV{DBD_INFORMIX_PASSWORD3};

        if (!defined $dbname || !defined $dbuser || !defined $dbpass)
        {
            my ($dbname1, $dbuser1, $dbpass1) = &primary_connection();
            $dbname = $dbname1 unless defined $dbname;
            $dbuser = $dbuser1 unless defined $dbuser;
            $dbpass = $dbpass1 unless defined $dbpass;
        }

        # Clear undefs
        $dbpass = "" unless ($dbpass);
        $dbuser = "" unless ($dbuser);
        # Either both username and password are set or neither are set
        $dbpass = "" unless ($dbuser && $dbpass);
        $dbuser = "" unless ($dbuser && $dbpass);

        return ($dbname, $dbuser, $dbpass);
    }

    sub connect_to_test_database
    {
        my ($attr) = @_;
        connect_to_primary(1, $attr);
    }

    sub connect_to_primary
    {
        my ($verbose, $attr) = @_;
        connect_controllably($verbose, $attr, \&primary_connection);
    }

    sub connect_to_secondary
    {
        my ($verbose, $attr) = @_;
        connect_controllably($verbose, $attr, \&secondary_connection);
    }

    sub connect_to_tertiary
    {
        my ($verbose, $attr) = @_;
        connect_controllably($verbose, $attr, \&tertiary_connection);
    }

    sub connect_controllably
    {
        my ($verbose, $attr, $func) = @_;
        my ($dbname, $dbuser, $dbpass) = &$func();

        # Chop trailing blanks by default, unless user explicitly chooses otherwise.
        ${$attr}{ChopBlanks} = 1 unless defined ${$attr}{ChopBlanks};
        &print_connection($dbname, $dbuser, $dbpass, $attr)
            if ($verbose);

        my ($dbh) = DBI->connect("dbi:Informix:$dbname", $dbuser, $dbpass, $attr);

        # Unconditionally fail if connection does not work!
        &stmt_fail() unless (defined $dbh);

        $dbh;
    }

    # Get both client-side and server-side
    # result of evaluating a date as a string.
    sub get_date_as_string
    {
        my ($dbh, $mm, $dd, $yyyy) = @_;
        my ($sth, $sel1, @row);

        $dd = 10 unless defined $dd;
        $mm = 20 unless defined $mm;
        $yyyy = 1930 unless defined $yyyy;
        # How to insert date values even when you cannot be bothered to sort out
        # what DBDATE will do...  You cannot insert an MDY() expression directly.
        # JL 2002-11-05: String concatenation is available in all supported
        # servers.  The date value has to be returned as string; otherwise,
        # you run into problems when the server has DBDATE set to a
        # non-default value (such as "Y4MD-") and the client side does not
        # set DBDATE at all.  This problem reported previously by others,
        # but this fix introduced in response to questions from Arlene
        # Gelbolingo <Gelbolingo.Arlene@menlolog.com>.  Note that the
        # string returned by default is unambiguous.
        $sel1 = qq% SELECT MDY($mm,$dd,$yyyy) || '', MDY($mm,$dd,$yyyy) FROM "informix".SysTables WHERE Tabid = 1%;
        (&stmt_nok(), return "$yyyy-$mm-$dd") unless $sth = $dbh->prepare($sel1);
        (&stmt_nok(), return "$yyyy-$mm-$dd") unless $sth->execute;
        (&stmt_nok(), return "$yyyy-$mm-$dd") unless @row = $sth->fetchrow_array;
        (&stmt_nok(), return "$yyyy-$mm-$dd") unless $sth->finish;
        &stmt_ok(0);
        return @row;
    }

    sub print_dbinfo
    {
        my ($dbh) = @_;
        print  "# Database Information\n";
        printf "#     Database Name:           %s\n", $dbh->{Name};
        printf "#     DBMS Version:            %d\n", $dbh->{ix_ServerVersion};
        printf "#     AutoCommit:              %d\n", $dbh->{AutoCommit};
        printf "#     PrintError:              %d\n", $dbh->{PrintError};
        printf "#     RaiseError:              %d\n", $dbh->{RaiseError};
        printf "#     Informix-OnLine:         %d\n", $dbh->{ix_InformixOnLine};
        printf "#     Logged Database:         %d\n", $dbh->{ix_LoggedDatabase};
        printf "#     Mode ANSI Database:      %d\n", $dbh->{ix_ModeAnsiDatabase};
        printf "#     Transaction Active:      %d\n", $dbh->{ix_InTransaction};
        print  "#\n";
    }

    sub print_sqlca
    {
        my ($sth) = @_;
        print "# Testing SQLCA handling\n";
        print "#     SQLCA.SQLCODE    = $sth->{ix_sqlcode}\n";
        print "#     SQLCA.SQLERRM    = '$sth->{ix_sqlerrm}'\n";
        print "#     SQLCA.SQLERRP    = '$sth->{ix_sqlerrp}'\n";
        my ($i) = 0;
        my @errd = @{$sth->{ix_sqlerrd}};
        for ($i = 0; $i < @errd; $i++)
        {
            print "#     SQLCA.SQLERRD[$i] = $errd[$i]\n";
        }
        my @warn = @{$sth->{ix_sqlwarn}};
        for ($i = 0; $i < @warn; $i++)
        {
            print "#     SQLCA.SQLWARN[$i] = '$warn[$i]'\n";
        }
        print "# SQLSTATE             = '$DBI::state'\n";
        my ($rows) = $sth->rows();
        print "# ROWS                 = $rows\n";
    }

    my $test_counter = 0;
    my $fail_counter = 0;

    sub stmt_err
    {
        # NB: error message in $DBI::errstr no longer ends with a newline.
        my ($str) = @_;
        my ($err, $state);
        $str = "Error Message" unless ($str);
        $err = (defined $DBI::errstr) ? $DBI::errstr : "<<no error string>>";
        $state = (defined $DBI::state) ? $DBI::state : "<<no state string>>";
        $str .= ":\n${err}\nSQLSTATE = ${state}\n";
        $str =~ s/^/# /gm;
        &stmt_note($str);
    }

    sub stmt_skip
    {
        my ($reason) = @_;
        $test_counter++;
        &stmt_note("ok $test_counter # $reason\n");
    }

    sub stmt_ok
    {
        my ($warn) = @_;
        $test_counter++;
        &stmt_note("ok $test_counter\n");
        &stmt_err("Warning Message") if ($warn);
    }

    sub stmt_nok
    {
        my ($warn) = @_;
        &stmt_note($warn) if ($warn);
        $test_counter++;
        $fail_counter++;
        &stmt_note("not ok $test_counter\n");
    }

    sub stmt_fail
    {
        my ($warn) = @_;
        &stmt_nok($warn);
        &stmt_err("Error Message");
        confess "!! Terminating Test !!\n";
    }

    sub stmt_counter
    {
        return $test_counter;
    }

    sub all_ok
    {
        &stmt_note("# *** Testing of DBD::Informix complete ***\n");
        if ($fail_counter == 0)
        {
            &stmt_note("# ***     You appear to be normal!      ***\n");
            exit(0);
        }
        else
        {
            &stmt_note("# !!!!!! There appear to be problems !!!!!!\n");
            exit(1);
        }
    }

    sub stmt_comment
    {
        my($str) = @_;
        $str =~ s/^[^#]/# $&/gmo;
        $str =~ s/^$/#/gmo;
        chomp $str;
        stmt_note("$str\n");
    }

    sub stmt_note
    {
        print STDOUT @_;
    }

    sub stmt_test
    {
        my ($dbh, $stmt, $ok, $test) = @_;
        $test = "Test" unless $test;
        &stmt_comment("$test: do('$stmt'):\n");
        if ($dbh->do($stmt)) { &stmt_ok(0); }
        elsif ($ok)          { &stmt_ok(1); }
        else                 { &stmt_nok(); }
    }

    sub stmt_retest
    {
        my ($dbh, $stmt, $ok) = @_;
        &stmt_test($dbh, $stmt, $ok, "Retest");
    }

    # Check that there is no data
    sub select_zero_data
    {
        my($dbh, $sql) = @_;
        my($sth) = $dbh->prepare($sql);
        (&stmt_nok, return) unless $sth;
        (&stmt_nok, return) unless $sth->execute;
        my $ref;
        while ($ref = $sth->fetchrow_arrayref)
        {
            # No data should have been selected!
            &stmt_nok("Unexpected data returned from $sql: @$ref\n");
            return;
        }
        &stmt_ok;
    }

    # Check that both the ESQL/C and the database server are IUS-aware
    # Handles ESQL/C 2.90 .. 4.99 - which are IUS-aware.
    # Return database handle if all is OK.
    sub test_for_ius
    {
        my ($dbase1, $user1, $pass1) = &primary_connection();

        my $drh = DBI->install_driver('Informix');
        print "# Driver Information\n";
        print "#     Name:                  $drh->{Name}\n";
        print "#     Version:               $drh->{Version}\n";
        print "#     Product:               $drh->{ix_ProductName}\n";
        print "#     Product Version:       $drh->{ix_ProductVersion}\n";
        my ($ev) = $drh->{ix_ProductVersion};
        if ($ev < 900 && !($ev >= 290 && $ev < 500))
        {
            &stmt_note("1..0 # Skip: IUS data types are not supported by $drh->{ix_ProductName}\n");
            exit(0);
        }

        my ($dbh, $sth, $numtabs);
        &stmt_note("# Connect to: $dbase1\n");
        &stmt_fail() unless ($dbh = DBI->connect("DBI:Informix:$dbase1", $user1, $pass1));
        &stmt_fail() unless ($sth = $dbh->prepare(q%
            SELECT COUNT(*) FROM "informix".SysTables WHERE TabID < 100
            %));
        &stmt_fail() unless ($sth->execute);
        &stmt_fail() unless (($numtabs) = $sth->fetchrow_array);
        if ($numtabs < 40)
        {
            &stmt_note("1..0 # Skip IUS data types are not supported by database server.\n");
            $dbh->disconnect;
            exit(0);
        }
        &stmt_note("# IUS data types can be tested!\n");
        return $dbh;
    }

    # Remove test debris created by DBD::Informix tests
    sub cleanup_database
    {
        my ($dbh) = @_;
        my ($old_p) = $dbh->{PrintError};
        my ($old_r) = $dbh->{RaiseError};
        my ($type);
        my ($sth);

        # Do not report any errors.
        $dbh->{PrintError} = 0;
        $dbh->{RaiseError} = 0;

        # Clean up synonyms (private and public), views, and base tables.
        my(%map) = ('P' => 'SYNONYM', 'S' => 'SYNONYM', 'V' => 'VIEW', 'T' => 'TABLE');
        foreach $type ('P', 'S', 'V', 'T')  # Private synonyms, public synonyms, views, tables.
        {
            my $kw = $map{$type};
            $sth = $dbh->prepare(qq%SELECT owner, tabname FROM "informix".systables WHERE tabname MATCHES  'dbd_ix_*' AND tabtype = '$type'%);
            $sth->execute;
            my($owner, $name);
            $sth->bind_col(1, \$owner);
            $sth->bind_col(2, \$name);
            while ($sth->fetchrow_array)
            {
                my($sql) = qq%DROP $kw "$owner".$name%;
                &stmt_note("# $sql\n");
                $dbh->do($sql);
            }
        }

        # Clean up stored procedures.
        $sth = $dbh->prepare(q%SELECT owner, procname FROM "informix".sysprocedures WHERE name MATCHES 'dbd_ix_*'%);
        if ($sth)
        {
            $sth->execute;
            my($owner, $name);
            $sth->bind_col(1, \$owner);
            $sth->bind_col(2, \$name);
            while ($sth->fetchrow_array)
            {
                my($sql) = qq%DROP PROCEDURE "$owner".$name%;
                &stmt_note("# $sql\n");
                $dbh->do($sql);
            }
        }

        # Clean up IUS types debris!
        $sth = $dbh->prepare(q%SELECT mode, owner, name FROM "informix".sysxtdtypes WHERE name MATCHES 'dbd_ix_*'%);
        if ($sth)
        {
            $sth->execute;
            my($mode, $owner, $name);
            $sth->bind_col(1, \$mode);
            $sth->bind_col(2, \$owner);
            $sth->bind_col(3, \$name);
            while ($sth->fetchrow_array)
            {
                my($sql);
                $sql = qq%DROP ROW TYPE "$owner".$name RESTRICT%
                    if ($mode eq "R");  # ROW types (to point out the obvious)
                $sql = qq%DROP     TYPE "$owner".$name RESTRICT%
                    if ($mode eq "D");  # DISTINCT types
                &stmt_note("# $sql\n");
                $dbh->do($sql);
            }
        }

        # Reinstate original error handling
        $dbh->{PrintError} = $old_p;
        $dbh->{RaiseError} = $old_r;
        1;
    }

    # Verify whether specified database name will use a shared memory connection.
    # AFAIK, NT does not support shared memory connections.
    # The use of grep (the Unix command) probably renders this worthless on NT.
    # Obviously, if it became desirable, we could write a grep-like function in
    # Perl (but beware the built-in grep which is different).
    # NB: Error checking is minimal and assumes that esqltest at least ran OK.
    sub is_shared_memory_connection
    {
        return 0 if $Config{archname} =~ /MSWin32/;
        my($dbs) = @_;
        my ($server) = $dbs;
        if ($dbs !~ /.*@/)
        {
            my ($ixsrvr) = $ENV{INFORMIXSERVER};
            $ixsrvr = 'unknown server name' unless $ixsrvr;
            $server = "$dbs\@$ixsrvr";
        }
        $server =~ s/.*@//;
        my($sqlhosts) = $ENV{INFORMIXSQLHOSTS};
        $sqlhosts = "$ENV{INFORMIXDIR}/etc/sqlhosts" unless $sqlhosts;
        # Implications for NT?
        my($ent) = qx(grep "^$server\[  ][  ]*" $sqlhosts 2>/dev/null);
        $ent = 'server protocol host service' unless $ent;
        my(@ent) = split ' ', $ent;
        return (($ent[1] =~ /o[ln]ipcshm/) ? 1 : 0);
    }

    # Run a memory leak test.
    # The main program will normally read:
    #       use strict;
    #       use DBD::Informix::TestHarness;
    #       &memory_leak_test(\&test_subroutine);
    #       exit;
    # The remaining code in the test file will implement a test
    # which shows the memory leak.  You should not connect to the
    # test database before invoking memory_leak_test.
    sub memory_leak_test
    {
        my($sub, $nap, $pscmd) = @_;
        use vars qw($ppid $cpid $nap);

        $|=1;
        print "# Bug is fixed if size of process stabilizes (fairly quickly!)\n";
        $ppid = $$;
        $nap  = 5 unless defined $nap;
        $pscmd = "ps -lp" unless defined $pscmd;
        $pscmd .= " $ppid";

        $cpid = fork();
        die "failed to fork\n" unless (defined $cpid);
        if ($cpid)
        {
            # Parent
            print "# Parent: $ppid, Child: $cpid\n";
            # Invoke the subroutine given by reference to do the real database work.
            &$sub();
            # Try to ensure that the child gets a chance to report at least once more...
            sleep ($nap * 2);
            kill 15, $cpid;
            exit(0);
        }
        else
        {
            # Child -- monitor size of parent, while parent exists!
            system "$pscmd | sed 's/^/# /'";
            sleep $nap;
            while (kill 0, $ppid)
            {
                system "$pscmd | sed -e 1d -e 's/^/# /'";
                sleep $nap;
            }
        }
    }

    # Valid values for $DBD::Informix::TestHarness::verbose are:
    #   0 -> don't say anything
    #   1 -> overall status for each row
    #   2 -> field-by-field detailed commentary
    # Note that errors are always reported.
    # our $verbose = 0; # But 'our' not acceptable to Perl 5.005_03!
    my $verbose = 0;
    sub set_verbosity
    {
        $verbose = $_[0];
    }

    sub smart_blob_space_name
    {
        my ($dbh) = @_;
        my ($sbspace) = "";

        if ($dbh->{ix_ServerVersion} < 900)
        {
            stmt_note "# No Smart BLOB testing because server version too old\n";
        }
        elsif ($ENV{DBD_INFORMIX_NO_SBSPACE})
        {
            stmt_note "# No Smart BLOB testing because \$DBD_INFORMIX_NO_SBSPACE set.\n";
        }
        else
        {
            # RT#14954: Only do smart blob testing if DBD_INFORMIX_SBSPACE is set.
            # Better - check whether there is an sbspace of the given name.
            # sysmaster:"informix".sysdbspaces has (relevant) columns name and is_sbspace.
            $sbspace = $ENV{DBD_INFORMIX_SBSPACE};
            $sbspace = "sbspace" unless $sbspace;
            my $sql = 'select name from sysmaster:"informix".sysdbspaces where name = ? and is_sbspace = 1';
            my $ore = $dbh->{RaiseError};
            my $ope = $dbh->{PrintError};
            $dbh->{RaiseError} = 0;
            $dbh->{PrintError} = 1;
            my $sth = $dbh->prepare($sql);
            $dbh->{RaiseError} = $ore;
            $dbh->{PrintError} = $ope;
            return "" if (!$sth);
            $sth->execute($sbspace);
            my @arr;
            my $ok = 0;
            while (@arr = $sth->fetchrow_array)
            {
                $ok = 1;
                last;
            }
            if ($ok)
            {
                stmt_note "# Smart BLOB testing using smart blob space '$sbspace'\n";
            }
            else
            {
                stmt_note "# No Smart BLOB testing - can't find smart blob space '$sbspace'\n";
                stmt_note "# Check value of \$DBD_INFORMIX_SBSPACE - or set it\n";
                $sbspace = "";
            }
        }
        return $sbspace;
    }

    # Validate that the data returned from the database is correct.
    # Assume each row in result set is supposed to appear exactly once.
    # Extra results are erroneous; missing results are erroneous.
    # The results from fetchrow_hashref() must be unambiguous.
    # The key data must be a single column.
    # The data in $val is a hash indexed by the key value containing the
    # expected values for each column corresponding to the key value:-
    # &validate_unordered_unique_data($sth, 'c1',
    # {
    #   'c1-value1' => { 'c1' => 'c1-value1', 'c2' => 'c2-value1', 'c3' => 'c3-value1' },
    #   'c1-value2' => { 'c1' => 'c1-value1', 'c2' => 'c2-value2', 'c3' => 'c3-value2' },
    # });
    # Note that the key (c1) and expected value (c1-value1) are repeated;
    # this is a test consistency check.

    sub validate_unordered_unique_data
    {
        my($sth, $key, $val) = @_;
        my(%values) = %$val;
        my($numexp) = 0;

        # Validate expected values array!
        foreach my $col (sort keys %values)
        {
            my(%columns) = %{$values{$col}};
            printf "# Key: %-20s = %s\n", "$key:", $col if $verbose >= 2;
            stmt_fail "### TEST ERROR: key column not in expected data: $key = $col\n"
                if !defined $columns{$key};
            stmt_fail "### TEST ERROR: inconsistent expected data: $key = $col and $key = $columns{$key}\n"
                if $col ne $columns{$key};
            foreach my $col (sort keys %columns)
            {
                printf "#      %-20s = %s\n", "$col:", $columns{$col} if $verbose >= 2;
            }
            $numexp++;
        }

        # Collect the data
        my ($ref);
        my (%state) = ('fail' => 0, 'pass' => 0, 'xtra' => 0, 'miss' => 0);
        my $rownum = 0;
        while ($ref = $sth->fetchrow_hashref)
        {
            $rownum++;
            my %row = %{$ref};
            if (defined $row{$key} && defined $values{$row{$key}})
            {
                my $pass = 0;
                my $fail = 0;
                my %expect = %{$values{$row{$key}}};

                # Verify that each returned column has the expected value.
                foreach my $col (keys %row)
                {
                    my($got, $want) = ($row{$col}, $expect{$col});
                    if (defined $got && defined $want)
                    {
                        if ($got ne $want)
                        {
                            print "# Row $rownum: Got unexpected value <<$got>> for $col (key value = $row{$key}) when <<$want>> expected!\n";
                            $fail++;
                        }
                        else
                        {
                            print "# Row $rownum: Got expected value $got for $col (key value = $row{$key})\n" if ($verbose >= 2);
                            $pass++;
                        }
                    }
                    elsif (!defined $got && !defined $want)
                    {
                        # Both values NULL - OK.
                        print "# Row $rownum: Got NULL which was wanted for $col\n" if ($verbose >= 2);
                        $pass++;
                    }
                    elsif (!defined $got)
                    {
                        print "# Row $rownum: Got NULL for $col (key value = $row{$key}) when $want expected!\n";
                        $fail++;
                    }
                    else
                    {
                        print "# Row $rownum: Got $got for $col (key value = $row{$key}) when NULL expected!\n";
                        $fail++;
                    }
                }

                # Verify that each expected value is returned.
                foreach my $col (keys %expect)
                {
                    my($got, $want) = ($row{$col}, $expect{$col});
                    next if (defined $got && defined $want);    # Errors already reported
                    next if (!defined $got && !defined $want);
                    if (!defined $got)
                    {
                        print "# Row $rownum: Did not get result for $col (key value = $row{$key}) when $want expected!\n";
                        $fail++;
                    }
                    # The 'else' clause "cannot happen".
                }

                if ($pass > 0 && $fail == 0)
                {
                    $state{pass}++;
                    print "# Row $rownum: PASS\n" if ($verbose >= 1);
                    delete $values{$row{$key}};
                }
                else
                {
                    $state{fail}++;
                    print "# Row $rownum: FAIL (erroneous content)\n" if ($verbose >= 1);
                    # Since the key was found (hence $ok > 0), it is OK to undef this row.
                    delete $values{$row{$key}} if $pass > 0;
                }
            }
            else
            {
                print "# Row $rownum: Got unexpected row of data!\n";
                foreach my $col (sort keys %row)
                {
                    printf "#     %-20s = %s\n", "$col:", $row{$col};
                }
                $state{xtra}++;
                print "# Row $rownum: FAIL (unexpected key value)\n" if ($verbose >= 1);
            }
        }

        # Verify that entire expected hash was consumed.
        foreach my $val (sort keys %values)
        {
            print "# Did not get a row corresponding to expected key $val\n";
            $state{miss}++;
        }

        # Determine whether test passed or failed overall.
        if ($state{fail} == 0 && $state{miss} == 0 && $state{xtra} == 0 && $state{pass} == $numexp)
        {
            stmt_note "# PASSED: $state{pass} row(s) found with expected values\n";
            stmt_ok;
        }
        else
        {
            my($msg) = "# FAILED";
            $msg .= ": $state{pass} rows were correct";
            $msg .= "; $state{fail} rows had faulty data" if ($state{fail} != 0);
            $msg .= "; $state{miss} rows did not get selected" if ($state{miss} != 0);
            $msg .= "; $state{xtra} rows were selected unexpectedly" if ($state{xtra} != 0);
            stmt_nok "$msg\n";
        }
    }

    1;
}

__END__

=head1 NAME

DBD::Informix::TestHarness - Test Harness for DBD::Informix

=head1 SYNOPSIS

  use DBD::Informix::TestHarness;

=head1 DESCRIPTION

This document describes DBD::Informix::TestHarness distributed with
Informix Database Driver for Perl DBI Version 2015.1101 (2015-11-01).
This is pure Perl code which exploits DBI and DBD::Informix to make it
easier to write tests.
Most notably, it provides a simple mechanism to connect to the user's
chosen test database and a uniform set of reporting mechanisms.

=head2 Loading DBD::Informix::TestHarness

To use the DBD::Informix::TestHarness software, you need to load the DBI
software and then install the Informix driver:

    use DBD::Informix::TestHarness;

=head2 Connecting to test database

    $dbh = &connect_to_test_database({ AutoCommit => 0 });

This gives you a reference to the database connection handle, aka the
database handle.
If the load fails, your program stops immediately.
The functionality available from this handle is documented in the
DBD::Informix manual page.
This function does not report success when it succeeds because the
test scripts for blobs, for example, need to know whether they are
working with an OnLine system before reporting how many tests will be
run.

This code exploits 3 environment variables:

    DBD_INFORMIX_DATABASE
    DBD_INFORMIX_USERNAME
    DBD_INFORMIX_PASSWORD

The database variable can be simply the name of the database, or it
can be 'database@server', or it can be one of the SE notations such
as '/opt/dbase' or '//hostname/dbase'.
If INFORMIXSERVER is not set, then you had better be on a 5.0x
system as otherwise the connection will fail.
With 6.00 and above, you can optionally specify a user name and
password in the environment.
This is horribly insecure -- do not use it for production work.
The test scripts do not print the password.

=head2 Using connect_to_primary

The method connect_to_primary takes a flag (0 implies quietly, 1 implies noisily)
and a set of attributes, and connects to the primary database.

    $dbh = &connect_to_primary(1, { AutoCommit => 0 });

=head2 Using connect_to_secondary

The method connect_to_secondary takes a flag (0 implies quietly, 1 implies noisily)
and a set of attributes, and connects to the secondary database.

    $dbh = &connect_to_secondary(1, { AutoCommit => 0 });

=head2 Using connect_to_tertiary

The method connect_to_tertiary takes a flag (0 implies quietly, 1 implies noisily)
and a set of attributes, and connects to the tertiary database.

    $dbh = &connect_to_tertiary(1, { AutoCommit => 0 });

=head2 Using cleanup_database

If the test needs a clean database to work with, the cleanup_database
method removes any tables, views, synonyms (or IUS types) created by the
DBD::Informix test suite.
These are all identified by the 'dbd_ix_' prefix.

    &cleanup_database($dbh);

This is not used in all tests by any stretch of the imagination.
In fact, the only test to use it routinely is t/t99clean.t.
Whereever possible, tests should use temporary tables.

=head2 Using test_for_ius

If the test explicitly requires Informix Universal Server (IUS)
or IDS/UDO (Informix Dynamic Server with Universal Data Option --
essentially the product as IUS, but with a longer, more recent,
name), then the mechanism to use is:

    my ($dbh) = &test_for_ius();

If this returns, then the ESQL/C is capable of handling IUS data
types, the database connection worked, and the database server is
capable of handling IUS data types.

=head2 Using is_shared_memory_connection

You cannot have multiple simultaneous connections if both connections
use shared memory connectivity.
The multiple connection tests try to determine whether both test databases
have shared memory connections.
This Unix-centric test provides such a test and allows the tests to report that
'skipping test on this platform'.

    if (&is_shared_memory_connection($dbase1)) { ... }

=head2 Using stmt_test

Once you have a database connection, you can execute simple statements (those
which do not return any data) using &stmt_test():

    &stmt_test($dbh, $stmt, $flag, $tag);

The first argument is the database handle.  The second is a string
containing the statement to be executed.  The third is optional and is a
boolean.  If it is 0, then the statement must execute without causing an
error or the test will terminate.  If it is set to 1, then the statement
may fail and the error will be reported but the test will continue.  The
fourth argument is an optional string which will be used as a tag before
the statement when it is printed.  If omitted, it defaults to "Test".

=head2 Using stmt_retest

The &stmt_retest() function takes three arguments, which have the same meaning
as the first three arguments of &stmt_test():

    &stmt_retest($dbh, $stmt, $flag);

It calls:

    &stmt_test($dbh, $stmt, 0, "Retest");

=head2 Using print_sqlca

The &print_sqlca() function takes a single argument which can be either a
statement handle or a database handle and prints out the current values of
the SQLCA record.

    &print_sqlca($dbh);
    &print_sqlca($sth);

=head2 Using print_dbinfo

The &print_dbinfo() function takes a single argument which should be a database
handle and prints out salient information about the database.

    &print_dbinfo($dbh);

=head2 Using all_ok

The &all_ok() function can be used at the end of a test script to report
whether everything was OK.
It exits with status 0 if everything was OK, and with status 1 if not.

    &all_ok();

=head2 Using stmt_counter

This function returns the current test counter (without altering it).
It is most frequently used when the number of tests cannot be told in advance.

    $n = &stmt_counter;

=head2 Using stmt_ok

The C<stmt_ok> function adds 'ok N' to the end of a line.
The N increments automatically each time C<stmt_ok>() or C<stmt_nok>()
is called.
If called with a non-false argument, it prints the contents of
DBI::errstr as a warning message too.
This routine is used both internally and more generally in the tests.

    &stmt_ok(0);

=head2 Using stmt_nok

The C<stmt_nok> function adds 'not ok N' to the end of a line.
The N is incremented automatically, as with C<stmt_ok>().
This routine is used both internally and more generally in the tests.
It takes an optional string as an argument, which is printed as well.

    &stmt_nok();
    &stmt_nok("Reason why test failed");

=head2 Using stmt_fail

This routine calls C<stmt_nok>, reports the error using C<stmt_err>, and
confesses where the failure occurs as it dies.
This routine is used (too) extensively, both internally and in the main
test scripts.
It takes an optional string as an argument, which is printed as well.

    &stmt_fail();
    &stmt_fail("Reason why test failed");

Note that because this terminates the test abrubtly, it means that all
subsequent tests after the one that really failed are deemed to fail.
This is often sensible because the subsequent tests depend on the
current test to succeed and it is not possible to get good results if
this test fails.
Nevertheless, whereever possible, the test script should continue after
a failure.

=head2 Using stmt_err

This routines prints a caption (defaulting to 'Error Message') and the
contents of DBI::errstr, ensuring that each line is prefixed by "# ".
This routine is used internally by the DBD::Informix::TestHarness module, but is
also available for your use.

    &stmt_err('Warning Message');

=head2 Using stmt_skip

This routine writes an 'ok' test result followed by a '#' and the text
supplied as its argument.
Note that it appends a newline to the given string.
It is used to indicate that a test was skipped.

    &stmt_skip("reason why test was skipped");

=head2 Using stmt_note

This routine writes a string (without any newline unless you include it).
This routine is used internally by stmt_test() but is also available for
your use.

    &stmt_note("Some string or other");

=head2 Using stmt_comment

This routine writes a string (prepending hash symbols to line and
appending a newline if necessary).
This routine is used internally by stmt_test() but is also available
for your use.

    &stmt_comment("Some string or other");

=head2 Using get_date_as_string

This routine takes one to four arguments:

    my($ssdt, $csdt) = &get_date_as_string($dbh [, $mm [, $dd [, $yyyy]]]);

The first argument is the database handle.
The optional second argument is the month number (1..12).
The optional third argument is the day number (1..31).
The optional fourth argument is the year number (1..9999).
If the date values are omitted, then values from 1930-10-20 are
substituted.
No direct validation is done; if the conversion operations fail,
stmt_fail is called.
The date value is converted to a string by the database server, and the
result returned to the calling function.

Each invocation of C<get_date_as_string> generates one test to be counted.

This function returns an array containing two elements.
The server-side string is returned as element 0, and the client-side
string as element 1.

The server-side string can be enclosed in quotes and will then be
accepted by the server as a valid date in an SQL statement.

The client-side string can be used to define expected values when the
database returns the given date as a DATE value.

Note: the code assumes that the database server supports the '||' string
concatenation operator; this is valid for OnLine 5.00 and above, and
DBD::Informix does not support earlier server versions, so it should
work everywhere that DBD::Informix works.

=head2 Using select_zero_data

The C<select_zero_data> function takes a database handle and the text of
a SELECT statement and ensures that no data is returned.
The test passes unless any data is returned.

    &select_zero_data($dbh, $stmt);

=head2 Using memory_leak_test

This routine takes a reference to a subroutine, and optionally a nap
time in seconds (default 5) and a C<ps> command string (default "ps
-lp", suitable for Solaris 2.x and Solaris 7).

Normally, your test script will simply call this routine and exit.
The remaining code in the test file will implement a test which shows
the memory leak.
You should not connect to the test database before invoking
memory_leak_test.

    use strict;
    use DBD::Informix::TestHarness;
    &memory_leak_test(\&test_subroutine);
    exit;

When it is called, memory_leak_test forks, and the parent process runs
the given subroutine with no arguments.
The subroutine will do the sequence of database operations which show
that there is a memory leak, or that the memory leak is fixed.
The child process checks that the parent is still alive, and runs the
C<ps> command to determine the size of the process.
The output of C<ps> is not parsed, so you have to run the test in a
verbose mode to see whether there is a memory leak or not.

    &memory_leak_test(\&test_subroutine);
    &memory_leak_test(\&test_subroutine, 10, "ps -l | grep");

The C<ps> command string has a process number appended to the end
after a space, and should report the size of the given process.
Note that the last example is not as reliable as requesting the
process status of a specific process number; it will probably show the
grep command and the child Perl process, and maybe random other
processes.

=head2 Using connect_controllably

The C<connect_controllably> function is primarily used by the explicit
C<connect_to_primary>, C<connect_to_secondary>, C<connect_to_tertiary>,
functions, but is also used in its own right.

    $dbh = connect_controllably(1, {PrintError=>1}, \&tertiary_connection);

It takes 3 arguments: a verbose flag (true or false), a reference to the
connection attributes, if any, and a reference to a function such as
C<primary_connection> which returns a database name, username and
password.
It uses these to connect to the database, logs the connection as a
successful test (or dies completely), and returns the database handle.

=head2 Using primary_connection

The primary_connection function returns three values, the database
name, the username and the password for the primary test connection.
This is used internally by the connect_controllably function, and
hence by the connect_to_test_database function.

    my ($dbase, $user, $pass) = &primary_connection();
    my ($dbh) = DBI->connect("dbi:Informix:$dbase", $user, $pass)
                    or die "$DBI::errstr\n";

In looking for the three values, it examines the environment variables
DBD_INFORMIX_DATABASE, DBD_INFORMIX_USERNAME and
DBD_INFORMIX_PASSWORD.
If the database is not determined, it looks at the DBI_DBNAME
environment variable (which is essentially obsolete as far as DBI is
concerned, but which is documented by the esqltest code -- an
alternative was to remove support for DBI_DBNAME from esqltest.ec).
If DBI_DBNAME is not set, then the default database name is 'stores'
with no version suffix.
If the username and password are not set, then empty strings are
returned.

=head2 Using secondary_connection

The secondary_connection function also returns three values, the
database name, the username and the password for the secondary test
connection.
This is used in the multiple connection tests.

    my ($dbase, $user, $pass) = &secondary_connection();
    my ($dbh) = DBI->connect("dbi:Informix:$dbase", $user, $pass)
                    or die "$DBI::errstr\n";

In looking for the three values, it examines the environment variables
DBD_INFORMIX_DATABASE2, DBD_INFORMIX_USERNAME2 and
DBD_INFORMIX_PASSWORD2.
If the database is not determined, it uses the primary_connection
method above to specify the values.

=head2 Using tertiary_connection

The C<tertiary_connection> function also returns three values, the
database name, the username and the password for the tertiary test
connection.
This is used in the multiple connection tests.

    my ($dbase, $user, $pass) = &tertiary_connection();
    my ($dbh) = DBI->connect("dbi:Informix:$dbase", $user, $pass)
                    or die "$DBI::errstr\n";

In looking for the three values, it examines the environment variables
DBD_INFORMIX_DATABASE3, DBD_INFORMIX_USERNAME3 and
DBD_INFORMIX_PASSWORD3.
If the database is not determined, it uses the primary_connection
method above to specify the values.

=head2 Using smart_blob_space_name

The C<smart_blob_space_name> function is used to determine the name of a
smart blob space that the program should use.
It takes a database handle, and uses the environment variables
DBD_INFORMIX_NO_SBSPACE and DBD_INFORMIX_SBSPACE to determine whether
smart blobs should be tested.

The return value is either an empty string (do not test smart blobs) or
the name of a valid smart blob space.

=head2 Using validate_unordered_unique_data

The C<validate_unordered_unique_data> function is used to ensure that
exactly the correct data is returned from a cursor-like statement handle
which has already had the $sth->execute method executed on it.

The data in $val is a hash indexed by the key value containing the
expected values for each column corresponding to the key value:-

    &validate_unordered_unique_data($sth, $keycol, \%expected);

    &validate_unordered_unique_data($sth, 'c1',
        {
            'c1-value1' => { 'c1' => 'c1-value1', 'c2' => 'c2-value1', 'c3' => 'c3-value1' },
            'c1-value2' => { 'c1' => 'c1-value1', 'c2' => 'c2-value2', 'c3' => 'c3-value2' },
        });

Note that the key (c1) and expected value (c1-value1) are repeated in
the data for each row; this is a consistency check that the function enforces.

This function assumes that each row in result set is supposed to appear
exactly once.
Any extra result rows are erroneous; any missing result rows are
erroneous.
Any missing columns are erroneous; any extra columns are erroneous.
The results from C<fetchrow_hashref>() must be unambiguous, meaning that
each selected column must have a unique name.
The key data must be a single column.

This routine (or its hypothetical relatives such as
C<validate_ordered_unique_data>, C<validate_unordered_duplicate_data>,
and C<validate_ordered_duplicate_data>) should be used to ensure that
the correct results are returned.  Note that there might not be any need
for separate routine for unique and duplicate ordered data.

=head2 Using set_verbosity

The C<set_verbosity> function takes a value 0, 1 or 2 and sets the
verbosity of the validate_* functions accordingly.

    &set_verbosity(0);

=head2 Note

All these routines can also be used without parentheses or the &, so that
the following is also valid:

    select_zero_data $dbh, $stmt;

=head1 AUTHOR

At various times:

=over 2

=item *
Jonathan Leffler (johnl@informix.com) # obsolete email address

=item *
Jonathan Leffler (j.leffler@acm.org)

=item *
Jonathan Leffler (jleffler@informix.com) # obsolete email address

=item *
Jonathan Leffler (jleffler@us.ibm.com)

=item *
Jonathan Leffler (jleffler@google.com)

=back

=head1 SEE ALSO

perl(1), DBD::Informix

=cut
