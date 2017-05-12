#!/usr/local/bin/perl

use strict;
use DBI;
use DBD::Oracle qw(:ora_types);

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );

my $sql = <<EOSQL;
BEGIN
    scott.GET_ALL_EMPLOYEES( :employees );
END;
EOSQL

my $sth = $dbh->prepare( $sql );

my ( $employees );
$sth->bind_param_inout( ':employees', \$employees, 0, { 'ora_type' => ORA_RSET } );

$sth->execute();

while (my ($emp_id, $dept_desc, $position_desc, $location_desc, $start_date, $end_date ) = $employees->fetchrow_array()) {
  print "$emp_id $dept_desc $position_desc $location_desc $start_date-$end_date\n";
}
