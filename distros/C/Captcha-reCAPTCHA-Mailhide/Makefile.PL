use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  NAME          => 'Captcha::reCAPTCHA::Mailhide',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  LICENSE       => 'perl',
  VERSION_FROM  => 'lib/Captcha/reCAPTCHA/Mailhide.pm',
  ABSTRACT_FROM => 'lib/Captcha/reCAPTCHA/Mailhide.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'      => 0,
    'Crypt::Rijndael' => 0,
    'MIME::Base64'    => 0,
    'HTML::Tiny'      => '0.904',
  },
  dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES => 'Captcha-reCAPTCHA-Mailhide-*' },
);
