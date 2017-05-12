use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Config::Strict',
    AUTHOR        => q{Blake Willmarth <bwillmarth@gmail.com>},
    VERSION_FROM  => 'lib/Config/Strict.pm',
    ABSTRACT_FROM => 'lib/Config/Strict.pod',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'                   => 0.88,
        'Scalar::Util'                 => 0,
        'Declare::Constraints::Simple' => 0.03
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Config-Strict-*' },
);
