#!/usr/bin/perl -w
#
# @(#)$Id: dbase.t,v 56.2 1997/06/25 20:32:57 johnl Exp $ 
#
# Copyright (C) 1997 Jonathan Leffler (johnl@informix.com)
#
# Test database creation and default connections.
# Note that database statements cannot be used with an explicit connection
# with ESQL/C 6.0x and up.

use DBD::SqlflexTest qw(stmt_ok stmt_fail stmt_note all_ok stmt_test
select_some_data);

$dbname = "dbd_ix_db";

stmt_note("1..19\n");

foreach $createdir (split(":",$ENV{'DBPATH'})) {
    if (chdir($createdir)) {
       stmt_note "#Found $createdir, and that's where I'll make my database\n";
    }
}

# Do not want these defaults to affect testing (in this file only).
delete $ENV{DBI_DSN};
delete $ENV{DBI_DBNAME};

&stmt_note("# Test (implicit default) DBI->connect('',...)\n");
stmt_fail unless ($dbh = DBI->connect('','','','Sqlflex'));
stmt_ok;

# Don't care about non-existent database
$dbh->{ix_AutoErrorReport} = 0;
$dbh->do("drop database $dbname");

$selver = "SELECT TabName, Owner FROM informix.SysTables WHERE TabName = 'systables'";

$dbh->{ix_AutoErrorReport} = 1;
&stmt_test($dbh, "create database $dbname");
&select_some_data($dbh, 1, $selver);
&stmt_test($dbh, "close database");
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

undef $dbh;

&stmt_note("# Test (explicit default) DBI->connect('.DEFAULT.',...)\n");
stmt_fail unless ($dbh = DBI->connect('.DEFAULT.','','','Sqlflex'));
stmt_ok;

$dbh->{ix_AutoErrorReport} = 1;
&stmt_test($dbh, "create database $dbname");
&select_some_data($dbh, 1, $selver);
&stmt_test($dbh, "close database");
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

# Test disconnecting implicit connections (B42204)
&stmt_note("# Test (explicit default) DBI->connect('.DEFAULT.',...)\n");
stmt_fail unless ($dbh = DBI->connect('.DEFAULT.','','','Sqlflex'));
stmt_ok;
$dbh->{ix_AutoErrorReport} = 1;
&stmt_test($dbh, "create database $dbname");
&select_some_data($dbh, 1, $selver);
&stmt_note("# Test disconnect on DEFAULT connection\n");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

# Clean up test database
&stmt_note("# Clean up test database\n");
stmt_fail unless ($dbh = DBI->connect('.DEFAULT.','','','Sqlflex'));
stmt_ok;
&stmt_test($dbh, "drop database $dbname");
stmt_fail unless ($dbh->disconnect);
stmt_ok;

&all_ok();
