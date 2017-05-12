use 5.006;use strict;use warnings FATAL => 'all';use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Class::Property',
    AUTHOR              => 'Alexandr Evstigneev <hurricup@evstigneev.com>',
    VERSION_FROM        => 'lib/Class/Property.pm', 
    ABSTRACT_FROM       => 'lib/Class/Property.pm', 
    MIN_PERL_VERSION    => 5.016,
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
        'Scalar::Util' => 0,
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
                'web' => 'https://github.com/hurricup/Class-Property/issues'
            },
            'repository' => {
                'type' => 'git',
                'url' => 'git://github.com/hurricup/Class-Property.git',
                'web' => 'https://github.com/hurricup/Class-Property',
            },
        },
    },    
);
