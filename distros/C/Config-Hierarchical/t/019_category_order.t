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
local $Plan = {'CATEGORIES_TO_EXTRACT_FROM' => 13} ;

warning_like
	{
	my $config = new Config::Hierarchical
					(
					CATEGORY_NAMES         => [ 'PARENT', 'LOCAL', 'CURRENT', 'OVERRIDING_1', 'OVERRIDING_2'],
					DEFAULT_CATEGORY       => 'CURRENT',
							
					INITIAL_VALUES  =>
						[
						{NAME => 'variable', CATEGORY => 'PARENT', VALUE => 'parent'},
						{NAME => 'variable', CATEGORY => 'LOCAL', VALUE => 'local'},
						{NAME => 'variable', CATEGORY => 'CURRENT', VALUE => 'current'},
						{NAME => 'variable', CATEGORY => 'OVERRIDING_1', VALUE => 'overriding_1', OVERRIDE => 1},
						{NAME => 'variable', CATEGORY => 'OVERRIDING_2', VALUE => 'overriding_2', OVERRIDE => 1},
						] ,
						
					INTERACTION            =>
						{
						# work around error in Test::Warn
						WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
						}
					) ;
					
					
	is($config->Get(NAME => 'variable'), 'overriding_2', 'get value from overriding category') ;
	is($config->Get(NAME => 'variable', CATEGORIES_TO_EXTRACT_FROM => ['LOCAL', 'CURRENT']), 'local', 'get value from highest priority category') ;
	
	warning_like
		{
		is($config->Get(NAME => 'variable', CATEGORIES_TO_EXTRACT_FROM => ['CURRENT', 'LOCAL']), 'current', 'get value order given') ;
		} qr/unexpected order/, 'categories not in default order' ;
	
	is($config->Get(NAME => 'variable', CATEGORIES_TO_EXTRACT_FROM => ['LOCAL', 'OVERRIDING_1']), 'overriding_1', 'get value from overriding category') ;
	warning_like
		{
		is($config->Get(NAME => 'variable', CATEGORIES_TO_EXTRACT_FROM => ['OVERRIDING_1', 'LOCAL']), 'overriding_1', 'get value from overriding category') ;
		} qr/unexpected order/, 'categories not in default order' ;
	
	is($config->Get(NAME => 'variable', CATEGORIES_TO_EXTRACT_FROM => ['OVERRIDING_1', 'OVERRIDING_2']), 'overriding_2', 'get value from overriding category') ;
	warning_like
		{
		is($config->Get(NAME => 'variable', CATEGORIES_TO_EXTRACT_FROM => ['OVERRIDING_2', 'OVERRIDING_1']), 'overriding_2', 'get value from overriding category') ;
		} qr/unexpected order/, 'categories not in default order' ;
	}
	[
	qr/Setting 'LOCAL::variable'.*'PARENT::variable' takes precedence /,
	qr/Setting 'CURRENT::variable'.*'LOCAL::variable' takes precedence /,
	qr/Setting 'OVERRIDING_1::variable'.*Overriding /,
	qr/Setting 'OVERRIDING_2::variable'.*Overriding /,
	], 'setup warning' ;

warning_like
	{
	# same thing but with verbosity to cover all code
	my $config = new Config::Hierarchical
					(
					CATEGORY_NAMES         => [ 'LOCAL', 'CURRENT', 'OVERRIDING_1'],
					DEFAULT_CATEGORY       => 'CURRENT',
							
					VERBOSE => 1,
					
					INITIAL_VALUES  =>
						[
						{NAME => 'variable', CATEGORY => 'LOCAL', VALUE => 'local'},
						{NAME => 'variable', CATEGORY => 'CURRENT', VALUE => 'current'},
						{NAME => 'variable', CATEGORY => 'OVERRIDING_1', VALUE => 'OVERRIDING_1', OVERRIDE => 1},
						] ,
						
					INTERACTION            =>
						{
						# work around error in Test::Warn
						WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
						}
					) ;
					
					
	is($config->Get(NAME => 'variable', CATEGORIES_TO_EXTRACT_FROM => ['LOCAL', 'CURRENT']), 'local', 'get value from highest priority category') ;
	}
	[
	qr/Setting 'CURRENT::variable'.*'LOCAL::variable' takes precedence /,
	qr/Setting 'OVERRIDING_1::variable'.*Overriding /,
	], 'setup warning' ;
	
}
