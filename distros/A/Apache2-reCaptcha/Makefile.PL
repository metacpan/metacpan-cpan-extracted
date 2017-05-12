use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Apache2::reCaptcha',
    AUTHOR        => 'Aaron Collins <analogrithems@gmail.com>',
    VERSION_FROM  => 'lib/Apache2/reCaptcha.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Captcha::reCAPTCHA'     => 0.92,
        'Test::More'     => 0,
        'LWP::UserAgent' => 0,
        'HTML::Tiny'     => '0.904',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'mod_reCaptcha-*' },
);
