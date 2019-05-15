use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
  NAME         => 'CPU::Emulator::Memory',
  META_MERGE => {
    license => 'open_source',
    resources => {
      repository => 'https://github.com/DrHyde/perl-modules-CPU-Emulator-Memory',
      bugtracker => 'https://github.com/DrHyde/perl-modules-CPU-Emulator-Memory/issues'
    },
  },
  VERSION_FROM => 'lib/CPU/Emulator/Memory.pm',
  PREREQ_PM    => {
    'Test::More'   => 0.88, # done_testing
    'Scalar::Util' => 0,
    'IO::Scalar'   => 0,
    'IO::File'     => 0,
  }
);
