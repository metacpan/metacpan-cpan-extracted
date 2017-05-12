#!/usr/local/bin/perl

use strict;
use DBI;
use DBIx::Fun;
use XML::Simple;
use Data::Dumper;

my $dbh = DBI->connect( 'dbi:Oracle:xe', 'scott', 'tiger' );
my $fun = DBIx::Fun->context($dbh);

my $xml = $fun->get_xml( 'select * from employee' );
print $xml;

my $perldata = XMLin( $xml );

print Dumper($perldata);


