use strict;
use XS::Install;

write_makefile(
    NAME      => 'Config::MorePerl',
    BIN_DEPS  => ['XS::Framework', 'Data::Recursive'],
    CCFLAGS   => '-Wall -Wextra',
    PREREQ_PM => {'Path::Class' => 0},
);
