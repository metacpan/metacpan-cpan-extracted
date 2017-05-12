use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::Plugin::ForwardChained',
    ABSTRACT  => 'Forwarding to "Chain"-Actions in Catalyst',	
    AUTHOR    => 'Ulrich Kautz <uk@fortrabbit.de>',
    PREREQ_PM => {
        'Catalyst'  => '5.70',
    },
    VERSION_FROM => 'lib/Catalyst/Plugin/ForwardChained.pm'
);
