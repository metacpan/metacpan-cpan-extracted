#!/usr/bin/perl
# Example script for DBIx::Report::Excel.pm module.
# See pod documentation in the module file.

use strict;
use DBIx::Report::Excel;
use DBI;
use DBD::SQLite;

my $report = DBIx::Report::Excel->new( "SQLite.xls" );

$report->dbh(DBI->connect("dbi:SQLite:dbname=/tmp/testdb","",""));


				# First worksheet has name People
				# Names and defined column aliases
				# "First Name" and "Family Name".
$report->sql(
    qq
    {
/****    ---
title: People Names
---*/
SELECT first_name as "First Name", last_name as "Family name" FROM people
    });
$report->write();

				# Examples below have optional SQL
                                # parameter for write() method.

				# Generic worksheet name Sheet2 and
                                # column names f_name, color obtained
                                # from parsing SQL.
$report->write("SELECT f_name, color from fruits");

				# Generic worksheet name Sheet3 and
				# generic column names Column1,
				# Column2.
$report->write("SELECT * from fruits");


				# Two SQL statements in one write()
				# call. Both SQL's define worksheet
				# name as YAML structure data. 1st SQL
				# - column names f_name, color. @nd
				# SQL: generic column names ColumnX.
$report->write(
    qq 
    {
/* 
---
title: Fruits
---
*/
	SELECT f_name, color from fruits;

/* 
---
title: More Fruits
---
*/
	SELECT * from fruits
    }
    );

$report->close();
