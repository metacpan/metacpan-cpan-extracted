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
local $Plan = {'lock category' => 1} ;

throws_ok
	{
	my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['A', 'B', 'C'],
			DEFAULT_CATEGORY => 'B',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A',              },
				{CATEGORY => 'B', NAME => 'CC', VALUE => 'B', OVERRIDE => 1},
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
				
			LOCKED_CATEGORIES => 'A',	
			) ;
			
	} qr/Invalid 'LOCKED_CATEGORIES'/, "Invalid 'LOCKED_CATEGORIES'" ;
}

{
local $Plan = {'lock category' => 7} ;

my $config ;

warnings_like
	{
	$config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['A', 'B', 'C'],
			DEFAULT_CATEGORY => 'B',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A',              },
				{CATEGORY => 'B', NAME => 'CC', VALUE => 'B', OVERRIDE => 1},
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A'},
				] ,
			INTERACTION            =>
				{
				# work around error in Test::Warn
				WARN  => sub{my $message = join(' ', @_) ; $message =~ s[\n][]g ;  use Carp ;carp $message; },
				},
			LOCKED_CATEGORIES => ['A', 'C'],	
			) ;
			
	is($config->Get(NAME => 'CC'), 'B', 'override is sticky') ;
	is($config->Get(NAME => 'CC', CATEGORIES_TO_EXTRACT_FROM => ['A']), 'A', 'locked categories are initialized') ;
	}
	[
	#~ # check which warnings are generated
	qr/Setting 'B::CC'.*Overriding 'A::CC'/,
	qr/Variable 'A::CC' was overridden/,
	], "override warnings" ;
	
throws_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'A', VALUE => 1) ;
	} qr/category 'A' was locked/, "can't write a locked category" ;
	
throws_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'A', VALUE => 1, FORCE_LOCK => 1) ;
	} qr/category 'A' was locked/, "can't FORCE_LOCK a locked category" ;

throws_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'C', VALUE => 1) ;
	} qr/category 'C' was locked/, "can't write a locked category" ;
	
$config->UnlockCategories('C') ;	
lives_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'C', VALUE => 1) ;
	} "can write an unlocked category" ;

}

{
local $Plan = {'lock category' => 11} ;

my $config;

warnings_like
	{
	$config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['A', 'B', 'C'],
			DEFAULT_CATEGORY => 'B',
			INITIAL_VALUES   =>
				[
				{CATEGORY => 'A', NAME => 'CC', VALUE => 'A',              },
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
	], "override warnings" ;
	
$config->LockCategories('A') ;	

throws_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'A', VALUE => 1) ;
	} qr/category 'A' was locked/, "can't write a locked category" ;
	
throws_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'A', VALUE => 1, FORCE_LOCK => 1) ;
	} qr/category 'A' was locked/, "can't FORCE_LOCK a locked category" ;
	
	
$config->LockCategories('C') ;	

throws_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'C', VALUE => 1, FORCE_LOCK => 1) ;
	} qr/category 'C' was locked/, "can't write a locked category" ;
	
$config->UnlockCategories('C') ;	

lives_ok
	{
	$config->Set(NAME => 'WHATEVER', CATEGORY => 'C', VALUE => 1) ;
	} "can write an unlocked category" ;

throws_ok
	{
	$config->LockCategories('X') ;	
	} qr/Invalid category 'X'/, "can't lock unexisting category" ;

throws_ok
	{
	$config->IsCategoryLocked('X') ;	
	} qr/Invalid category 'X'/, "unexisting category" ;

throws_ok
	{
	$config->IsCategoryLocked() ;	
	} qr/No category/, "No category" ;

is($config->IsCategoryLocked('A'), 1, 'locked') ;
is($config->IsCategoryLocked('C'), 0, 'not locked') ;

}
