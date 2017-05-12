use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Config::Files::Simple',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Config/Files/Simple.pm',
    ABSTRACT_FROM      => 'lib/Config/Files/Simple.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'      => 1.302031,
        'Hash::MD5'       => 0.08,
        'Path::Tiny'      => 0,
        'Test::Exception' => 0.43,
    },
    PREREQ_PM => {
        'Carp'                    => 0,
        'Exporter'                => 0,
        'JSON::Parse'             => 0,
        'String::Any::Extensions' => 0.01.1,
        'Module::Load'            => 0,
        'Ref::Util'               => 0,
        'YAML'                    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Config-Files-Simple-*' },
);
