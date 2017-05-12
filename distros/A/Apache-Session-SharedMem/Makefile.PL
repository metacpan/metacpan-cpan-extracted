#
# Makefile.PL for Apache::Session::SharedMem distribution:
#       Apache::Session::SharedMem
#       Apache::Session::Store::SharedMem
#
# Filename:     Makefile.PL
# Author:       Simon Wistow
# Created:      10 December 2000
#


use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Apache::Session::SharedMem',
    'VERSION_FROM' => 'lib/Apache/Session/SharedMem.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Apache::Session' => 0, 'IPC::Cache' => 0, 'Apache::Session::Flex' => 0 },
);
