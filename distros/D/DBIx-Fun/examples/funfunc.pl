#!/usr/local/bin/perl

use strict;
use DBI;
use DBIx::Fun;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );
my $fun = DBIx::Fun->context($dbh);

my $emp_id = 9;
my $dept_desc = $fun->get_dept( $emp_id );

print "Employee #${emp_id}'s department is called '$dept_desc'.\n";
