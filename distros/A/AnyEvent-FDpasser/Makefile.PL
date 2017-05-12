use ExtUtils::MakeMaker;

use strict;

my $preop =
    'perldoc -uT $(VERSION_FROM) | tee $(DISTVNAME)/README.pod > README.pod;' .
    'pod2text README.pod | tee $(DISTVNAME)/README > README';

my $define;

if (exists $ENV{FDPASSER_SYSV}) {
  $define = '-DFDPASSER_SYSV';
} else {
  $define = '-DFDPASSER_BSD';
}

WriteMakefile(
  NAME => 'AnyEvent::FDpasser',
  VERSION_FROM => 'lib/AnyEvent/FDpasser.pm',
  LIBS => [''],
  OBJECT => 'FDpasser.o',
  DEFINE => $define,
  INC => '-I lib/',
  PREREQ_PM => {
    'common::sense' => 0,
    'AnyEvent' => 0,
  },
  dist => {
    PREOP => $preop,
  },
);
