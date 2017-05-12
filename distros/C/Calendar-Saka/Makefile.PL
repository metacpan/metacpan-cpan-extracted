use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Calendar::Saka',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Calendar/Saka.pm',
    ABSTRACT_FROM      => 'lib/Calendar/Saka.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'        => 0,
        'File::Temp'        => 0,
        'XML::SemanticDiff' => 0,
    },
    PREREQ_PM => {
        'Moo'                        => '2.000000',
        'namespace::clean'           => '0.24',
        'Date::Saka::Simple'         => '0.18',
        'Calendar::Plugin::Renderer' => '0.12',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Calendar-Saka-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Calendar::Saka' => { file => 'lib/Calendar/Saka.pm', version => '1.34' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Calendar-Saka.git',
                web  => 'https://github.com/manwar/Calendar-Saka',
            },
        }})
     : ()
    ),
);
