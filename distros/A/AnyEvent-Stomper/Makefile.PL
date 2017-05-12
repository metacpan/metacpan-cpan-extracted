use 5.008000;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'AnyEvent::Stomper',
  VERSION_FROM     => 'lib/AnyEvent/Stomper.pm',
  MIN_PERL_VERSION => '5.008000',
  PREREQ_PM        => {
    'AnyEvent'        => '6.01',
    'Scalar::Util'    => '0',
    'List::MoreUtils' => '0.410',
    'Carp'            => '0',
    version           => '0.77',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },
  BUILD_REQUIRES => {
    'Test::More'       => '0.98',
    'Test::Fatal'      => '0.013',
    'Test::MockObject' => '1.20150527',
  },
  META_MERGE => {
    resources => {
      homepage   => 'https://github.com/iph0/AnyEvent-Stomper',
      bugtracker => 'https://github.com/iph0/AnyEvent-Stomper/issues',
      repository => 'https://github.com/iph0/AnyEvent-Stomper',
      license    => 'http://dev.perl.org/licenses/',
    },
  },
  ABSTRACT_FROM => 'lib/AnyEvent/Stomper.pm',
  AUTHOR        => 'Eugene Ponizovsky <ponizovsky@gmail.com>',
  LICENSE       => 'perl',
);

