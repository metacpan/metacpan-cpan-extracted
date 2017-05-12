#!perl

use 5.008000;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME         => 'Acme::NamespaceRoulette',
  VERSION_FROM => 'lib/Acme/NamespaceRoulette.pm',
  PREREQ_PM    => {},
  ( $] >= 5.005
    ?    ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM => 'lib/Acme/NamespaceRoulette.pm',
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
      homepage   => 'http://github.com/thrig/Acme-NamespaceRoulette',
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/thrig/Acme-NamespaceRoulette',
    }
  };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
  $params{MIN_PERL_VERSION} = 5.008000;
}

WriteMakefile( ( MM->can('signature_target') ? ( SIGN => 1 ) : () ), %params );
