#!/usr/local/bin/perl

use strict;
use DBI;
use DBIx::Fun;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );
my $fun = DBIx::Fun->context($dbh);

# type name schema
print $fun->dbms_metadata->get_ddl( uc shift, uc shift, uc shift );

