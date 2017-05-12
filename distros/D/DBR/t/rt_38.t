#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 28;

my $dbr = setup_schema_ok('rt_38');

my $dbh = $dbr->connect('rt_38');
ok($dbh, 'dbr connect');

# Repeat the whole test twice to test both query modes (Unregistered and Prefetch)
for(1..2){

      my $names = $dbh->firstnames->all();
      ok(defined($names), 'select all first names');

      # this will loop four times
      while (my $name = $names->next()) {

	    ok(defined($name), 'name = $names->next');

	    my $first = eval{ $name->firstname };
	    ok(defined($first), 'first = name->firstname (' . $first . ') ' . $@);

	    my $lastname = eval{ $name->last_name->lastname };
	    ok(defined($lastname), 'lastname = name->last_name->last_name (' . $first . ') ' . $@);

      }

}
