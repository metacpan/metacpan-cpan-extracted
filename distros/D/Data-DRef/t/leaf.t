#!/usr/bin/perl -w

use strict;
use Test;
BEGIN { plan tests => 1, todo => [] }

use Data::DRef qw( :leaf );

my ($target, $mapping);

$target = { 
  'myself' => 1,
  'several' => { 'steps' => { 'away' => 2 } }, 
};

$mapping = { leaf_drefs_and_values( $target ) };

ok( scalar keys %$mapping == 2 and $mapping->{'myself'} == 1 and 
	$mapping->{'several.steps.away'} == 2 );
