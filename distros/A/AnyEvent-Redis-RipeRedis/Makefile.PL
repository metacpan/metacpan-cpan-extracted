use 5.008000;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'AnyEvent::Redis::RipeRedis',
  VERSION_FROM     => 'lib/AnyEvent/Redis/RipeRedis.pm',
  MIN_PERL_VERSION => '5.008000',
  PREREQ_PM        => {
    'AnyEvent'     => '6.01',
    'Encode'       => '0',
    'Scalar::Util' => '0',
    'Digest::SHA'  => '0',
    'Carp'         => '0',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.64',
  },
  BUILD_REQUIRES => {
    'Test::More'  => '0.98',
    'Test::TCP'   => '2.12',
    'Test::Fatal' => '0.013',
    'Time::HiRes' => '0',
    'File::Temp'  => '0.19',
    'POSIX'       => '0',
    version       => '0.77',
  },
  META_MERGE => {
    resources => {
      homepage   => 'https://github.com/iph0/AnyEvent-Redis-RipeRedis',
      bugtracker => 'https://github.com/iph0/AnyEvent-Redis-RipeRedis/issues',
      repository => 'https://github.com/iph0/AnyEvent-Redis-RipeRedis',
      license    => 'http://dev.perl.org/licenses/',
    },
  },
  ABSTRACT_FROM => 'lib/AnyEvent/Redis/RipeRedis.pm',
  AUTHOR        => 'Eugene Ponizovsky <ponizovsky@gmail.com>',
  LICENSE       => 'perl',
);
