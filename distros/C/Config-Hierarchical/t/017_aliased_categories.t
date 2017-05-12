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

my $config_1 = new Config::Hierarchical
			(
			NAME => 'config 1',
			
			INITIAL_VALUES  =>
				[
				{NAME => 'CC1', VALUE => '1'},
				{NAME => 'CC2', VALUE => '2'},
				{NAME => 'CC3', VALUE => '3'},
				{NAME => 'CC4', VALUE => '4'},
				{NAME => 'CC5', VALUE => '5'},
				] ,
			) ;

{
local $Plan = {'no validator for aliased categories' => 1} ;

sub PositiveValueValidator
{
my ($value) = @_; 
return($value >= 0)
} ;

my $config_2 = new Config::Hierarchical
		(
		NAME => 'config 2',
		
		CATEGORY_NAMES   => ['A', 'B',],
		DEFAULT_CATEGORY => 'A',
		INITIAL_VALUES   =>
			[
			{CATEGORY => 'A', ALIAS_CATEGORY => $config_1},
			] ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;
		
throws_ok
	{
	$config_2->AddValidator
		(
		CATEGORY_NAMES => ['A'] ,
		NAMES          => ['CC', 'LD'],
		VALIDATORS     => {positive_value => \&PositiveValueValidator},
		) ;	
	} qr/Can't Add validator '.*' to aliased category/, "can't add validator to aliased category" ;
}

{
local $Plan = {'aliased category, is default category' => 7} ;

my $config_2 ;

warning_like
	{
	$config_2 = new Config::Hierarchical
			(
			NAME => 'config 2',
			
			CATEGORY_NAMES   => ['A', 'B',],
			DEFAULT_CATEGORY => 'A',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', ALIAS_CATEGORY => $config_1, COMMENT => 'comment', HISTORY => 'history'},
				{CATEGORY => 'B', NAME => 'CC1', VALUE => 'B'},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
	} qr/Setting 'B::CC1'.*'A::CC1' takes precedence /, 'setup warning' ;
	
is_deeply
	(
	[sort $config_2->GetKeys()],
	[qw(CC1 CC2 CC3 CC4 CC5)]
	, 'get keys'
	) or diag DumpTree [sort $config_2->GetKeys()];
	
throws_ok
	{
	$config_2->Set(NAME => 'ABC', VALUE => 1) ;	
	} qr/Can't set aliased category \(read only\)/, 'setting a read only alias' ;


$config_2->Set(CATEGORY => 'B', NAME => 'ABC', VALUE => 'ABC') ;
is($config_2->Get(NAME => 'ABC'), 'ABC', 'set/get non aliased category') ;

is($config_2->Get(NAME => 'CC1'), '1', 'get from aliased category') ;

warning_like
	{
	$config_2->Set(CATEGORY => 'B', NAME => 'CC1', VALUE => 'B', OVERRIDE => 1) ;
	} qr/Setting 'B::CC1'.*Overriding 'A::CC1'/, 'override aliased category warning' ;
	
is($config_2->Get(NAME => 'CC1'), 'B', 'override aliased category') ;
}

{
local $Plan = {'aliased category, is lower category' => 3} ;

my $config_2 ;

warning_like
	{
	my $config_2 = new Config::Hierarchical
				(
				
				NAME => 'config 2',
				
				CATEGORY_NAMES   => ['<A>', 'B',],
				DEFAULT_CATEGORY => 'A',
				INITIAL_VALUES   =>
					[
					{CATEGORY => 'B', ALIAS_CATEGORY => $config_1},
					] ,
				INTERACTION            =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					},
				) ;

	is($config_2->Get(NAME => 'CC1'), '1', 'config from aliased category') ;

	$config_2->Set(CATEGORY => 'A', NAME => 'CC1', VALUE => 'A', OVERRIDE => 1, CHECK_LOWER_LEVEL_CATEGORIES => 1) ;
	
	is($config_2->Get(NAME => 'CC1'), 'A', 'config from higher level category') ;
	
	} qr/Setting 'A::CC1'.*Takes Precedence over lower category 'B::CC1'/, 'setup warning' ;
}

{
local $Plan = {'aliased category, bad setup arguments' => 4} ;

throws_ok
	{
	new Config::Hierarchical
		(
		NAME => 'config 2',
		
		CATEGORY_NAMES   => ['B',],
		DEFAULT_CATEGORY => 'B',
		INITIAL_VALUES   =>
			[
			{CATEGORY => 'A', ALIAS_CATEGORY => $config_1},
			] ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;
	} qr/Invalid category 'A'/, 'invalid aliased category' ;
	
throws_ok
	{
	new Config::Hierarchical
		(
		NAME => 'config 2',
		
		CATEGORY_NAMES   => ['A', 'B',],
		DEFAULT_CATEGORY => 'B',
		INITIAL_VALUES   =>
			[
			{CATEGORY => 'A', ALIAS_CATEGORY => $config_1, VALUE => 1},
			] ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;
	} qr/Invalid 'VALUE'/, 'invalid aliased category' ;

throws_ok
	{
	new Config::Hierarchical
		(
		NAME => 'config 2',
		
		CATEGORY_NAMES   => ['A', 'B',],
		DEFAULT_CATEGORY => 'B',
		INITIAL_VALUES   =>
			[
			{CATEGORY => 'A', ALIAS_CATEGORY => $config_1, NAME => 'name'},
			] ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;
	} qr/Invalid 'NAME'/, 'invalid aliased category' ;

throws_ok
	{
	new Config::Hierarchical
		(
		NAME => 'config 2',
		
		CATEGORY_NAMES   => ['A', 'B',],
		DEFAULT_CATEGORY => 'B',
		INITIAL_VALUES   =>
			[
			{CATEGORY => 'A', NAME => 'name', VALUE => 1},
			{CATEGORY => 'A', ALIAS_CATEGORY => $config_1},
			] ,
		INTERACTION            =>
			{
			# work around error in Test::Warn
			WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
			},
		) ;
	} qr/Can't alias a category that's is already set/, 'aliased too late' ;


}

{
local $Plan = {'aliased category display override warnings' => 1} ;

warnings_like
	{
	my $config_a = new Config::Hierarchical
				(
				NAME => 'config a',
				
				INITIAL_VALUES  =>
					[
					{NAME => 'same', VALUE => '0'},
					{NAME => 'CC1', VALUE => 'a1'},
					{NAME => 'CC2', VALUE => 'a2'},
					] ,
				) ;
				
	my $config_c = new Config::Hierarchical
				(
				NAME => 'config c',
				
				INITIAL_VALUES  =>
					[
					{NAME => 'same', VALUE => '0'},
					{NAME => 'CC1', VALUE => 'c1'},
					{NAME => 'CC2', VALUE => 'c2'},
					] ,
				) ;
				

	my $config_2 = new Config::Hierarchical
				(
				NAME => 'config 2',
				
				CATEGORY_NAMES   => ['A', 'B', 'C'],
				DEFAULT_CATEGORY => 'B',
				
				INITIAL_VALUES  =>
					[
					{NAME => 'CC1', VALUE => '1'},
					{NAME => 'CC2', VALUE => '2'},
					{NAME => 'CC3', VALUE => '3'},
					{CATEGORY => 'A', ALIAS_CATEGORY => $config_a, CHECK_LOWER_LEVEL_CATEGORIES => 1},
					{CATEGORY => 'C', ALIAS_CATEGORY => $config_c},
					] ,
					
				INTERACTION =>
					{
					# work around error in Test::Warn
					WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
					},
				) ;
				
	$config_2->Set(NAME => 'CC1', VALUE => '1.1', CHECK_LOWER_LEVEL_CATEGORIES => 1) ;
	}
	[
	qr/config 2: Setting 'A::CC1'.*Takes Precedence over lower category 'B::CC1'/ ,
	qr/config 2: Setting 'A::CC2'.*Takes Precedence over lower category 'B::CC2'/,
	qr/config 2: Setting 'C::CC1'.*'B::CC1' takes precedence.*'A::CC1' takes precedence/,
	qr/config 2: Setting 'C::CC2'.*'B::CC2' takes precedence.*'A::CC2' takes precedence/,
	qr/config 2: Setting 'B::CC1'.*'A::CC1' takes precedence/ ,
	], 'alias setup warnings' ;
}

{
local $Plan = {'aliased category and variable history' => 5} ;

my $config_0 = new Config::Hierarchical
			(
			NAME => 'config 0',
			
			INITIAL_VALUES  =>
				[
				{NAME => 'CC1', VALUE => '1'},
				{NAME => 'CC2', VALUE => '2'},
				] ,
				
			FILE => 'file',
			LINE => 'line',
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
			FILE => 'file',
			LINE => 'line',
			) ;
			
$config_1->Set(FILE => 'file', LINE => 'line', NAME => 'CC1', VALUE => '1.1') ;

my $config_2 = new Config::Hierarchical
			(
			NAME => 'config 2',
			
			CATEGORY_NAMES   => ['<A>', 'B',],
			DEFAULT_CATEGORY => 'A',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'B', ALIAS_CATEGORY => $config_1},
				] ,
			FILE => 'file',
			LINE => 'line',
			) ;

$config_2->Set(FILE => 'file', LINE => 'line', CATEGORY => 'A', NAME => 'CC1', VALUE => 'A', OVERRIDE => 1) ;
$config_2->Set(FILE => 'file', LINE => 'line', CATEGORY => 'A', NAME => 'XYZ', VALUE => 'xyz') ;


my $expected_dump = <<EOD ;
History for variable 'CC1' from config 'config 2' created at 'file:line':
|- 0 
|  |- HISTORY FROM 'B' ALIASED TO 'config 1' 
|  |  |- 0 
|  |  |  |- HISTORY FROM 'B' ALIASED TO 'config 0' 
|  |  |  |  `- 0 
|  |  |  |     |- EVENT = CREATE AND SET. value = '1', category = 'CURRENT' at 'file:line', status = OK. 
|  |  |  |     `- TIME = 0 
|  |  |  `- TIME = 2 
|  |  |- 1 
|  |  |  |- EVENT = CREATE AND SET. value = '1', category = 'A' at 'file:line', status = OK. 
|  |  |  `- TIME = 3 
|  |  `- 2 
|  |     |- EVENT = SET. value = '1.1', category = 'A' at 'file:line', status = OK. 
|  |     `- TIME = 6 
|  `- TIME = 3 
`- 1 
   |- EVENT = CREATE AND SET. value = 'A', OVERRIDE, category = 'A' at 'file:line', status = OK. 
   `- TIME = 4 
EOD

my $dump = $config_2->GetHistoryDump(NAME => 'CC1') ;
is($dump, $expected_dump, 'history dump') ;

$expected_dump = <<EOD ;
History for variable 'XYZ' from config 'config 2' created at 'file:line':
`- 0 
   |- EVENT = CREATE AND SET. value = 'xyz', category = 'A' at 'file:line', status = OK. 
   `- TIME = 5 
EOD

$dump = $config_2->GetHistoryDump(NAME => 'XYZ') ;
is($dump, $expected_dump, 'history dump without aliases') ;

throws_ok
	{
	$dump = $config_2->GetHistoryDump('NAME') ;
	} qr/Invalid number of argument!/, 'Invalid number of argument' ;
	
throws_ok
	{
	$dump = $config_2->GetHistoryDump(FILE => 'file', LINE => 'line', CATEGORIES_TO_EXTRACT_FROM => ['A', 'B']) ;
	} qr/Missing name /, 'Missing name ' ;

$expected_dump = <<EOD ;
History for variable 'CC1' from config 'config 2' created at 'file:line':
`- 0 
   |- HISTORY FROM 'B' ALIASED TO 'config 1' 
   |  |- 0 
   |  |  |- HISTORY FROM 'B' ALIASED TO 'config 0' 
   |  |  |  `- 0 
   |  |  |     |- EVENT = 'CREATE AND SET. value = '1', category = 'CURRENT' at 'file:line', status = OK.' 
   |  |  |     `- TIME = '0' 
   |  |  `- TIME = '2' 
   |  |- 1 
   |  |  |- EVENT = 'CREATE AND SET. value = '1', category = 'A' at 'file:line', status = OK.' 
   |  |  `- TIME = '3' 
   |  `- 2 
   |     |- EVENT = 'SET. value = '1.1', category = 'A' at 'file:line', status = OK.' 
   |     `- TIME = '6' 
   `- TIME = '3' 
EOD

$dump = $config_2->GetHistoryDump(CATEGORIES_TO_EXTRACT_FROM => ['B'], NAME => 'CC1', DATA_TREEDUMPER_OPTIONS => [QUOTE_VALUES => 1]) ;
is($dump, $expected_dump, 'history dump without aliases') ;
}

