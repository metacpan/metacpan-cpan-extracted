#!/usr/local/bin/perl

use strict;
use DBI;
use DBIx::Fun;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );
my $fun = DBIx::Fun->context($dbh);

my ($numrows, $numblks, $avgrlen);
$fun->dbms_stats->get_table_stats( 'sys', 'all_procedures', undef, undef, undef,
                                    \$numrows, \$numblks, \$avgrlen  );

print "We have $numrows rows, $numblks blocks, and $avgrlen average row length\n";

