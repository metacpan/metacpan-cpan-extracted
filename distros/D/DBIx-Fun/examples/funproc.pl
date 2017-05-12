#!/usr/local/bin/perl

use strict;
use DBI;
use DBIx::Fun;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );
my $fun = DBIx::Fun->context($dbh);

my ( $emp_id, $hire_date );
$fun->hire_employee( 40, 1, 3, \$emp_id, \$hire_date );

print "Employee #${emp_id} was hired on $hire_date.\n";
