use ExtUtils::MakeMaker;
use Devel::PPPort;
use Config;
Devel::PPPort::WriteFile();
WriteMakefile(
  NAME => 'Data::PerfectHash::Shared', VERSION_FROM => 'lib/Data/PerfectHash/Shared.pm',
  ABSTRACT => 'Immutable shared-memory exact static set (CHD perfect hash)',
  AUTHOR => 'vividsnow', LICENSE => 'perl_5', MIN_PERL_VERSION => '5.22.0',
  CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, 'Devel::PPPort' => 0 },
  TEST_REQUIRES => { 'Test::More' => 0 },
  CCFLAGS => "$Config{ccflags} -std=gnu11", OBJECT => '$(O_FILES)',
  clean => { FILES => 'ppport.h' },
  test => { TESTS => 't/*.t' },
);
