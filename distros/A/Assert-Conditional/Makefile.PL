use v5.10;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => "Assert::Conditional",
    AUTHOR           => q{Tom Christiansen <tchrist@perl.com>},
    VERSION_FROM     => "lib/Assert/Conditional.pm",
    ABSTRACT_FROM    => "lib/Assert/Conditional.pm",
    LICENSE          => "perl_5",
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.012,
    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 0, # core
    },
    BUILD_REQUIRES => {
        "Carp::Always"             =>  0,
        "Hash::Util"               =>  0.12,    # core but gosh it's version dependent
        "IO::File"                 =>  0,       # core
        "IO::Handle"               =>  0,       # core
        "Moose"                    =>  0,       # alas to need this to test
        "Moose::Role"              =>  0,       # alas to need this to test
        "Pod::Coverage"            =>  0.18,
        "Test2::Tools::Exception"  =>  "0.000114",
        "Test::CheckManifest"      =>  0.9,
        "Test::Exception"          =>  0.38,
        "Test::More"               =>  1.001014,  # core
        "Test::Pod::Coverage"      =>  1.08,
    },
    PREREQ_PM => {
        "Attribute::Handlers"        =>  0,     # core
        "B::Deparse"                 =>  0,     # core
        "Cwd"                        =>  0,     # core
        "Env"                        =>  0,     # core
        "Exporter"                   =>  5.57,  # core
        "Exporter::ConditionalSubs"  =>  1.01,
        "File::Basename"             =>  0,     # core
        "File::Spec"                 =>  0,     # core
        "namespace::autoclean"       =>  0,
        "namespace::clean"           =>  0,
        "parent"                     =>  0,     # core as of 5.12
        "POSIX"                      =>  0,     # core
        "Scalar::Util"               =>  0,     # core
        "Tie::Hash"                  =>  0,     # core
        "Unicode::Collate"           =>  0,     # core
        "Unicode::Normalize"         =>  0,     # core
    },
    dist  => { COMPRESS => "gzip -9f", SUFFIX => "gz", },
    clean => { FILES => "Assert-Conditional-*" },
);
