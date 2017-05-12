#!/usr/local/bin/perl

use strict;
use DBI;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );

my $sql = <<EOSQL;
BEGIN
    scott.HIRE_EMPLOYEE( :dept_id, :position_id, :location_id, :emp_id, :hire_date );
END;
EOSQL

my $sth = $dbh->prepare( $sql );

$sth->bind_param( ':dept_id', 40 );
$sth->bind_param( ':position_id', 1 );
$sth->bind_param( ':location_id', 3 );

my ( $emp_id, $hire_date );
$sth->bind_param_inout( ':emp_id', \$emp_id, 80 );
$sth->bind_param_inout( ':hire_date', \$hire_date, 80 );

$sth->execute();

print "Employee #${emp_id} was hired on $hire_date.\n";