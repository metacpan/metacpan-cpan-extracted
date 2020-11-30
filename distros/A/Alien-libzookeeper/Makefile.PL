use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my %WriteMakefileArgs = (
    "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => "6.52",
        "Alien::Build::Plugin::Build::CMake"     => 0,
    },
    "PREREQ_PM" => {
        "Alien::Base" => "0.038",
        "Alien::Build::Plugin::Build::CMake"     => 0,
    },
    BUILD_REQUIRES => {
        "Alien::Base" => "0.038",
        "Alien::Build::Plugin::Build::CMake"     => 0,
        "Alien::cmake3"     => 0,

    },
    DISTNAME         => 'Alien-libzookeeper',
    NAME             => 'Alien::libzookeeper',
    AUTHOR           => q{B Fraser <fraserbn@gmail.com>},
    VERSION_FROM     => 'lib/Alien/libzookeeper.pm',
    ABSTRACT_FROM    => 'lib/Alien/libzookeeper.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Alien-libzookeeper-*' },
    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'git@github.com:Hugmeir/p5-alien-libzookeeper.git',
                web  => 'https://github.com/Hugmeir/p5-alien-libzookeeper',
            },
        },
    },
);

my $abmm = Alien::Build::MM->new;
%WriteMakefileArgs = $abmm->mm_args(%WriteMakefileArgs);

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  $abmm->mm_postamble;
}
