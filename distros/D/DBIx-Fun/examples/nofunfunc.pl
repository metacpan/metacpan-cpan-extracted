#!/usr/local/bin/perl

use strict;
use DBI;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );

my $sql = <<EOSQL;
BEGIN
    :dept_desc := scott.GET_DEPT( :emp_id );
END;
EOSQL

my $sth = $dbh->prepare( $sql );

my $emp_id = 9;
$sth->bind_param( ':emp_id', $emp_id );

my $dept_desc;
$sth->bind_param_inout( ':dept_desc', \$dept_desc, 80 );

$sth->execute();

print "Employee #${emp_id}'s department is called '$dept_desc'.\n";