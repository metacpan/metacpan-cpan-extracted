#!/usr/bin/perl -w
use strict;
use Carp 'confess', 'croak';
use Test;
use Data::Taxi;    # TESTING


BEGIN { plan tests => 3 };


my ($struct, $hold);

$struct = {
	name => 'Miko',
	
	schools => [
		'Cardinal Forest',
		'Robinson',
		'VA Tech',
	],
	
	titles => {
		president => 'Idocs',
		worker => 'Dietrick',
	},
};

$struct->{'jobs'} = $struct->{'titles'};
$hold = Data::Taxi::freeze($struct);
$struct = Data::Taxi::thaw($hold);

if ($struct->{'schools'}->[1] eq 'Robinson')
	{ok 1}
else
	{ok 0}

if ($struct->{'jobs'}->{'president'} eq 'Idocs')
	{ok 1}
else
	{ok 0}

if ($struct->{'jobs'} eq $struct->{'titles'})
	{ok 1}
else
	{ok 0}

