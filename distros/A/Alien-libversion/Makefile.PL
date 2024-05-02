#!perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME               => 'Alien::libversion',
    DISTNAME           => 'Alien-libversion',
    VERSION_FROM       => 'lib/Alien/libversion.pm',
    ABSTRACT_FROM      => 'lib/Alien/libversion.pm',
    LICENSE            => 'artistic_2',
    CONFIGURE_REQUIRES => {'Alien::Build::MM' => 0,},
    BUILD_REQUIRES     => {'Alien::Build::MM' => 0, 'Alien::cmake3' => 0},
    PREREQ_PM          => {'Alien::Base'      => 0,},
    TEST_REQUIRES      => {'Test::Alien'      => 0, 'Test2::V0' => 0},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-Alien-libversion/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-Alien-libversion',
                web  => 'https://github.com/giterlizzi/perl-Alien-libversion'
            },
        },
        x_purl => 'pkg:cpan/GDT/Alien-libversion'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Alien-libversion-*'},
));

sub MY::postamble {
    $abmm->mm_postamble;
}
