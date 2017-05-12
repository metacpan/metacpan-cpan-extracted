# protected categories test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn ;
use Test::NoWarnings qw(had_no_warnings) ;

use Test::More 'no_plan';
use Test::Block qw($Plan);
  
use Config::Hierarchical ; 

{
local $Plan = {'protected categories names' => 1} ;

my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES => ['<CLI>'],
			INITIAL_VALUES =>
				[
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1,},
				],
			) ;
			
$config->Set(CATEGORY => 'CLI', NAME => 'CC', VALUE => 2) ;
is($config->Get(CATEGORY => 'CLI', NAME => 'CC'), 2, 'Get, protection brackets removed') ;
}

{
local $Plan = {'set protected categorvariable' => 2} ;

my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES => ['<CLI>'],
			INITIAL_VALUES =>
				[
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1,},
				],
			) ;
			
had_no_warnings('protection brackets removed') ;
is($config->Get(CATEGORY => 'CLI', NAME => 'CC'), 1, 'set protected categorvariable') ;
}

{
local $Plan = {'protected categories names' => 3} ;

dies_ok
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES => ['C<L>I'],
			INITIAL_VALUES =>
				[
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1,},
				],
			) ;
	} "<> not accepted" ;
	
dies_ok
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES => ['<C<L>I>'],
			INITIAL_VALUES =>
				[
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1,},
				],
			) ;
	} "<> not accepted" ;

dies_ok
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES => ['CL>I'],
			INITIAL_VALUES =>
				[
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1,},
				],
			) ;
	} "<> not accepted" ;
}

{
local $Plan = {'protected categories' => 2} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['CLI', '<PBS>', 'CURRENT', 'LOCAL'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'CLI'    , NAME => 'CC', VALUE => 1},
				{CATEGORY => 'PBS'    , NAME => 'CC', VALUE => 2, OVERRIDE => 1},
				{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 3, OVERRIDE => 1},
				{CATEGORY => 'LOCAL'  , NAME => 'CC', VALUE => 4, OVERRIDE => 1},
				] ,
				
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
			
	#~ # check values
	is($config->Get(NAME => 'CC'), 2, 'one protected, all override') ;
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'PBS::CC'.*Overriding 'CLI::CC'/,
	qr/Setting 'CURRENT::CC'.*'<PBS>::CC' takes precedence/,
	qr/Setting 'LOCAL::CC'.*Overriding 'CURRENT::CC'.*'<PBS>::CC' takes precedence/,
	], "override and precedence warnings" ;
	
}

{
local $Plan = {'protected categories' => 2} ;

warnings_like
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['CLI', '<PBS>', '<LOCAL>', 'CURRENT'],
			DEFAULT_CATEGORY => 'CURRENT',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'CLI'    , NAME => 'CC', VALUE => 1,              },
				{CATEGORY => 'PBS'    , NAME => 'CC', VALUE => 2, OVERRIDE => 1},
				{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 3, OVERRIDE => 1},
				{CATEGORY => 'LOCAL'  , NAME => 'CC', VALUE => 4, OVERRIDE => 1},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
			
	#~ # check values
	is($config->Get(NAME => 'CC'), 2, 'all override') ;
	
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'PBS::CC'.*Overriding 'CLI::CC'/,
	qr/Setting 'CURRENT::CC'.*'<PBS>::CC' takes precedence/,
	qr/Setting 'LOCAL::CC'.*'<PBS>::CC' takes precedence/,
	], "override and precedence warnings" ;
	
}

#~ use Data::TreeDumper ;
#~ diag DumpTree $config ;

