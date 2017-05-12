use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Captcha::reCAPTCHA',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Captcha/reCAPTCHA.pm',
    ABSTRACT_FROM => 'lib/Captcha/reCAPTCHA.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'HTML::Tiny'     => '0.904',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Captcha-reCAPTCHA-*' },
);
