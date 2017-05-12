#!/usr/bin/perl

use strict;
use warnings;
use Data::Google::Visualization::DataTable;

use Test::More tests => 1;

my $datatable = Data::Google::Visualization::DataTable->new();

$datatable->add_columns(
	{ id => 'bool',     label => "True or False", type => 'boolean' },
	{ id => 'number',   label => "Number",        type => 'number' },
	{ id => 'string',   label => "Some String",   type => 'string',
		p => { display => 'none' } },
);

$datatable->add_rows(
 # Add as array-refs
	[
		{ v => undef, f => 'YES' },
		undef,
		undef
	],
	{
		bool      => undef,
		number    => undef,
		string    => { v => undef, f => 'Foo Bar' },
	},
);

$datatable->add_rows({ number => 0 });
$datatable->add_rows([ undef, 1 ]);

is(
	$datatable->output_javascript(),
	q!{"cols": [{"id":"bool","label":"True or False","type":"boolean"},{"id":"number","label":"Number","type":"number"},{"id":"string","label":"Some String","p":{"display":"none"},"type":"string"}],"rows": [{"c":[{"f":"YES","v":null},{"v":null},{"v":null}]},{"c":[{"v":null},{"v":null},{"f":"Foo Bar","v":null}]},{"c":[{"v":null},{"v":0},{"v":null}]},{"c":[{"v":null},{"v":1},{"v":null}]}]}!
);

