use v5.10;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Assert::Conditional',
    AUTHOR           => q{Tom Christiansen <tchrist@perl.com>},
    VERSION_FROM     => 'lib/Assert/Conditional.pm',
    ABSTRACT_FROM    => 'lib/Assert/Conditional.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.012,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'            => 1.001014,
        'Test::Exception'       => 0.38,
        'Test::CheckManifest'   => 0.9,
        'Test::Pod::Coverage'   => 1.08,
        'Pod::Coverage'         => 0.18,
        'IO::File'              => 0,
        'IO::Handle'            => 0,
    },
    PREREQ_PM => {

        "parent"                     =>  0,
        "Attribute::Handlers"        =>  0,
        "Exporter"                   =>  5.54,
        "Exporter::ConditionalSubs"  =>  1.01,
        "File::Basename"             =>  0,
        "File::Spec"                 =>  0,
        "POSIX"                      =>  0,
        "Scalar::Util"               =>  0,
        "Tie::Hash"                  =>  0,
        "Unicode::Collate"           =>  0,
        "Unicode::Normalize"         =>  0,

    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Assert-Conditional-*' },
);
