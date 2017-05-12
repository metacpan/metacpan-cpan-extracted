# set_get_default test

use strict ;
use warnings ;
use Test::Exception ;
use Test::Warn ;
use Test::NoWarnings qw(had_no_warnings) ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Data::TreeDumper ;

use Config::Hierarchical ; 

{
local $Plan = {'Attributes' => 16} ;

my $config = new Config::Hierarchical
				(
				INITIAL_VALUES  =>	[ {NAME => 'CC', VALUE => 1},] ,
				) ;
				
$config->SetAttribute(NAME => 'CC', VALUE => 'attribute') ;
my ($value, $attribute_exists) = $config->GetAttribute(NAME => 'CC') ;
is($value, 'attribute', 'right attribute') ;
ok($attribute_exists, 'attribute exists') ;

$config->SetAttribute(NAME => 'CC', VALUE => undef) ;
($value, $attribute_exists) = $config->GetAttribute(NAME => 'CC') ;
is($value, undef, 'right attribute') ;
ok($attribute_exists, 'attribute exists') ;

# get attribute from variable without attribute
$config->Set(NAME => 'XYZ', VALUE => 'xyz') ;
($value, $attribute_exists) = $config->GetAttribute(NAME => 'XYZ') ;
is($value, undef, 'right attribute') ;
ok(!$attribute_exists, 'attribute does not exists') ;

# unexisting valiable attribute setting
throws_ok
	{
	$config->SetAttribute(NAME => 'UNEXISTING', VALUE => 'unexisting') ;
	} qr/Can't set attribute, variable 'UNEXISTING' doesn't exist/, 'attribute to unexisting variable' ;

# unexisting valiable attribute getting
throws_ok
	{
	warning_like
		{
		$config->GetAttribute(NAME => 'UNEXISTING') ;
		} qr/'GetAttribute' called in scalar context/, 'scalar contex' ;
		
	} qr/Can't get attribute, variable 'UNEXISTING' doesn't exist/, 'attribute from unexisting variable' ;

# scalar context
warning_like
	{
	my $scalar = $config->GetAttribute(NAME => 'CC') ;
	} qr/GetAttribute: called in scalar context/, 'scalar contex' ;
	
# Set attribute in 'Set'
$config->Set(NAME => 'NEW', VALUE => 'new', ATTRIBUTE => 'new') ;
($value, $attribute_exists) = $config->GetAttribute(NAME => 'NEW') ;
is($value, 'new', 'right attribute') ;
ok($attribute_exists, 'attribute does not exists') ;

# check the attribute settings in the history
my $cc_reference_history = 
	[ 
	{ 
	EVENT => "CREATE AND SET. value = '1', category = 'CURRENT' at 't/018_set_get_attribute.t:19', status = OK.",
	TIME => 0,
	},
	
	{
	EVENT => "SET_ATTRIBUTE. category = 'CURRENT', value = 'attribute' at 't/018_set_get_attribute.t:24', status = OK.",
	TIME => 1,
	}, 
	
	{
	EVENT => "SET_ATTRIBUTE. category = 'CURRENT', value = undef at 't/018_set_get_attribute.t:29', status = OK.",
	TIME => 2,
	}, 
	] ;
	
my $history = $config->GetHistory(NAME=> 'CC') ;
is_deeply($history, $cc_reference_history, 'history matches reference') or diag DumpTree($history);


# check the attribute settings in the history when done through Set
# at creation
my $new_reference_history = 
	[ 
	{ 
	EVENT => "CREATE, SET ATTRIBUTE AND SET. value = 'new', category = 'CURRENT' at 't/018_set_get_attribute.t:63', status = OK.",
	TIME => 4,
	},
	] ;
	
$history = $config->GetHistory(NAME=> 'NEW') ;
is_deeply($history, $new_reference_history, 'history matches reference') or diag DumpTree($history);

# after creation
$config->Set(NAME => 'ABC', VALUE => 'abc') ;
$config->Set(NAME => 'ABC', VALUE => 'def', ATTRIBUTE => 'def') ;

($value, $attribute_exists) = $config->GetAttribute(NAME => 'ABC') ;
is($value, 'def', 'right attribute') ;
ok($attribute_exists, 'attribute does not exists') ;

my $abc_reference_history = 
	[ 
	{
	EVENT => "CREATE AND SET. value = 'abc', category = 'CURRENT' at 't/018_set_get_attribute.t:105', status = OK.",
	TIME => 5,
	} ,
	
	{
	EVENT => "SET, SET ATTRIBUTE. value = 'def', category = 'CURRENT' at 't/018_set_get_attribute.t:106', status = OK.",
	TIME => 6,
	}
	] ;
	
$history = $config->GetHistory(NAME=> 'ABC') ;
is_deeply($history, $abc_reference_history, 'history matches reference') or diag DumpTree($history);
}

