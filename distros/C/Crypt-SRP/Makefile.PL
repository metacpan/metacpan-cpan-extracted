use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Crypt::SRP',
    AUTHOR       => 'Karel Miko',
    VERSION_FROM => 'lib/Crypt/SRP.pm',
    ABSTRACT     => 'Secure Remote Protocol',
    LICENSE      => 'perl_5',
    PREREQ_PM    => {
      'CryptX'       => '0.074',   # we need: Crypt::Misc + Math::BigInt::LTM (v0.074 = 2021-11-06)
      'Math::BigInt' => '1.88',    # many things fail with Math::BigInt older than 1.88
    },
    MIN_PERL_VERSION => '5.006',
    META_MERGE       => {
      resources => {
        repository => 'https://github.com/DCIT/perl-Crypt-SRP',
        bugtracker => 'https://github.com/DCIT/perl-Crypt-SRP/issues',
      },
    },
    dist => {
      PREOP    => 'perldoc -u lib/Crypt/SRP.pm | pod2markdown > README.md',
      TAR      => 'ptar',
      TARFLAGS => '-c -C -f'
      #TARFLAGS => '--owner=0 --group=0 -cvf',
    },
);
