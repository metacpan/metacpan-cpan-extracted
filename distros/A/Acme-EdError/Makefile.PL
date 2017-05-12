#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Acme::EdError',
  VERSION_FROM => 'lib/Acme/EdError.pm',
  PREREQ_PM    => {
    'IPC::Open3' => 1.0106,
    'Test::More' => 0.86,
  },
  ( $] >= 5.005
    ? (
      ABSTRACT_FROM => 'lib/Acme/EdError.pm',
      AUTHOR        => 'Jeremy Mates <jmates@cpan.org>'
      )
    : ()
  ),
);

if ( $ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/ and $ExtUtils::MakeMaker::VERSION > 6.30 ) {
  $params{LICENSE} = 'artistic_2';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
  $params{META_MERGE} = {
    resources => {
      homepage   => 'https://github.com/thrig/Acme-EdError',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'https://github.com/thrig/Acme-EdError',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.000000;
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
