use 5.10.1;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Cache::Memcached::Turnstile',
    VERSION_FROM      => 'lib/Cache/Memcached/Turnstile.pm', # finds $VERSION
    PREREQ_PM         => {
      POSIX                  => '0',
      'Test::More'           => '0.88',
      'Time::HiRes'          => '0',
      'Clone'                => '0',
      'Data::Dumper'         => '0',
      'Constant::FromGlobal' => '0',
      Exporter               => '0',
      constant               => '0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Cache/Memcached/Turnstile.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);
