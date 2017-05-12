#!perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'CGI::Alternatives',
  ABSTRACT_FROM => 'lib/CGI/Alternatives.pm',
  VERSION_FROM  => 'lib/CGI/Alternatives.pm',
  AUTHOR        => 'Lee Johnson <leejo@cpan.org>',
  LICENSE       => 'perl',
  MIN_PERL_VERSION => '5.6.2',
  PREREQ_PM => {
  },
  BUILD_REQUIRES => {
    'Test::More'          => 0,
    'Test::Pod'           => 1.48,
    'Test::Pod::Coverage' => 1.08,
  },
  META_MERGE => {
    resources => {
      license    => 'http://dev.perl.org/licenses/',
      homepage   => 'https://metacpan.org/module/CGI::Alternatives',
      bugtracker => 'https://github.com/leejo/cgi-alternatives/issues',
      repository => 'https://github.com/leejo/cgi-alternatives'
    },
  },
  test => {
    TESTS => 't/*.t',
  },
);
