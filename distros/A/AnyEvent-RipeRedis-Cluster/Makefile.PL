use 5.008000;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'AnyEvent::RipeRedis::Cluster',
  VERSION_FROM     => 'lib/AnyEvent/RipeRedis/Cluster.pm',
  MIN_PERL_VERSION => '5.008000',
  PREREQ_PM        => {
    'AnyEvent::RipeRedis' => '0.38',
    'AnyEvent'            => '6.01',
    'List::MoreUtils'     => '0.410',
    'Scalar::Util'        => '0',
    'Carp'                => '0',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },
  BUILD_REQUIRES => {
    'Test::More'       => '0.98',
    'Test::Fatal'      => '0.013',
    'Test::MockObject' => '1.20150527',
    'Clone'            => '0.38',
  },
  META_MERGE => {
    resources => {
      homepage   => 'https://github.com/iph0/AnyEvent-RipeRedis-Cluster',
      bugtracker => 'https://github.com/iph0/AnyEvent-RipeRedis-Cluster/issues',
      repository => 'https://github.com/iph0/AnyEvent-RipeRedis-Cluster',
      license    => 'http://dev.perl.org/licenses/',
    },
  },
  ABSTRACT_FROM => 'lib/AnyEvent/RipeRedis/Cluster.pm',
  AUTHOR        => 'Eugene Ponizovsky <ponizovsky@gmail.com>',
  LICENSE       => 'perl',
);
