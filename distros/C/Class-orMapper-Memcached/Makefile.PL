use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::orMapper::Memcached',
    VERSION_FROM      => 'lib/Class/orMapper/Memcached.pm', # finds $VERSION
    PREREQ_PM         => {
        'String::CRC32' => '1.4',
        'DBI' => '1.627',
        'Cache::Memcached::Fast' => '0.21',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/orMapper/Memcached.pm', # retrieve abstract from module
       AUTHOR         => 'Kazunori Minoda <kazunori@cpan.org>') : ()),
);
