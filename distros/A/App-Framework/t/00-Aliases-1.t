#!perl
use Test::More;

use App::Framework ;

	plan tests => 3 ;
	go() ;
	
#		# alternates
#		['app_begin',	'app_start'],
#		['app_enter',	'app_start'],
#		['app_init',	'app_start'],

#		['app_finish',	'app_end'],
#		['app_exit',	'app_end'],
#		['app_term',	'app_end'],
	
#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
sub app_start
{
	my ($app) = @_ ;

	pass("In app start subroutine") ;	
}

#----------------------------------------------------------------------
sub app_begin
{
	my ($app) = @_ ;

	fail("In app begin subroutine") ;	
}

#----------------------------------------------------------------------
sub app_enter
{
	my ($app) = @_ ;

	fail("In app enter subroutine") ;	
}

#----------------------------------------------------------------------
sub app_init
{
	my ($app) = @_ ;

	fail("In app init subroutine") ;	
}




#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;

	pass("In app subroutine") ;	
}



#----------------------------------------------------------------------
sub app_end
{
	my ($app) = @_ ;

	pass("In app end subroutine") ;	
}

#----------------------------------------------------------------------
sub app_finish
{
	my ($app) = @_ ;

	fail("In app finish subroutine") ;	
}

#----------------------------------------------------------------------
sub app_exit
{
	my ($app) = @_ ;

	fail("In app exit subroutine") ;	
}


#----------------------------------------------------------------------
sub app_term
{
	my ($app) = @_ ;

	fail("In app term subroutine") ;	
}

