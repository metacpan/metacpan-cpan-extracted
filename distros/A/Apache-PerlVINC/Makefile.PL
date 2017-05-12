package Apache::PerlVINC;

use ExtUtils::MakeMaker;

use Apache::ExtUtils qw(command_table);
use Apache::src ();

my @directives = ( 
	 	   { 
		    name     => 'PerlINC',
		    errmsg   => 'A path to add to @INC',
		    args_how => 'TAKE1',
		    req_override => 'OR_ALL',
		   },
	 	   { 
		    name     => 'PerlVersion',
		    errmsg   => 'A file name',
		    args_how => 'ITERATE',
		    req_override => 'OR_ALL',
		   },
		  );

command_table(\@directives);

WriteMakefile(
     'NAME'	=> __PACKAGE__,
     'VERSION_FROM' => 'PerlVINC.pm',
     'INC'	=> Apache::src->new->inc,
 );
