# set_get_default test

use strict ;
use warnings ;
use Test::Exception ;
use Test::Warn ;
use Test::NoWarnings qw(had_no_warnings) ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Config::Hierarchical ; 

{
local $Plan = {'initial values' => 16} ;

my $structure = { NAME => 'hi', VALUE => 'there'} ;
my $object = bless { NAME => 'hi', VALUE => 'there'}, 'a test object' ;

my $config = new Config::Hierarchical
				(
				INITIAL_VALUES         =>
					[
					{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 1},
					{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2},
					{CATEGORY => 'CURRENT', NAME => 'LD', VALUE => 3, LOCK => 1},
					{NAME => 'AS', VALUE => 4, LOCK => 1},
					
					{NAME => 'STRUCTURE', VALUE => $structure},
					{NAME => 'OBJECT', VALUE => $object},
					] ,
				) ;
				
is(defined $config, 1, 'constructor with initial values') ;

is($config->IsLocked(NAME => 'CC'), 0, 'config not locked') ;
is($config->IsLocked(NAME => 'LD'), 1, 'config locked') ;

is($config->Get(NAME => 'CC'), '2', 'initialized ok') or diag  $config->GetDump();
is($config->Get(NAME => 'LD'), '3', 'initialized ok') ;
is($config->Get(CATEGORY => 'CURRENT', NAME => 'AS'), 4, 'initialized ok') ;

is($config->Exists(NAME => 'AS'), 1, 'exist') ;

is($config->Exists(NAME => 'AS', CATEGORIES_TO_EXTRACT_FROM => ['CURRENT']), 1, 'exist') ;
dies_ok
	{
	$config->Exists(NAME => 'AS', CATEGORIES_TO_EXTRACT_FROM => ['NOT_EXISTS']) ;
	} "invalid categoty in CATEGORIES_TO_EXTRACT_FROM" ;

dies_ok
	{
	$config->Exists(NAME => 'AS', CATEGORIES_TO_EXTRACT_FROM => undef) ;
	} "undefined CATEGORIES_TO_EXTRACT_FROM" ;
	
is($config->Exists(NAME => 'AS', CATEGORIES_TO_EXTRACT_FROM => ['CURRENT']), 1, 'exist') ;

is($config->Exists(NAME => 'NOT_EXIST'), 0, 'not exist') ;

dies_ok
	{
	$config->Exists(CATEGORY => 'CURRENT', NAME => 'DOESNT_MATTER') ;
	} 'no category allowed' ;
	
dies_ok
	{
	$config->Exists() ;
	} 'un-named variable' ;
	
is_deeply($config->Get(NAME => 'STRUCTURE'), $structure, 'structured variable') or diag  $config->GetDump();
is(ref($config->Get(NAME => 'OBJECT')), 'a test object', 'object variable') or diag  $config->GetDump();
}

{
local $Plan = {'coverage' => 1} ;

my (@info_messages);
my $info = sub {push @info_messages, @_} ;
	
my $config = new Config::Hierarchical
				(
				NAME            => 'extra coverage test',
				VERBOSE         => 1,
				INITIAL_VALUES  => [{NAME => 'AS', VALUE => 1}],
				INTERACTION     => 
					{
					INFO  => $info,
					},
				) ;

$config->Exists(FILE => 'my file', LINE => 'my line', NAME => 'AS') ;

#use Data::TreeDumper ;
#diag DumpTree \@info_messages ;

like($info_messages[2], qr/my file:my line/, 'extra coverage') ;
}

{
local $Plan = {'initial values' => 3} ;

dies_ok
	{
	new Config::Hierarchical
				(
				INITIAL_VALUES         =>
					[
					{CATEGORY => 'CURRENT', NAME => 'CC'},
					] ,
				) ;
	} "missing  parameter" ;
	
dies_ok
	{
	new Config::Hierarchical
				(
				INITIAL_VALUES         =>
					[
					{CATEGORY => 'CURRENT', NAMEX => 'CC', VALUE => 1},
					] ,
				) ;
	} "bad parameter" ;
	
dies_ok
	{
	new Config::Hierarchical
				(
				INITIAL_VALUES         =>
					[
					{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1},
					] ,
				) ;
	} "bad category" ;
}

{
local $Plan = {'config creation' => 2} ;

my $config = new Config::Hierarchical() ;

is(defined $config, 1, 'default constructor') ;
isa_ok($config, 'Config::Hierarchical');
}

# single config

