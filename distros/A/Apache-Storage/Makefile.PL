package Apache::Storage;
use ExtUtils::MakeMaker;

#Kinda weird looking ain't it? -Brian

use Apache::ExtUtils qw (command_table);
use Apache::src ();
use Apache::Constants;

my @directives = (
	{ name			=> 'ApacheStorageInit',
	errmsg			=> 'Takes no parameters, only needs to be called if no ApacheStore directives are called',
	args_how		=> 'NO_ARGS',
	req_overrive => 'ACCESS_CONF'
	},
	{ name			=> 'ApacheStore',
	errmsg			=> 'Takes a keyword and either a string to be evalled or script',
	args_how		=> 'TAKE2',
	req_overrive => 'ACCESS_CONF'
	}
);

command_table(\@directives);

WriteMakefile(
    'NAME'	=> 'Apache::Storage',
    'VERSION_FROM' => 'Storage.pm',
    'INC'	=> Apache::src->new->inc, 
);
