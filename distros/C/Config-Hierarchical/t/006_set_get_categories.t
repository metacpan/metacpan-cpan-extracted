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
local $Plan = {'override warning and value' => 2} ;

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
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
			
	#~ # check values
	is($config->Get(NAME => 'CC'), 'B', 'override is sticky') ;
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'B::CC'.*Overriding 'A::CC'/,
	qr/Variable 'A::CC' was overridden/,
	], "override warnings. existed, value was different" ;
}

{
local $Plan = {'override same value' => 1} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['A', 'B',],
			DEFAULT_CATEGORY => 'B',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
				{CATEGORY => 'B', NAME => 'CC', VALUE => 'A', OVERRIDE => 1},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
	}
	[
	], "no override warnings. existed, value was equal" ;
}

{
local $Plan = {'override twice without warning' => 2} ;

warnings_like
	{
	my $config3 = new Config::Hierarchical
					(
					NAME => 'config3',
					CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
					INITIAL_VALUES  =>
						[
						{FILE => __FILE__, LINE => 0,  NAME => 'CC', CATEGORY => 'PARENT', VALUE => 0},
						] ,
					INTERACTION            =>
						{
						# work around error in Test::Warn
						WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
						},
					) ;
					
	$config3->Set(FILE => __FILE__, LINE => 0, NAME => 'CC', OVERRIDE => 1, VALUE => '4') ;
	$config3->Set(FILE => __FILE__, LINE => 0, NAME => 'CC', OVERRIDE => 1, VALUE => '5') ;

	is($config3->Get(NAME => 'CC'), 5, 'override twice without warning') ;
	}
	[
	qr/Overriding 'PARENT::CC'/,
	qr/Overriding 'PARENT::CC'/,
	], 'precedence warnings' ;
}

{
local $Plan = {'no warning when same value as protected category' => 1} ;

my $config = new Config::Hierarchical
				(
				NAME => 'Test config',

				CATEGORY_NAMES         => ['<PROTECTED>','CURRENT'],
				DEFAULT_CATEGORY       => 'CURRENT',
						
				INITIAL_VALUES  =>
					[
					{NAME => 'PROT', CATEGORY => 'PROTECTED', VALUE => 'protected'},
					] ,
					
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					}
				) ;
				
$config->Set(NAME => 'PROT', VALUE => 'protected', OVERRIDE => 1) ;

had_no_warnings() ;
}

