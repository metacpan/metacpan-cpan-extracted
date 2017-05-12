package Apache::LogFile::Config;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Apache::src ();
use Apache::ExtUtils qw(command_table);

command_table([{
       name => "PerlLogFile",
       errmsg => "a file name and filehandle name",
       args_how => "TAKE2",
       req_override => "RSRC_CONF",
}]);

WriteMakefile(
    'NAME'	=> 'Apache::LogFile::Config',
    'VERSION_FROM' => 'Config.pm', # finds $VERSION
    'INC'	=> Apache::src->new->inc,
    'clean' => { FILES => "Config.xs Config.xs.orig" },
);
