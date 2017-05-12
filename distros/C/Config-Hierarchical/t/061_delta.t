# test

use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Config::Hierarchical ; 
use Config::Hierarchical::Delta qw (GetConfigDelta GetConfigHierarchicalDelta DumpConfigHierarchicalDelta Get_NoIdentical_Filter) ; 

{
local $Plan = {'delta' => 12} ;

my $delta ;

$delta = GetConfigDelta({name => {}}, {name_2 => {}}) ;
is_deeply($delta, {}, '') ;
	
$delta = GetConfigDelta
	(
	{name   => {A => 1, COMMON => 0}},
	{name_2 => {B => 2, COMMON => 0}}
	) ;
is_deeply
	(
	$delta, 
	{
	'in \'name\' only'   => {'A' => 1},
	'in \'name_2\' only' => {'B' => 2},
	'identical'          => {'COMMON' => 0},
        },
	'something in common'
	) ;
	

$delta = GetConfigDelta
	(
	{name   => {A => 1, COMMON => undef}},
	{name_2 => {B => 2, COMMON => undef}}
	) ;
is_deeply
	(
	$delta, 
	{
	'in \'name\' only'   => {'A' => 1},
	'in \'name_2\' only' => {'B' => 2},
	'identical'          => {'COMMON' => undef},
        },
	'something in common'
	) ;
	
$delta = GetConfigDelta
	(
	{name   => {A => 1, COMMON => undef, COMMON_2 => 0}},
	{name_2 => {B => 2, COMMON => 0, COMMON_2 => 0}}
	) ;
is_deeply
	(
	$delta, 
	{
	'different' => 
		{
		'COMMON' => 
			{
			'name_2' => 0,
			'name' => undef
			}
		},
		
	'in \'name\' only'   =>	{'A' => 1},
	'in \'name_2\' only' => {'B' => 2},
	'identical'          => {'COMMON_2' => 0}
        },
	'common named variable undef on one side'
	) ;

$delta = GetConfigDelta
	(
	{name   => {A => 1, COMMON => 0}},
	{name_2 => {B => 2, COMMON => undef}}
	) ;
is_deeply
	(
	$delta, 
	{
        'different' => 
		{
                'COMMON' => 
			{
                        'name_2' => undef,
                        'name' => 0
                        }
		},
	'in \'name\' only'   =>	{'A' => 1},
	'in \'name_2\' only' => {'B' => 2},
        },
	'common named variable undef on the other side'
	) ;

$delta = GetConfigDelta
	(
	{name   => {A => 1, COMMON => 1}},
	{name_2 => {B => 2, COMMON => 0}}
	) ;
is_deeply
	(
	$delta,
	{
        'different' => 
		{
                'COMMON' => 
			{
                        'name_2' => 0,
                        'name' => 1
                        }
		},
	'in \'name\' only'   => {'A' => 1},
	'in \'name_2\' only' => {'B' => 2},
        },
	'common named variable different'
	) ;


throws_ok
	{
	GetConfigDelta(1, {name_2 => {}}) ;
	} qr/wrong argument type on the left hand side, expected hash/, 'wrong argument type on the left hand side, expected hash' ;

throws_ok
	{
	GetConfigDelta({name => {}}, 1) ;
	} qr/wrong argument type on the right hand side, expected hash/, 'wrong argument type on the right hand side, expected hash' ;

throws_ok
	{
	GetConfigDelta({name => {}, extra => 1}, {name_2 => {}}) ;
	} qr/only one element expected on left hand side/, 'only one element expected on left hand side' ;

throws_ok
	{
	GetConfigDelta({name => {}}, {name_2 => {}, extra => 1}) ;
	} qr/only one element expected on right hand side/, 'only one element expected on right hand side' ;

throws_ok
	{
	GetConfigDelta({name => 1}, {name_2 => {}}) ;
	} qr/expected a HASH as a config on the left hand side/, 'expected a HASH as a config on the left hand side' ;

throws_ok
	{
	GetConfigDelta({name => {}}, {name_2 => 1}) ;
	} qr/expected a HASH as a config on the right hand side/, 'expected a HASH as a config on the right hand side' ;

}

{
local $Plan = {'delta config hierarchical' => 6} ;

my $config_0 = new Config::Hierarchical
			(
			NAME => 'config 0',
			
			INITIAL_VALUES  =>
				[
				{NAME => 'CC1', VALUE => '1'},
				{NAME => 'CC2', VALUE => '2'},
				] ,
			) ;
			

my $config_1 = new Config::Hierarchical
			(
			NAME => 'config 1',
			
			CATEGORY_NAMES   => ['A', 'B',],
			DEFAULT_CATEGORY => 'A',
			
			INITIAL_VALUES  =>
				[
				{CATEGORY => 'B', ALIAS_CATEGORY => $config_0},
				
				{NAME => 'CC1', VALUE => '1'},
				{NAME => 'CC2', VALUE => '2'},
				{NAME => 'CC3', VALUE => '3'},
				] ,
			) ;
			
$config_1->Set(NAME => 'CC1', VALUE => '1.1') ;

my $config_2 = new Config::Hierarchical
			(
			NAME => 'config 2',
			
			CATEGORY_NAMES   => ['<A>', 'B',],
			DEFAULT_CATEGORY => 'A',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'B', ALIAS_CATEGORY=> $config_1},
				] ,
			) ;

$config_2->Set(CATEGORY => 'A', NAME => 'CC1', VALUE => 'A', OVERRIDE => 1) ;
$config_2->Set(CATEGORY => 'A', NAME => 'XYZ', VALUE => 'xyz') ;

my $dump = DumpConfigHierarchicalDelta($config_2, $config_0, Get_NoIdentical_Filter()) ;

my $expected_dump = <<EOD ;
Delta between 'config 2' and 'config 0'':
|- different 
|  `- CC1 
|     |- config 0 = 1 
|     `- config 2 = A 
`- in 'config 2' only 
   |- CC3 = 3 
   `- XYZ = xyz 
EOD

is($dump, $expected_dump, 'config hierarchical (no identical) delta dump') ;



$dump = DumpConfigHierarchicalDelta($config_2, $config_0) ;
$expected_dump = <<EOD ;
Delta between 'config 2' and 'config 0'':
|- different 
|  `- CC1 
|     |- config 0 = 1 
|     `- config 2 = A 
|- identical 
|  `- CC2 = 2 
`- in 'config 2' only 
   |- CC3 = 3 
   `- XYZ = xyz 
EOD

is($dump, $expected_dump, 'config hierarchical delta dump') ;

throws_ok
	{
	GetConfigHierarchicalDelta($config_2, 1) ;
	} qr/expected a 'Config::Hierarchical' on the right hand side/, 'wrong argument' ;

throws_ok
	{
	GetConfigHierarchicalDelta(1, $config_2) ;
	} qr/expected a 'Config::Hierarchical' on the left hand side/, 'wrong argument' ;

throws_ok
	{
	DumpConfigHierarchicalDelta($config_2, 1) ;
	} qr/expected a 'Config::Hierarchical' on the right hand side/, 'wrong argument' ;

throws_ok
	{
	DumpConfigHierarchicalDelta(1, $config_2) ;
	} qr/expected a 'Config::Hierarchical' on the left hand side/, 'wrong argument' ;

}


