use strict;
use warnings;

use Alien::Build::MM;
use ExtUtils::MakeMaker;

my $module_file = 'lib/Alien/nghttp3.pm';
my $module_version = MM->parse_version($module_file);
my $abmm = Alien::Build::MM->new;

WriteMakefile(
    $abmm->mm_args(
        NAME             => 'Alien::nghttp3',
        DISTNAME         => 'Alien-nghttp3',
        VERSION_FROM     => $module_file,
        ABSTRACT_FROM    => $module_file,
        AUTHOR           => 'Joshua S. Day <haxmeister@hotmail.com>',
        LICENSE          => 'mit',
        MIN_PERL_VERSION => '5.020',

        CONFIGURE_REQUIRES => {
            'Alien::Build::MM'   => '2.84',
            'ExtUtils::MakeMaker' => 0,
        },

        BUILD_REQUIRES => {
            'Alien::Build::MM' => '2.84',
        },

        PREREQ_PM => {
            'Alien::Base' => '2.84',
        },

        TEST_REQUIRES => {
            'Test2::V0'   => 0,
            'Test::Alien' => '2.84',
        },

        META_MERGE => {
            'meta-spec' => {
                version => 2,
            },
            provides => {
                'Alien::nghttp3' => {
                    file    => $module_file,
                    version => $module_version,
                },
            },
            resources => {
                homepage => 'https://github.com/haxmeister/perl-Alien-nghttp3',
                repository => {
                    type => 'git',
                    url  => 'https://github.com/haxmeister/perl-Alien-nghttp3.git',
                    web  => 'https://github.com/haxmeister/perl-Alien-nghttp3',
                },
                bugtracker => {
                    web => 'https://github.com/haxmeister/perl-Alien-nghttp3/issues',
                },
            },
        },
    )
);

sub MY::postamble {
    return $abmm->mm_postamble;
}
