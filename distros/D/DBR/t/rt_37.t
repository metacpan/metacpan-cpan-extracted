#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 64;

my $dbr = setup_schema_ok('rt_37');

my $dbh = $dbr->connect('rt_37');
ok($dbh, 'dbr connect');
my $rv;
# Repeat the whole test twice to test both query modes (Unregistered and Prefetch)
for(1..2){

      my $albums = $dbh->album->all();
      ok( defined($albums) , 'select all albums');

      # this will loop four times
      while (my $album = $albums->next()) {

	    my $date = $album->date_released;
	    ok(defined($date), '$date defined');

	    my $unixtime = eval{ $date->unixtime };
	    ok($unixtime && !$@, '$date->unixtime ') or diag($@);

	    $rv = eval{ $date eq 'Some string' };
	    ok(!$@, 'String Equality') or diag($@);

	    $rv = eval{ $date ne 'Some string' };
	    ok(!$@, 'String Inequality') or diag($@);

	    $rv = eval{ $date == 1244926800 };
	    ok(!$@, 'Numeric Equality') or diag($@);

	    $rv = eval{ $date != 1244926800 };
	    ok(!$@, 'Numeric Inequality') or diag($@);

	    $rv = eval{ $date > 1244926800 };
	    ok(!$@, 'Greater than') or diag($@);

	    $rv = eval{ $date < 1244926800 };
	    ok(!$@, 'Less than') or diag($@);

            my $date2 = eval { $date + '4 hours'};
            ok(!$@ && defined($date2) , 'Object + "4 hours"') or diag($@);

            $rv = eval { $date2 > $date };
            ok(!$@, 'Object Less than Object') or diag($@);

      }

}
