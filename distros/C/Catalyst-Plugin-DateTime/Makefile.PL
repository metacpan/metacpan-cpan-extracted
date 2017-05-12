use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Plugin::DateTime',
    ABSTRACT  => 'DateTime plugin for Catalyst',	
    AUTHOR    => 'James Kiser (james.kiser@gmail.com)',
    PREREQ_PM => {
        'Catalyst'		=> '2.99',
        'DateTime'		=> '0.20',
    },
    VERSION_FROM => 'lib/Catalyst/Plugin/DateTime.pm'
);
