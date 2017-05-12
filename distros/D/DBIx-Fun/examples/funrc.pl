#!/usr/local/bin/perl

use strict;
use DBI;
use DBIx::Fun;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );
my $fun = DBIx::Fun->context($dbh);

my $employees;
$fun->get_all_employees( \$employees );

while (my ($emp_id, $dept_desc, $position_desc, $location_desc, $start_date, $end_date ) = $employees->fetchrow_array()) {
  print "$emp_id $dept_desc $position_desc $location_desc $start_date-$end_date\n";
}
