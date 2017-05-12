#!perl

use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Data::StackedMap',
    VERSION_FROM      => 'lib/Data/StackedMap.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {
        'Test::More' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/StackedMap.pm', # retrieve abstract from module
       AUTHOR         => 'Claes Jakobsson <claesjac@cpan.org>') : ()),
);
