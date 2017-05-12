use 5.006;use strict;use warnings FATAL => 'all';use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Accessor::Lazy',
    AUTHOR              => 'Alexandr Evstigneev <hurricup@evstigneev.com>',
    VERSION_FROM        => 'lib/Class/Accessor/Lazy.pm', 
    ABSTRACT_FROM       => 'lib/Class/Accessor/Lazy.pm', 
    MIN_PERL_VERSION    => 5.008,
    LICENSE             => 'MIT',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Harness' => 0,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Exporter' => 0,
        'parent' => 0,
        'Class::Accessor' => 0,
        'Class::Accessor::Fast' => 0
    }, 
    META_MERGE        => {
        'meta-spec' => { 
            'version' => 2 
        },
        'resources' => {
            'license' => [
                'http://www.opensource.org/licenses/mit-license.php',
            ],
            'bugtracker' => {
                'web' => 'https://github.com/hurricup/Class-Accessor-Lazy/issues'
            },
            'repository' => {
                'type' => 'git',
                'url' => 'git://github.com/hurricup/Class-Accessor-Lazy.git',
                'web' => 'https://github.com/hurricup/Class-Accessor-Lazy',
            },
        },
    },    
);

