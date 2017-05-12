use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Data::BISON',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    VERSION_FROM  => 'lib/Data/BISON.pm',
    ABSTRACT_FROM => 'lib/Data/BISON.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'            => 0,
        'version'               => 0,
        'Carp'                  => 0,
        'Config'                => 0,
        'Encode'                => 0,
        'Scalar::Util'          => 0,
        'Scalar::Util::Numeric' => '0.02',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Data-BISON-*' },
);