{
local $Plan = {'CHECK_LOWER_LEVEL_CATEGORIES' => 7} ;

warning_like
	{
	my $config = new Config::Hierarchical
					(
					NAME => 'Test config',

					CATEGORY_NAMES         => ['<CLI>', '<PBS>', 'PARENT', 'LOCAL', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
							
					INITIAL_VALUES  =>
						[
						{NAME => 'PROT', CATEGORY => 'PBS', VALUE => 'pbs'},
						{NAME => 'PROT', CATEGORY => 'PARENT', VALUE => 'parent'},
						] ,
						
					CHECK_LOWER_LEVEL_CATEGORIES => 1,
					
					INTERACTION            =>
						{
						# work around error in Test::Warn
						WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
						}
					) ;
					
	warning_like
		{
		$config->Set(NAME => 'PROT', VALUE => 'current') ;
		} qr/'PARENT::PROT' takes precedence.*'<PBS>::PROT' takes precedence/, '' ;
		
	warning_like
		{
		$config->Set(NAME => 'PROT', CATEGORY => 'PBS', VALUE => 'PBS') ;
		} qr/Takes Precedence over lower category 'PARENT::PROT'.*Takes Precedence over lower category 'CURRENT::PROT'/, '' ;
		
	warning_like
		{
		$config->Set(NAME => 'PROT', CATEGORY => 'CLI', VALUE => 'cli') ;
		} qr/Takes Precedence over lower category '<PBS>::PROT'.*Takes Precedence over lower category 'PARENT::PROT'.*Takes Precedence over lower category 'CURRENT::PROT'/, '' ;
		
	warning_like
		{
		$config->Set(NAME => 'PROT', CATEGORY => 'PARENT', VALUE => 'parent') ;
		} qr/'<PBS>::PROT' takes precedence.*Takes Precedence over lower category 'CURRENT::PROT'/, '' ;
		
	warning_like
		{
		$config->Set(NAME => 'PROT', LOCK => 1, OVERRIDE => 1, VALUE => 'override') ;
		} qr/Overriding 'PARENT::PROT'.*'<PBS>::PROT' takes precedence/, '' ;
		
	is($config->Get(NAME => 'PROT'),'cli', 'right value') ;
	} 
	[
	qr/'<PBS>::PROT' takes precedence/, # in setup
	], 'warnings OK'

}

{
local $Plan = {'CHECK_LOWER_LEVEL_CATEGORIES' => 4} ;

my $config = new Config::Hierarchical
				(
				NAME => 'Test config',

				CATEGORY_NAMES         => ['A', 'B'],
				DEFAULT_CATEGORY       => 'B',
						
				INITIAL_VALUES  =>
					[
					{NAME => 'CC', CATEGORY => 'B', VALUE => 'B'},
					] ,
				
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					}
				) ;
				
warning_like
	{
	$config->Set(NAME => 'CC', CATEGORY => 'A', VALUE => 'A', CHECK_LOWER_LEVEL_CATEGORIES => 1,) ;
	} qr/Takes Precedence over lower category 'B::CC'/, '' ;
	
is($config->Get(NAME => 'CC'), 'A', 'right value') ;

$config->Set(NAME => 'CC', CATEGORY => 'A', VALUE => 'B', CHECK_LOWER_LEVEL_CATEGORIES => 1,) ;
is($config->Get(NAME => 'CC'), 'B', 'right value') ;

$config->Set(NAME => 'XYZ', CATEGORY => 'A', VALUE => 'XYZ', CHECK_LOWER_LEVEL_CATEGORIES => 1,) ;
had_no_warnings("no warning for variable that don't exist in lower categories") ; 
}

