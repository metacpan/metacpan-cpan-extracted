# utilities test

use strict ;
use warnings ;
use Test::Exception ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Test::NoWarnings ;
use Test::Warn ;

use Data::TreeDumper ;
use Config::Hierarchical ; 

{
local $Plan = {'previous history' => 1} ;

my $config = new Config::Hierarchical
		(
		INITIAL_VALUES   =>
			[
			{NAME => 'CC', VALUE => 'A', },
			] ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;

my $previous_history = [{hi => 1}, {there => 2}] ;

throws_ok
	{
	$config->Set(HISTORY => $previous_history, NAME => 'CC', VALUE => 'B') ;
	}qr/Can't add history/, 'late history' ;

my $history = $config->GetHistory(NAME => 'CC') ;

#~ use Data::TreeDumper ;
#~ diag DumpTree($history)  ;

}

{
local $Plan = {'CATEGORIES_TO_EXTRACT_FROM' => 3} ;

my $config = new Config::Hierarchical
		(
		INITIAL_VALUES   =>
			[
			{NAME => 'CC', VALUE => 1},
			{NAME => 'CC', VALUE => 2},
			] ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;
my $creation_line = __LINE__ - 1 ;

throws_ok
	{
	$config->GetHistory(CATEGORIES_TO_EXTRACT_FROM => undef, NAME => 'CC') ;
	} qr/undefined category 'CATEGORIES_TO_EXTRACT_FROM'/, 'invalid categories' ;

throws_ok
	{
	$config->GetHistory(CATEGORIES_TO_EXTRACT_FROM => ['INVALID'], NAME => 'CC') ;
	} qr/Invalid category 'INVALID'/, 'invalid categories' ;


my $history = $config->GetHistory(CATEGORIES_TO_EXTRACT_FROM => ['CURRENT'], NAME => 'CC') ;

#~ use Data::TreeDumper ;
#~ diag DumpTree($history)  ;

my $reference_history =
	[
		{
		EVENT => "CREATE AND SET. value = '1', category = 'CURRENT' at '" . __FILE__ . ':' . $creation_line . "', status = OK.",
		TIME => 0,
		},
		{
		EVENT => "SET. value = '2', category = 'CURRENT' at '" . __FILE__ . ':' . $creation_line . "', status = OK.",
		TIME => 1,
		},
	] ;

is_deeply($history, $reference_history, 'history matches reference') or diag DumpTree($history);
}


{
local $Plan = {'cross history' => 2} ;

warnings_like
	{
	my $config1 = new Config::Hierarchical
					(
					NAME => 'config1',
					INITIAL_VALUES  =>
						[
						{FILE => __FILE__, LINE => 0, NAME => 'CC', VALUE => 1},
						] ,
						
					INTERACTION            =>
						{
						# work around error in Test::Warn
						WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
						},
					) ;
					
	$config1->Set(FILE => __FILE__, LINE => 0, NAME => 'CC', VALUE => 2) ;

	my($value1, $category1) = $config1->Get(NAME => 'CC',  GET_CATEGORY => 1) ;
	my $title1 = "'CC' = '$value1' from category '$category1':" ;
	my $history1 = $config1->GetHistory(NAME=> 'CC') ;
	#~ print DumpTree($history1, $title1, DISPLAY_ADDRESS => 0) ;

	my $config2 = new Config::Hierarchical
					(
					NAME => 'config2',
					CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
					INITIAL_VALUES  =>
						[
						{FILE => __FILE__, LINE => 0, HISTORY => $history1, NAME => 'CC', CATEGORY => 'PARENT', VALUE => $value1},
						] ,
					INTERACTION            =>
						{
						# work around error in Test::Warn
						WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
						},
					) ;
					
	$config2->Set(FILE => __FILE__, LINE => 0, NAME => 'CC', OVERRIDE => 1, VALUE => '3') ;

	my($value2, $category2) = $config2->Get(NAME => 'CC',  GET_CATEGORY => 1) ;
	my $title2 = "'CC' = '$value2' from category '$category2':" ;
	my $history2 = $config2->GetHistory(NAME=> 'CC') ;
	#~ print DumpTree($history2, $title2, DISPLAY_ADDRESS => 0) ;

	my $config3 = new Config::Hierarchical
					(
					NAME => 'config3',
					CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
					INITIAL_VALUES  =>
						[
						{FILE => __FILE__, LINE => 0, HISTORY => $history2, NAME => 'CC', CATEGORY => 'PARENT', VALUE => $value2},
						] ,
					INTERACTION            =>
						{
						# work around error in Test::Warn
						WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
						},
					) ;
					
	$config3->Set(FILE => __FILE__, LINE => 0, NAME => 'CC', OVERRIDE => 1, VALUE => '4') ;
	$config3->Set(FILE => __FILE__, LINE => 0, NAME => 'CC', VALUE => '5', COMMENT => 'Set it to 5') ;

	my($value3, $category3) = $config3->Get(NAME => 'CC',  GET_CATEGORY => 1) ;
	my $title3 = "'CC' = '$value3' from category '$category3':" ;
	my $history3 = $config3->GetHistory(NAME=> 'CC') ;
	#~ print DumpTree($history3, $title3, DISPLAY_ADDRESS => 0) ;

my $reference_history = 
	[ 
	{ 
	EVENT => "CREATE, SET HISTORY AND SET. value = '3', category = 'PARENT' at 't/013_history.t:0', status = OK." ,
	HISTORY =>
		[
		{
		EVENT => "CREATE, SET HISTORY AND SET. value = '2', category = 'PARENT' at 't/013_history.t:0', status = OK." ,
		HISTORY =>
			[
			{
			EVENT => "CREATE AND SET. value = '1', category = 'CURRENT' at 't/013_history.t:0', status = OK.",
			TIME => 0,
			},
			{
			EVENT => "SET. value = '2', category = 'CURRENT' at 't/013_history.t:0', status = OK.",
			TIME => 1,
			},
			],
		TIME => 0,
		},
		{
		EVENT => "CREATE AND SET. value = '3', OVERRIDE, category = 'CURRENT' at 't/013_history.t:0', status = Overriding 'PARENT::CC' (existed, value was different).OK.",
		TIME => 1
		},
		],
	TIME => 0,
	},
	
	{
	EVENT => "CREATE AND SET. value = '4', OVERRIDE, category = 'CURRENT' at 't/013_history.t:0', status = Overriding 'PARENT::CC' (existed, value was different).OK." ,
	TIME => 1,
	},
	
	{
	COMMENT => 'Set it to 5',
	EVENT => "SET. value = '5', OVERRIDE, category = 'CURRENT' at 't/013_history.t:0', status = Overriding 'PARENT::CC' (existed, value was different).OK.",
	TIME => 2,
	},
	
	] ;

	is_deeply($history3, $reference_history, 'history matches reference') or diag DumpTree($history3);
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'CURRENT::CC'.*Overriding 'PARENT::CC'/,
	qr/Setting 'CURRENT::CC'.*Overriding 'PARENT::CC'/,
	qr/'CC' is of OVERRIDE type/,
	qr/Setting 'CURRENT::CC'.*Overriding 'PARENT::CC'/,
	], "override  warnings" ;
}

{
local $Plan = {'override warning and value' => 5} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['A', 'B',],
			DEFAULT_CATEGORY => 'B',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
				{CATEGORY => 'B', NAME => 'CC', VALUE => 'B', OVERRIDE => 1},
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
				
				{CATEGORY => 'A', NAME => 'OVERRIDE', VALUE => 'OVERRIDE', OVERRIDE => 1},
				{CATEGORY => 'A', NAME => 'LOCK', VALUE => 'LOCK', LOCK => 1},
				{CATEGORY => 'A', NAME => 'OVERRIDE_AND_LOCK', VALUE => 'OVERRIDE_AND_LOCK', OVERRIDE => 1, LOCK => 1},
				{CATEGORY => 'A', NAME => 'FORCE_LOCK', VALUE => 'FORCE_LOCK', FORCE_LOCK => 1},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
	my $creation_line = __LINE__ - 1 ;
	
	my $history = $config->GetHistory(NAME => 'OVERRIDE') ;
	is
		(
		$history->[0]{EVENT},
		"CREATE AND SET. value = 'OVERRIDE', OVERRIDE, category = 'A' at '" . __FILE__ . ':' . $creation_line . "', status = OK.", 
		'event is complete'
		);
		
		
	$history = $config->GetHistory(NAME => 'LOCK') ;
	is
		(
		$history->[0]{EVENT},
		"CREATE AND SET. value = 'LOCK', LOCK(1), category = 'A' at '" . __FILE__ . ':' . $creation_line . "', status = OK.", 
		'event is complete'
		);
		
	$history = $config->GetHistory(NAME => 'OVERRIDE_AND_LOCK') ;
	is
		(
		$history->[0]{EVENT},
		"CREATE AND SET. value = 'OVERRIDE_AND_LOCK', OVERRIDE, LOCK(1), category = 'A' at '" . __FILE__ . ':' . $creation_line . "', status = OK.", 
		'event is complete'
		);
		
	$history = $config->GetHistory(NAME => 'FORCE_LOCK') ;
	is
		(
		$history->[0]{EVENT},
		"CREATE AND SET. value = 'FORCE_LOCK', FORCE_LOCK, category = 'A' at '" . __FILE__ . ':' . $creation_line . "', status = OK.", 
		'event is complete'
		);
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'B::CC'.*Overriding 'A::CC'/,
	qr/Variable 'A::CC' was overridden/,
	], "override and precedence warnings" ;
}

{
local $Plan = {'empty history' => 14} ;

my $config = new Config::Hierarchical() ;

my $history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "unexisting variable history") ;

$history = $config->GetHistory(CATEGORIES_TO_EXTRACT_FROM => ['CURRENT'], NAME => 'CC') ;
is(@$history, 0, "unexisting variable history") ;

# do stuff that don't change history
$config->Set(NAME => 'XYZ', VALUE => 1) ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "Set") ;

