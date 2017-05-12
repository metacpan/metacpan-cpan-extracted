#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More;

my $dbr = setup_schema_ok('music');

my $dbh = $dbr->connect('music');
ok($dbh, 'dbr connect');
my $rv;

my %ALBUMDATES = (
		   'Artist A' => 924625200,
		   'Artist B' => 946684800,
		  );

my $artists = $dbh->artist->all();
ok( defined($artists) , 'select all artists');

while (my $artist = $artists->next()) {
    my ($refdate,$datetime);
    ok ( $refdate  =  $ALBUMDATES{$artist->name} , 'datetime - reference date');
    ok ( $datetime =  $artist->date_founded,       'datetime - date_founded ' );
    ok ( $datetime == $refdate,                    'date verification');
    diag($datetime);
    
    ok ( $artist->date_founded('2001-02-03 04:05:06'),    'datetime - update' );
    ok ( $artist->date_founded('midnight Last Tuesday'),  'datetime - update' );
    ok ( $artist->date_founded('next sunday'),  'datetime - update' );
}



done_testing();