{
local $Plan = {'Get from specific category + WARN_FOR_EXPLICIT_CATEGORY' => 3} ;

warning_like
	{
	my $config = new Config::Hierarchical
					(
					CATEGORY_NAMES    => ['A', 'B'],
					DEFAULT_CATEGORY => 'B',
					INITIAL_VALUES  =>
						[
						{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
						{CATEGORY => 'B', NAME => 'CC', VALUE => 'B'},
						] ,
						
					WARN_FOR_EXPLICIT_CATEGORY => 1
					) ;
					
	warning_like
		{
		my $value = $config->Get(NAME => 'CC', CATEGORIES_TO_EXTRACT_FROM => ['B'],) ;
		is($value, 'B', 'Get from specific category') ;
		}
		qr/Getting 'CC' using explicit category/, 'explict category' ;
	
	} 
	[
	qr/Setting 'CC' using explicit category/, # in setup
	qr/Setting 'CC' using explicit category/, # in setup
	qr/Setting 'B::CC'/, # precedence warning
	], 'warnings OK'
}

{
local $Plan = {'Get from specific category + WARN_FOR_EXPLICIT_CATEGORY' => 3} ;

warning_like
	{
	my $config = new Config::Hierarchical
					(
					CATEGORY_NAMES    => ['A', 'B'],
					DEFAULT_CATEGORY => 'B',
					INITIAL_VALUES  =>
						[
						{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
						{CATEGORY => 'B', NAME => 'CC', VALUE => 'B'},
						] ,
						
					) ;
					
	$config->SetDisplayExplicitCategoryWarningOption(1) ;
	my $value = $config->Get(NAME => 'CC', CATEGORIES_TO_EXTRACT_FROM => ['B'],) ;
	is($value, 'B', 'Get from specific category') ;
	
	$value = $config->Get(NAME => 'CC', CATEGORIES_TO_EXTRACT_FROM => ['A', 'B'],) ;
	is($value, 'A', 'Get from firstcategory') ;
	} 
	[
	qr/Setting 'B::CC'/, # precedence warning
	qr/Getting 'CC' using explicit category/,
	qr/Getting 'CC' using explicit categories/,
	], 'warnings OK'
}

{
local $Plan = {'SetDisplayExplicitCategoryWarningOption verbose' => 2} ;

warning_like
	{
	my $config = new Config::Hierarchical
				(
				VERBOSE => 1,
				INTERACTION =>
					{
					INFO => sub{print @_},
					} ,
				) ;
	
	$config->SetDisplayExplicitCategoryWarningOption(1) ;
	
	throws_ok
		{
		my $value = $config->Get(NAME => 'CC', CATEGORIES_TO_EXTRACT_FROM => ['B'], ) ;
		} qr/Invalid category 'B'/, 'category not listed in constructor';
	} 
	[
	qr/Getting 'CC' using explicit category/,
	], 'warnings OK'
}

{
local $Plan = {'GET_CATEGORY' => 3} ;

warning_like
	{
	my $config = new Config::Hierarchical
					(
					CATEGORY_NAMES    => ['A', 'B'],
					DEFAULT_CATEGORY => 'B',
					INITIAL_VALUES  =>
						[
						{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
						{CATEGORY => 'B', NAME => 'CC', VALUE => 'B'},
						] ,
					) ;
					
	my ($value, $from) = $config->Get(NAME => 'CC', GET_CATEGORY => 1,) ;
	is($value, 'A', 'GET_CATEGORY right value') ;
	is($from, 'A', 'GET_CATEGORY right category') ;
	} qr/Setting 'B::CC'/, 'precedence warning'
	
}

{
local $Plan = {'SILENT_NOT_EXISTS' => 1} ;

dies_ok
	{
	my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES  => ['CLI', 'CURRENT'],
				) ;
	} "must define DEFAULT_CATEGORY" ;
}

{
local $Plan = {'SILENT_NOT_EXISTS' => 1} ;

dies_ok
	{
	my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES    => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURENT',
				) ;
	} "default category must be part of the categories" ;
}

{
local $Plan = {'initial values' => 10} ;

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES    => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1},
					{CATEGORY => 'CLI', NAME => 'CC', VALUE => 2},
					{CATEGORY => 'CURRENT', NAME => 'LD', VALUE => 3, LOCK => 1},
					{NAME => 'AS', VALUE => 4, LOCK => 1},
					] ,
				) ;
				
is(defined $config, 1, 'constructor with initial values') ;

is($config->IsLocked(NAME => 'CC', CATEGORY => 'CLI'), 0, 'config not locked') ;
is($config->IsLocked(NAME => 'LD'), 1, 'config locked') ;

is($config->Get(NAME => 'CC'), '2', 'initialized ok') ;
is($config->Get(NAME => 'LD'), '3', 'initialized ok') ;
is($config->Get(CATEGORY => 'CURRENT', NAME => 'AS'), 4, 'initialized ok') ;

is($config->Exists(NAME => 'LD'), 1, 'exist') ;
is($config->Exists(NAME => 'CC'), 1, 'exist') ;
is($config->Exists(NAME => 'NOT_EXIST'), 0, 'not exist') ;

dies_ok
	{
	$config->Exists(CATEGORY => 'CURRENT', NAME => 'DOESNT_MATTER') ;
	} 'no category allowed' ;

}

{
local $Plan = {'initial values' => 3} ;

dies_ok
	{
	new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				
				INITIAL_VALUES  =>
					[
					{CATEGORY => 'CLI', NAME => 'CC'},
					] ,
				) ;
	} "missing  parameter" ;
	
