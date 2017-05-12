use 5.006;use strict;use warnings FATAL => 'all';use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DTL::Fast',
    AUTHOR              => 'Alexandr Evstigneev <hurricup@evstigneev.com>',
    VERSION_FROM        => 'lib/DTL/Fast.pm', 
    ABSTRACT_FROM       => 'lib/DTL/Fast.pm', 
    MIN_PERL_VERSION    => 5.010,
    LICENSE             => 'MIT',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Harness' => 0,
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Date::Format' => 0,
        'URI::Escape::XS' => '0.12',
        'POSIX' => 0,
        'Storable' => 0,
        'Compress::Zlib' => 0, 
        'Digest::MD5' => 0, 
        'XSLoader' => 0,
		'parent' => 0,
		'Module::Load' => 0,
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
                'web' => 'https://github.com/hurricup/DTL-Fast/issues'
            },
            'repository' => {
                'type' => 'git',
                'url' => 'git://github.com/hurricup/DTL-Fast.git',
                'web' => 'https://github.com/hurricup/DTL-Fast',
            },
        },
    },    
);
