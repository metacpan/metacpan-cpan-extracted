#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 4;

# As always, it's important that the sample database is not tampered with, otherwise our tests will fail
my $dbr = setup_schema_ok('music');

my $dbh = $dbr->connect('music');
ok($dbh, 'dbr connect');

my $count;
my $rv;


# legacy
$rv = $dbh->select(
		   -table => 'album',
		   -where => {
			      album_id => {
					   -table => 'track',
					   -where => {
						      'name' => ['like', 'Track%A1']
						     },
					   -field => 'album_id'
					  },
			     },
		   -fields => [qw'album_id rating date_released']
		  );

if(defined($rv)){
      ok(1, 'legacy - basic subquery defined');

      ok(@$rv == 2,   'legacy - basic subquery number of results');
}