dies_ok
	{
	new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				
				INITIAL_VALUES   =>
					[
					{CATEGORY => 'CLI', NAMEX => 'CC', VALUE => 1},
					] ,
				) ;
	} "bad parameter" ;
	
dies_ok
	{
	new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				
				INITIAL_VALUES   =>
					[
					{CATEGORY => 'BAD_CATEGORY', NAME => 'CC', VALUE => 1},
					] ,
				) ;
	} "bad category" ;
}

{
local $Plan = {'initial values' => 7} ;

my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					},
				) ;
				
$config->Set(CATEGORY => 'CLI', NAME => 'CC', VALUE => 1) ;
is($config->Get(NAME => 'CC'), 1, 'Set ok') ;

warning_like
	{
	is($config->Get(NAME => 'AS'), undef, 'Not set ok') ;
	} qr/Returning undef/i, "element doesn't exist";
	
warning_like
	{
	$config->Set(CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2) ;
	} qr/'CLI::CC' takes precedence/, "precedence given";

is($config->Get(NAME => 'CC'), 1, 'High priority category')  or diag DumpTree $config ;

warning_like
	{
	$config->Set(CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2, OVERRIDE => 1) ;
	} qr/Overriding 'CLI::CC'/i, "override";

is($config->Get(NAME => 'CC'), 2, 'override') ;
}

{
local $Plan = {'override is not time dependent' => 2} ;

warning_like
	{
	my $config = new Config::Hierarchical
				(
				CATEGORY_NAMES   => ['CLI', 'CURRENT'],
				DEFAULT_CATEGORY => 'CURRENT',
				INITIAL_VALUES   =>
					[
					{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2, OVERRIDE => 1},
					{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1},
					] ,
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					}
				) ;
				
	is($config->Get(NAME => 'CC'), 2, 'override is not time dependent')  or diag DumpTree $config ;
	} qr/Variable 'CLI::CC' was overridden/, 'override warning' ;
}

{
local $Plan = {'override and no silent override' => 1} ;

my $config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 1, 
			
			CATEGORY_NAMES   => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1},
				{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 2, OVERRIDE => 1},
				] ,
			) ;

is($config->Get(NAME => 'CC'), 2, 'override is not time dependent')  or diag DumpTree $config ;
}

{
local $Plan = {'SILENT_NOT_EXISTS' => 3} ;

my $config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				{CATEGORY => 'CLI', NAME => 'CLI', VALUE => 1},
				{CATEGORY => 'CURRENT', NAME => 'CURRENT', VALUE => 1},
				] ,
			) ;

my $ cc = $config->Get(CATEGORY => 'CLI', NAME => 'CC', SILENT_NOT_EXISTS => 1) ;
had_no_warnings("getting non existing variable, warning localy disabled") ; 

warning_like
	{
	$cc = $config->Get(CATEGORY => 'CLI', NAME => 'CC') ;
	} qr/'CC' doesn't exist/, "getting non existing variable" ;
	
$config->SetDisableSilentOptions(1) ;

$cc = $config->Get(CATEGORY => 'CLI', NAME => 'CC') ;
had_no_warnings("getting existing variable, warning disabled") ; 
}

{
local $Plan = {'DIE_NOT_EXISTS' => 3} ;

my $config = new Config::Hierarchical
			(
			DIE_NOT_EXISTS => 1,
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				{CATEGORY => 'CLI', NAME => 'CLI', VALUE => 1},
				{CATEGORY => 'CURRENT', NAME => 'CURRENT', VALUE => 1},
				] ,
			) ;

