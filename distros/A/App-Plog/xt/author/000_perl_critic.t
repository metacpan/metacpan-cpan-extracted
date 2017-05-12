# perl_critic test

use strict ;
use warnings ;
use Term::ANSIColor qw(:constants) ;

#~ use Test::More skip_all => 'perl_critic' ;

use Test::Perl::Critic 
	-severity => 1,
	#~ -format =>  "[%s] %m at '%f:" . RED . "%l" . RESET .  ":%c ' rule %p %e\n\t" . BOLD . BLUE . "%r" . RESET ,
	-format =>  '[%s]' . RED . "%l" . RESET .  ":%c '%f : %m, %p \n\t" . BOLD . BLUE . "%r" . RESET ,
	#~ -format =>  "[%s] %m at '%f:" . BOLD . RED . "%l" . RESET . "'. %e\n",
	#~ -format =>  "[%s] %m at " . BOLD . BLUE . "%F:%l" . RESET . ". %e\n",
	-exclude =>
		[
		'Miscellanea::RequireRcsKeywords',
		'NamingConventions::ProhibitMixedCaseSubs',
		'ControlStructures::ProhibitPostfixControls',
		'CodeLayout::ProhibitParensWithBuiltins',
		'Documentation::RequirePodAtEnd',
		'ControlStructures::ProhibitUnlessBlocks',
		'CodeLayout::RequireTidyCode',
		'CodeLayout::ProhibitHardTabs',
		'CodeLayout::ProhibitTrailingWhitespace' ,
		'ValuesAndExpressions::ProhibitCommaSeparatedStatements', # too many false positives. See RT #27654
		], 
		
	-profile => 'xt/author/perlcriticrc' ;

all_critic_ok() ;
	
