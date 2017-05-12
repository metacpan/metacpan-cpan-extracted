use strict;
use warnings;
use ExtUtils::MakeMaker;

$^O =~ m/MSWin/i and die "OS unsupported";

WriteMakefile(
    NAME              => 'BGS',
    VERSION_FROM      => 'BGS.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'BGS.pm', # retrieve abstract from module
       AUTHOR         => 'Nick Kostirya <nick@ToDo.org>') : ()),
);