throws_ok
	{
	my $variable = $config->Get(CATEGORY => 'CLI', NAME => 'NOT_EXISTS') ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;


throws_ok
	{
	my $variable = $config->Get(CATEGORY => 'CLI', NAME => 'NOT_EXISTS', SILENT_NOT_EXISTS => 1) ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;
	

throws_ok
	{
	$config->SetDisableSilentOptions(1) ;
	my $variable = $config->Get(CATEGORY => 'CLI', NAME => 'NOT_EXISTS', SILENT_NOT_EXISTS => 1) ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;
}

{
local $Plan = {'DIE_NOT_EXISTS' => 1} ;

my $config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				{CATEGORY => 'CLI', NAME => 'CLI', VALUE => 1},
				{CATEGORY => 'CURRENT', NAME => 'CURRENT', VALUE => 1},
				] ,
			) ;

throws_ok
	{
	my $variable = $config->Get(DIE_NOT_EXISTS => 1, CATEGORY => 'CLI', NAME => 'NOT_EXISTS') ;
	} qr/'NOT_EXISTS' doesn't exist/, "getting non existing variable under DIE_NOT_EXISTS mode" ;
}

{
local $Plan = {'SILENT_OVERRIDE' => 3} ;

my $config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				{CATEGORY => 'CLI', NAME => 'CLI', VALUE => 1},
				{CATEGORY => 'CLI', NAME => 'CLI2', VALUE => 1},
				{CATEGORY => 'CLI', NAME => 'CLI3', VALUE => 1},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;

$config->Set(CATEGORY => 'CURRENT', NAME => 'CLI', VALUE => 'override', OVERRIDE => 1, SILENT_OVERRIDE => 1) ;
had_no_warnings("overriding variable, warning localy disabled") ; 

warning_like
	{
	$config->Set(CATEGORY => 'CURRENT', NAME => 'CLI2', VALUE => 'override') ;
	} qr/'CLI::CLI2' takes precedence/, "overriding variable" ;
	
$config->SetDisableSilentOptions(1) ;
$config->Set(CATEGORY => 'CURRENT', NAME => 'CLI3', VALUE => 'override', OVERRIDE => 1, SILENT_OVERRIDE => 1) ;
had_no_warnings("overriding variable, silent override globaly disabled") ; 
}

{
local $Plan = {'GetHash && $config->GetKeyValueTuples' => 4} ;

my $config ;
warning_like
	{
	$config = new Config::Hierarchical
			(
			DISABLE_SILENT_OPTIONS => 0,
			CATEGORY_NAMES  => ['CLI', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES  =>
				[
				{CATEGORY => 'CLI',     NAME => 'CLI',     VALUE => 'CLI_CLI'},
				{CATEGORY => 'CLI',     NAME => 'CLI2',    VALUE => 'CLI_CLI2'},
				{CATEGORY => 'CURRENT', NAME => 'CURRENT', VALUE => 'CURRENT'},
				{CATEGORY => 'CURRENT', NAME => 'CLI',     VALUE => 'CURRENT_CLI'},
				{CATEGORY => 'CURRENT', NAME => 'CLI2',    VALUE => 'CURRENT_CLI2', OVERRIDE => 1},
				] ,
				
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
	} 
	[
	qr/Setting 'CURRENT::CLI'.*'CLI::CLI' takes precedence/,
	qr/Setting 'CURRENT::CLI2'.*Overriding 'CLI::CLI2'/,
	], "initialisation" ;

is_deeply(scalar($config->GetHashRef()),{CLI => 'CLI_CLI', CLI2 => 'CURRENT_CLI2', CURRENT => 'CURRENT'}, 'expected values') ;

is_deeply
	(
	[sort {$a->{NAME} cmp $b->{NAME}} $config->GetKeyValueTuples()],
	[
	{NAME => 'CLI', VALUE => 'CLI_CLI'},
	{NAME => 'CLI2', VALUE => 'CURRENT_CLI2'},
	{NAME => 'CURRENT', VALUE => 'CURRENT'}
	]
	, 'expected tuples'
	)  or diag DumpTree [$config->GetKeyValueTuples()];

warning_like
	{
	$config->GetKeyValueTuples() ;
	}
	qr/\'GetKeyValueTuples\' in void context/, 'GetKeyValue tuples called in void context' ;

}
