use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Password::Entropy',
    AUTHOR           => q{Oleg Alistratov <zero@cpan.org>},
    VERSION_FROM     => 'lib/Data/Password/Entropy.pm',
    ABSTRACT_FROM    => 'lib/Data/Password/Entropy.pm',
    LICENSE          => 'Artistic_2_0',

    META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'https://github.com/alistratov/data-password-entropy.git',
          web => 'https://github.com/alistratov/data-password-entropy',
        },
      },
    },
    
    PL_FILES         => {},
    INSTALLDIRS      => 'site',
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::More' => 0,
        'POSIX' => 0,
        'Encode' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Password-Entropy-*' },
);
