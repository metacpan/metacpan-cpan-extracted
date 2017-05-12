use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::RESTModel',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Dancer/Plugin/RESTModel.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/RESTModel.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'         => '0.88',
        'Dancer'             => 0,
        'Role::REST::Client' => 0,
        'Moose'              => 0,
    },
    META_MERGE      => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-RESTModel',
            repository  => 'http://github.com/estantevirtual/Dancer-Plugin-RESTModel',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-RESTModel-*' },
);
