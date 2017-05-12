
# check stricture

use strict ;
use warnings ;
use Test::More 'no_plan' ;

my $alarm_reached = 0 ;
eval
	{
	local $SIG{ALRM} = sub {$alarm_reached++ ; die} ;
	alarm 1 ;
	
	eval
		{
		my $input = <STDIN> ;
		} ;
	
	alarm 0 ;
	} ;

alarm 0 ;

if($alarm_reached)
	{
	SKIP: 
		{
		skip 'Syntax ok and use strict (press key to run)', 1 ;
		}
	}
else
	{
	use Test::Strict;
	all_perl_files_ok();
	}
	