$config->SetMultiple([NAME => 'XYZ', VALUE => 1], [NAME => 'ABC', VALUE => 1]) ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "SetMultiple") ;

# do stuff that don't change history
my $xyz = $config->Get(NAME => 'XYZ') ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "Get") ;

my @multiple = $config->GetMultiple('XYZ', 'ABC') ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "GetMultiple") ;

my $hash_ref = $config->GetHashRef() ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "GetHashRed") ;

$config->SetDisableSilentOptions(1) ;
$config->SetDisableSilentOptions(0) ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "SetDisableSilentOptions") ;

$config->IsLocked(NAME => 'CC') ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "IsLocked") ;

$config->GetDump() ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "GetDump") ;

$config->GetHistory(NAME => 'XYZ') ;
$history = $config->GetHistory(NAME => 'CC') ;
is(@$history, 0, "GetHistory") ;

throws_ok
	{
	$config->GetHistory(FILE => 'my file', LINE => 'my line') ;
	} qr/my file:my line/, "location options used in die" ;

dies_ok
	{
	$config->GetHistory(CATEGORIES_TO_EXTRACT_FROM => ['NOT_EXIT'], NAME => 'CC') ;
	} "bad category" ;

dies_ok
	{
	$config->GetHistory(CATEGORY => 'NOT_EXIT', NAME => 'CC') ;
	} "bad argument" ;
}

