#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().
use DBI;

# ------

my($dbh) = DBI -> connect('dbi:mysql:dbname=testdb', 'testuser', 'testpass');
my($sth) = $dbh -> foreign_key_info(undef, undef, 'one', undef, undef, 'two');

if ($sth)
{
	print Dumper($sth->fetchall_hashref(['PKTABLE_NAME']) );
}
else
{
	print "foreign_key_info() returned undef\n";
}
