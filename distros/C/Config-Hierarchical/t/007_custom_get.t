# custom get test

use strict ;
use warnings ;
use Test::Exception ;

use Test::More 'no_plan';
use Test::Block qw($Plan);
use Test::Warn;
use Test::NoWarnings ;

use Config::Hierarchical ; 

{
local $Plan = {'custom get' => 4} ;

my $config ;
warnings_like
	{
	$config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['CLI', '<PBS>', 'PARENT', '<LOCAL>', 'CURRENT', ],
			DEFAULT_CATEGORY => 'CURRENT',
			GET_CATEGORIES   => 
				{
				Inheritable => ['CLI', 'PBS', 'PARENT', 'CURRENT'], # no local
				},
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'PBS'    , NAME => 'CC', VALUE => 'PBS_CC'},
				{CATEGORY => 'PARENT' , NAME => 'CC', VALUE => 'PARENT_CC'},
				{CATEGORY => 'LOCAL'  , NAME => 'AR', VALUE => 'LOCAL_AR'},
				{CATEGORY => 'CURRENT', NAME => 'AR', VALUE => 'CURRENT_AR', OVERRIDE => 1},
				] ,
				
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			) ;
			
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'PARENT::CC'.*'<PBS>::CC' takes precedence/,
	qr/Setting 'CURRENT::AR'.*'<LOCAL>::AR' takes precedence/,
	], "override and precedence warnings" ;

#diag DumpTree $config ;

# custom get
is($config->Get(NAME => 'AR'), 'LOCAL_AR', 'local value') ;
is($config->GetInheritable(NAME => 'AR'), 'CURRENT_AR', 'inheritable value') ;

# custom get hash ref
is_deeply(scalar($config->GetInheritableHashRef()),{AR => 'CURRENT_AR', CC => 'PBS_CC'}, 'expected values') ;

# what limitations in the get_categories order do we have?
# problem when a high prio category is overriden and the overriding category is not part of the get list
}
