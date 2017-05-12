#!/usr/bin/perl

use strict;
use warnings;
use Data::Google::Visualization::DataTable;

use Test::More tests => 3;

my $datatable = Data::Google::Visualization::DataTable->new({ p => 'space' });

$datatable->add_columns(
	{ id => 'bool',  label => "bool", type => 'boolean', p =>
		['mad', { vampires => 'evade' } ] },
);

$datatable->add_rows({
		bool => { v => '1' },
		p    => { 'military' => 'jury', service => ['under'] }
});


is(
	$datatable->output_javascript( pretty => 1 ),
q!{
    "cols": [
        {"id":"bool","label":"bool","p":["mad",{"vampires":"evade"}],"type":"boolean"}
    ],
    "rows": [
        {
            "c":[
                {"v":true}
            ],
            "p":{"military":"jury","service":["under"]}
        }
    ],
    "p":"space"
}!,
	"Properties set on instantiation" );

$datatable->set_properties( undef );

is(
	$datatable->output_javascript( pretty => 1 ),
q!{
    "cols": [
        {"id":"bool","label":"bool","p":["mad",{"vampires":"evade"}],"type":"boolean"}
    ],
    "rows": [
        {
            "c":[
                {"v":true}
            ],
            "p":{"military":"jury","service":["under"]}
        }
    ]
}!,
	"Properties removed" );

$datatable->set_properties( { 'no' => 'protest' } );

is(
	$datatable->output_javascript( pretty => 1 ),
q!{
    "cols": [
        {"id":"bool","label":"bool","p":["mad",{"vampires":"evade"}],"type":"boolean"}
    ],
    "rows": [
        {
            "c":[
                {"v":true}
            ],
            "p":{"military":"jury","service":["under"]}
        }
    ],
    "p":{"no":"protest"}
}!,,
	"Properties set using set_properties" );