{
local $Plan = {'Set with invalid arguments' => 8} ;

my $config = new Config::Hierarchical() ;

dies_ok {$config->Set()} "Missing arguments" ;
dies_ok {$config->Set(NAME => 'CC')} "Missing value" ;
dies_ok {$config->Set(VALUE => 'gcc')} "Missing Name" ;
dies_ok {$config->Set(NAME => 'CC', VALUE => 'gcc', INVALID_ARGUMENT => 1)} "Invalid argument" ;
dies_ok {$config->Set(NAME => 'CC', VALUE => 'gcc', FILE => 'FILE')} "Missing LINE argument" ;
dies_ok {$config->Set(NAME => 'CC', VALUE => 'gcc', LINE => 1)} "Missing FILE argument" ;
dies_ok {$config->Set(NAME => 'CC', VALUE => 'gcc', CATEGORY => 'UNKNOWN')} "Invalid category" ;

dies_ok {$config->Get() ;} "Missing argument" ;

};

{
local $Plan = {'set and get' => 3} ;

my $config = new Config::Hierarchical() ;

$config->Set(NAME => 'CC', VALUE => 'gcc') ;
is($config->Get(NAME => 'CC'), 'gcc', 'get variable back') ;

$config->Set(NAME => 'CC', VALUE => 'gcc') ;
is($config->Get(NAME => 'CC'), 'gcc', 'get variable back') ;

$config->Set(NAME => 'CC', VALUE => 'gcc2') ;
is($config->Get(NAME => 'CC'), 'gcc2', 'get overriden variable back') ;

}

{
local $Plan = {'multiple configs' => 9} ;

my $config = new Config::Hierarchical() ;

dies_ok {$config->SetMultiple(NAME => 'CC', VALUE => 'gcc')} "Invalid arguments, non array ref" ;
dies_ok 
	{
	$config->SetMultiple
			(
			[NAME => 'CC', VALUE => 'gcc'],
			{LOCK => 1}
			) ;
	} "options not first argument" ;

lives_ok {	$config->SetMultiple() ; } "no argument" ;
lives_ok {	$config->SetMultiple({LOCK => 1}) ; } "options only" ;
lives_ok {	$config->SetMultiple({}, [NAME => 'CC', VALUE => 'gcc']) ; } "empty options" ;
dies_ok {	$config->SetMultiple({INVALID => 1}, [NAME => 'CC', VALUE => 'gcc']) ; } "invalid options" ;

#pass valid confis and check all are defined
$config->SetMultiple
		(
		[NAME => 'CC', VALUE => 'gcc'], 
		[NAME => 'CC1', VALUE => 'gcc1'], 
		[NAME => 'CC2', VALUE => 'gcc2'], 
		) ;
		
is($config->Get(NAME => 'CC') , 'gcc', 'get value back') ;
is($config->Get(NAME => 'CC1') , 'gcc1', 'get value back') ;
is($config->Get(NAME => 'CC2') , 'gcc2', 'get value back') ;
}

{
local $Plan = {'multiple configs, option override' => 7} ;

my $config = new Config::Hierarchical() ;

# pass options and sets that override the options
$config->SetMultiple
		(
		{LOCK => 1},
		[NAME => 'LCC', VALUE => 'gcc'], 
		[NAME => 'LCC1', VALUE => 'gcc1'], 
		) ;

# die
dies_ok
	{
	$config->SetMultiple
		(
		[NAME => 'LCC', VALUE => 'gccx'], 
		) ;
	} "setting locked variable" ;
	
# die
dies_ok
	{
	$config->SetMultiple
			(
			{FORCE_LOCK => 1},
			[NAME => 'LCC', VALUE => 'gccx', FORCE_LOCK => 0], 
			) ;
	} "ignoring option" ;
		
warning_like
	{
	lives_ok
		{
		$config->SetMultiple
				(
				{FORCE_LOCK => 1 , FILE => __FILE__, LINE => __LINE__},
				[NAME => 'LCC', VALUE => 'gccx'], 
				) ;
		} "option working" ;
	} qr/Forcing locked/i, "forcing warning";
	
# dies, but first variable is set before die is called
warning_like
	{
	dies_ok
		{
		$config->SetMultiple
			(
			{FORCE_LOCK => 1, FILE => __FILE__, LINE => __LINE__},
			[NAME => 'LCC', VALUE => 'gccy'], 
			[NAME => 'LCC1', VALUE => 'gccz', FORCE_LOCK => 0], 
			) ;
		} "one variable uses options the other not" ;
	} qr/Forcing locked/i, "forcing warning";

is($config->Get(NAME => 'LCC') , 'gccy', 'one value forced lock') ;

}

