# add_get_default test

use strict ;
use warnings ;
use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn ;
use Test::NoWarnings qw(had_no_warnings) ;

use Test::More 'no_plan';
use Test::Block qw($Plan);
  
use Config::Hierarchical ; 

{
local $Plan = {'GetKey' => 5} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['A', 'B',],
			DEFAULT_CATEGORY => 'B',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A', },
				{CATEGORY => 'B', NAME => 'CC', VALUE => 'B', OVERRIDE => 1},
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
				{CATEGORY => 'A', NAME => 'V1', VALUE => 'V1'},
				{CATEGORY => 'A', NAME => 'VA', VALUE => 'VA'},
				{CATEGORY => 'A', NAME => 'V2', VALUE => 'V2'},
				{CATEGORY => 'B', NAME => 'V1', VALUE => 'V1'},
				{CATEGORY => 'B', NAME => 'VB', VALUE => 'VB'},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
			
	#~ # check values
	is($config->Get(NAME => 'CC'), 'B', 'override is sticky') ;
	
	is_deeply
		(
		[sort $config->GetKeys()],
		[qw(CC V1 V2 VA VB)]
		, 'get keys'
		) or diag DumpTree [sort $config->GetKeys()];
		
	is_deeply
		(
		[sort $config->GetKeys(CATEGORIES_TO_EXTRACT_FROM => ['A'])],
		[qw(CC V1 V2 VA)],
		'get keys'
		) or diag DumpTree [sort $config->GetKeys(CATEGORIES_TO_EXTRACT_FROM => ['A'])] ;
	
	is_deeply
		(
		[sort $config->GetKeys(CATEGORIES_TO_EXTRACT_FROM => ['B'])],
		[qw(CC V1 VB)],
		'get keys'
		) or diag DumpTree [sort $config->GetKeys(CATEGORIES_TO_EXTRACT_FROM => ['B'])] ;
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'B::CC'.*Overriding 'A::CC'/,
	qr/Variable 'A::CC' was overridden/,
	], "override warnings. existed, value was different" ;
}


{
local $Plan = {'GetKeys in void context' => 1} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['A', 'B',],
			DEFAULT_CATEGORY => 'B',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A', },
				{CATEGORY => 'B', NAME => 'CC', VALUE => 'B', OVERRIDE => 1},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
			
	$config->GetKeys() ; # warns about void context
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'B::CC'.*Overriding 'A::CC'/,
	qr/'GetKeys' called in void context/,
	], "override warnings. existed, value was different" ;
}