{
local $Plan = {'history' => 8} ;

my $creation_line = __LINE__ + 1 ;
my $config = new Config::Hierarchical
				(
				INITIAL_VALUES  =>
					[
					{NAME => 'CC', VALUE => 1},
					{NAME => 'CC', VALUE => 2},
					{NAME => 'AS', VALUE => 4},
					] ,
				) ;

is($config->Get(NAME => 'CC'), 2, 'right value') ;

my $history = $config->GetHistory(NAME => 'CC') ;

is(scalar(@{$history}), 2, '2 entries')  ;

my $lock_line = __LINE__ + 1 ;
$config->Lock(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 3, '3 entries')  ;

my $unlock_line = __LINE__ + 1 ;
$config->Unlock(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, '4 entries') ;

$config->IsLocked(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, 'IsLocked does not change history') ;

$config->GetDump() ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, 'GetDump does not change history') ;

$config->GetHistory(NAME => 'CC') ;
is(scalar(@{$config->GetHistory(NAME => 'CC')}), 4, 'GetHistory does not change history') ;

$history = $config->GetHistory(NAME => 'CC') ;

#~ use Data::TreeDumper ;
#~ diag DumpTree($history)  ;

my $reference_history =
	[
 		{
		EVENT => "CREATE AND SET. value = '1', category = 'CURRENT' at '" . __FILE__ . ':' . $creation_line . "', status = OK.",
		TIME => 0,
		},
		{
		EVENT => "SET. value = '2', category = 'CURRENT' at '" . __FILE__ . ':' . $creation_line . "', status = OK.",
		TIME => 1,
		},
		{
		EVENT => "LOCK. category = 'CURRENT' at '" . __FILE__ . ':' . $lock_line . "', status = Lock: OK.",
		TIME => 3,
		},
		{
		EVENT => "UNLOCK. category = 'CURRENT' at '" . __FILE__ . ':' . $unlock_line . "', status = Unlock: OK.",
		TIME => 4,
		},
	] ;

is_deeply($history, $reference_history, 'history matches reference') or diag DumpTree($history);
}


