#!perl

use 5.006000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Config::OpenSSH::Authkey',
  VERSION_FROM => 'lib/Config/OpenSSH/Authkey.pm',
  PREREQ_PM    => {
    'Carp'       => 0,
    'IO::Handle' => 0,
    'Test::More' => 0,
  },
  ( $] >= 5.005
    ? (
      ABSTRACT_FROM => 'lib/Config/OpenSSH/Authkey.pm',
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
      homepage   => 'https://github.com/thrig/Config-OpenSSH-Authkey',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'https://github.com/thrig/Config-OpenSSH-Authkey',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.006000;
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
