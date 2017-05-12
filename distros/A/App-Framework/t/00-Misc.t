#!perl

use Test::More;

use App::Framework ;

	## expand keys

	my %vars = (
		'var1'		=> 'this is a var',
		'var2'		=> 'another var',
	) ;
	my %hash = (
		'v1v2'		=> '$$var1${var1}$var2$var1$var2',
		'simple'	=> 'a simple var',
		'single'	=> 'contains $simple',
		'esc'		=> 'contains \$simple',
		'esc2'		=> 'contains $$simple',
		'single2'	=> 'this has $var1 and $var2',
		'multi'		=> 'contains $single2 and $var1',
		'multi2'	=> '$multi and contains $single',
		'multi3'	=> '$$multi2${multi2}\$multi${multi}$$single2$single2$$esc2$esc2$$esc$esc\${single}$single$${simple}$simple$$var1$var1$$var2$var2',
	) ;
	
	my %expect = (
		'v1v2'		=> '$var1this is a varanother varthis is a varanother var',
		'simple'	=> 'a simple var',
		'single'	=> 'contains a simple var',
		'esc'		=> 'contains $simple',
		'esc2'		=> 'contains $simple',
		'single2'	=> 'this has this is a var and another var',
		'multi'		=> 'contains this has this is a var and another var and this is a var',
		'multi2'	=> 'contains this has this is a var and another var and this is a var and contains contains a simple var',

		'multi3'	=> '$multi2contains this has this is a var and another var and this is a var and contains contains a simple var$multicontains this has this is a var and another var and this is a var$single2this has this is a var and another var$esc2contains $simple$esccontains $simple$singlecontains a simple var$simplea simple var$var1this is a var$var2another var',
	) ;
	
	

	plan tests => 1 ;
	go() ;
	
#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;

$App::Framework::Base::class_debug = 5 ;

	$app->expand_keys(\%hash, [\%vars]) ;

	$app->prt_data("HASH=", \%hash) ;	
	
	is_deeply(\%hash, \%expect, "Key expansion") ;
	
}