{
local $Plan = {'multiple get and hash ref' => 8} ;

my $config = new Config::Hierarchical() ;

$config->SetMultiple
		(
		[NAME => 'AR', VALUE => 'ar'], 
		[NAME => 'AS', VALUE => 'as'], 
		[NAME => 'CC', VALUE => 'gcc'], 
		[NAME => 'LD', VALUE => 'ld'], 
		) ;

my @values = $config->GetMultiple(qw(CC AR AS)) ;
ok(@values == 3, "Got values back") ;
is_deeply([@values], [qw( gcc ar as)], 'expected values') ;


my $flattened_hash = $config->GetHashRef() ;
ok(defined$flattened_hash, "Got a hash back") ;
is(keys%$flattened_hash, 4, "hash has 4 elements") ;

is_deeply([sort keys%$flattened_hash], [qw( AR AS CC LD)], 'expected keys') ;

is_deeply
	(
	[
	map {$flattened_hash->{$_}}sort keys%$flattened_hash
	],
	[qw( ar as gcc ld )],
	'expected values'
	) ;

dies_ok
	{
	$config->GetHashRef('argument') ;
	} 'dies on argument' ;
	
dies_ok
	{
	$config->GetHashRef(INVALID_OPTION => ['CURRENT']) ;
	} 'dies on argument' ;
}

{
local $Plan = {'multiple get with option' => 2} ;

my $config = new Config::Hierarchical() ;
my @values = $config->GetMultiple({SILENT_NOT_EXISTS => 1}, qw(CC AR )) ;
ok(@values == 2, "Got no values back") ;

my @other_values = $config->GetMultiple({FILE => __FILE__, LINE => __LINE__, SILENT_NOT_EXISTS => 1}, qw(CC AR )) ;
ok(@other_values == 2, "Got no values back") ;
}

{
local $Plan = {'multiple get with bad argument' => 1} ;

my $config = new Config::Hierarchical() ;

dies_ok
	{
	my @values = $config->GetMultiple(['CC', 'AR']) ;
	} "invalid argument" ;
}

{
local $Plan = {'SILENT_NOT_EXISTS' => 4} ;

my $config = new Config::Hierarchical(DISABLE_SILENT_OPTIONS => 0) ;
$config->Set(NAME => 'AR', VALUE => 'ar') ;

my $ar = $config->Get(NAME => 'AR') ;
had_no_warnings("getting existing variable") ; 

my $cc = $config->Get(NAME => 'CC', SILENT_NOT_EXISTS => 1) ;
had_no_warnings("getting non existing variable, warning localy disabled") ; 

warning_like
	{
	$cc = $config->Get(NAME => 'CC') ;
	} qr/'CC' doesn't exist/, "getting non existing variable" ;
	
$config->SetDisableSilentOptions(1) ;

$cc = $config->Get(NAME => 'CC') ;
had_no_warnings("getting non existing variable, warning disabled") ; 
}

{
local $Plan = {'DIE_NOT_EXISTS' => 3} ;

my $config = new Config::Hierarchical(DIE_NOT_EXISTS => 1) ;

throws_ok
	{
	my $variable = $config->Get(NAME => 'NOT_EXISTS') ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;


throws_ok
	{
	my $variable = $config->Get(NAME => 'NOT_EXISTS', SILENT_NOT_EXISTS => 1) ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;
	

throws_ok
	{
	$config->SetDisableSilentOptions(1) ;
	my $variable = $config->Get(NAME => 'NOT_EXISTS', SILENT_NOT_EXISTS => 1) ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;
}

{
local $Plan = {'DIE_NOT_EXISTS' => 1} ;

my $config = new Config::Hierarchical() ;

throws_ok
	{
	my $variable = $config->Get(DIE_NOT_EXISTS => 1, NAME => 'NOT_EXISTS') ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;
}

{
local $Plan = {'coverage test' => 1} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES   => [ 'PBS', 'CURRENT'],
		DEFAULT_CATEGORY => 'CURRENT',
		INITIAL_VALUES   =>
			[
			{CATEGORY => 'PBS'    , NAME => 'CC', VALUE => 2},
			{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2},
			] ,
		) ;

had_no_warnings() ;
}

{
local $Plan = {'coverage test' => 1} ;

my $config = new Config::Hierarchical
		(
		CATEGORY_NAMES   => [ 'PBS', 'CURRENT'],
		DEFAULT_CATEGORY => 'CURRENT',
		) ;

$config->Set(NAME => 'CC', VALUE => undef) ;

had_no_warnings() ;
}