{
local $Plan = {'no validator for aliased categories' => 1} ;

my $config_1 = new Config::Hierarchical
			(
			NAME => 'config 1',
			
			INITIAL_VALUES  =>
				[
				{NAME => 'CC1', VALUE => '1'},
				] ,
			) ;

my $config_2 = new Config::Hierarchical
		(
		NAME => 'config 2',
		
		CATEGORY_NAMES   => ['A', 'B',],
		DEFAULT_CATEGORY => 'A',
		INITIAL_VALUES   =>
			[
			{CATEGORY => 'A', ALIAS_CATEGORY => $config_1},
			] ,
		) ;
		
throws_ok
	{
	$config_2->SetAttribute
		(
		CATEGORY  => 'A' ,
		NAME          => 'CC',
		VALUE         => 'attribute',
		) ;	
	} qr/Can't set aliased category attribute \(read only\)/, "can't add attribute to aliased category" ;
}

{
local $Plan = {'bad arguments' => 6} ;

my $config = new Config::Hierarchical
				(
				INITIAL_VALUES  =>	[ {NAME => 'CC', VALUE => 1},] ,
				) ;

throws_ok
	{
	$config->SetAttribute(CATEGORY => 'XYZ', NAME => 'CC', VALUE => 'attribute') ;
	} qr/Invalid category/, 'invalid category' ;
	
throws_ok
	{
	$config->SetAttribute(VALUE => 'attribute') ;
	} qr/Missing name/, 'missing variable name' ;
	
throws_ok
	{
	$config->SetAttribute(NAME => 'CC') ;
	} qr/Missing value/, 'missing value for attribute' ;
	
throws_ok
	{
	my ($attribute, $attribute_exists) = $config->GetAttribute(CATEGORY => 'XYZ', NAME => 'CC', VALUE => 'attribute') ;
	} qr/Invalid category/, 'invalid category' ;
	
throws_ok
	{
	my ($attribute, $attribute_exists) = $config->GetAttribute(VALUE => 'attribute') ;
	} qr/Missing name/, 'missing variable name' ;
	
throws_ok
	{
	my ($attribute, $attribute_exists) = $config->GetAttribute(NAME => 'CC', VALUE => 'attribute') ;
	} qr/Unexpected field VALUE/, 'unexpected fiels value in GetAttribute' ;

}

{
local $Plan = {'coverage' => 8} ;

my @messages ;
my $info = sub {push @messages, @_} ;
	
my $config = new Config::Hierarchical
				(
				VERBOSE         => 1,
				INITIAL_VALUES  =>	[ {NAME => 'CC', VALUE => 1},] ,
				INTERACTION     => {INFO => $info},
				WARN_FOR_EXPLICIT_CATEGORY => 1,
				) ;

@messages = () ;

warning_like
	{
	$config->SetAttribute(FILE => 'special_file', LINE => 'line', CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 'attribute') ;
	} qr/Setting 'CC' using explicit category at 'special_file:line'/, 'explicit category' ;

is(@messages, 1, "SetAttribute message") or diag DumpTree \@messages ;
like($messages[0], qr/special_file/, 'verbose reports right file') ;
like($messages[0], qr/SetAttribute/, 'SetAttribute') ;

@messages = () ;
warning_like
	{
	my ($attribute, $exists) = $config->GetAttribute(FILE => 'special_file', LINE => 'line', CATEGORY => 'CURRENT', NAME => 'CC') ;
	} qr/Setting 'CC' using explicit category at 'special_file:line'/, 'explicit category' ;
	
is(@messages, 1, "GetAttribute message")  or diag DumpTree \@messages ;
like($messages[0], qr/special_file/, 'verbose reports right file') ;
like($messages[0], qr/GetAttribute/, 'GetAttribute') ;

}
