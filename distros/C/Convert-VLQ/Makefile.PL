#!env perl

use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Convert::VLQ',
    VERSION_FROM      => 'lib/Convert/VLQ.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { 
            Data::Dump => 1
        }, 
    ABSTRACT_FROM     => 'lib/Convert/VLQ.pm', # retrieve abstract from module
    AUTHOR            => 'Philip Gwyn <fil -at- cpan.org>',
    LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
