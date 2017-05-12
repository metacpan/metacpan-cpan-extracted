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
      'CryptX'       => '0.029',   # we need: Crypt::Misc + Math::BigInt::LTM (v0.029 = Apr 13, 2016)
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
      PREOP    => 'pod2text lib/Crypt/SRP.pm > README',
      TAR      => 'ptar',
      TARFLAGS => '-c -C -f'
      #TARFLAGS => '--owner=0 --group=0 -cvf',
    },
);
