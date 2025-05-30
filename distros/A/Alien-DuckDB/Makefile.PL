use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

my %WriteMakefileArgs = (
    NAME             => 'Alien::DuckDB',
    DISTNAME         => 'Alien-DuckDB',
    AUTHOR           => 'Chris Prather <chris@prather.org>',
    VERSION_FROM     => 'lib/Alien/DuckDB.pm',
    ABSTRACT_FROM    => 'lib/Alien/DuckDB.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.008004',
    CONFIGURE_REQUIRES => {
        'Alien::Build::MM' => '0.32',
        'Alien::Build'     => '0.32',
        'ExtUtils::MakeMaker' => '6.52',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
        'Test2::V0' => '0',
        'Test::Alien' => '0',
        'FFI::Platypus' => '0',
    },
    PREREQ_PM => {
        'Alien::Base'  => '0.038',
        'Path::Tiny'   => '0.122',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/perigrin/Alien-DuckDB.git',
                web  => 'https://github.com/perigrin/Alien-DuckDB',
            },
            bugtracker => {
                web => 'https://github.com/perigrin/Alien-DuckDB/issues',
            },
        },
    },
    clean => { FILES => 'Alien-DuckDB-* _alien' },
);

%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

# Handle postamble and install
{ package
    MY;
  sub postamble {
    $abmm->mm_postamble(@_);
  }
  sub install {
    $abmm->can('mm_install')
      ? $abmm->mm_install(@_)
      : shift->SUPER::install(@_);
  }
}

WriteMakefile(%WriteMakefileArgs);
