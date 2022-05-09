#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 0.030_000;

use ExtUtils::MakeMaker;
use Alien::Build::MM;

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
    NAME         => 'Alien::PCRE2',
    DISTNAME     => 'Alien-PCRE2',
    ABSTRACT     => 'Find Or Download/Build/Install libpcre2 In PCRE2',
    VERSION_FROM => 'lib/Alien/PCRE2.pm',
    AUTHOR           => 'Will Braswell <wbraswell@cpan.org>',
    LICENSE          => 'perl_5',
#    EXE_FILES        => ['bin/pcre2-config', 'bin/pcre2grep', 'bin/pcre2test'],  # error, no rule to make target 'bin/pcre2grep'

    'BUILD_REQUIRES' => {
        'Alien::Build'          => '0.32',
        'Alien::Build::MM'      => '0.32',
        'ExtUtils::MakeMaker'   => '6.52'
    },
    'CONFIGURE_REQUIRES' => {
        'Alien::Build'          => '1.40',
        'Alien::Build::MM'      => '0.32',
        'ExtUtils::MakeMaker'   => '6.52'
    },
    'PREREQ_PM' => {
        'Alien::Base'           => '0.038',
        'base'                  => 0,
        'strict'                => 0,
        'warnings'              => 0
    },
    TEST_REQUIRES => {
        'Capture::Tiny'         => 0,
        'Data::Dumper'          => 0,
        'English'               => 0,
        'Env'                   => 0,
        'File::Spec'            => 0,
        'IPC::Cmd'              => 0,
        'Test2::V0'             => 0,
        'Test::Alien'           => 0,
        'Test::Alien::Diag'     => 0,
        'Test::More'            => 0,
    },

    META_MERGE => {
        'meta-spec' => {
            version => '2',
            url     => 'https://metacpan.org/pod/CPAN::Meta::Spec'
        },

        release_status => 'stable',
        keywords       => [qw(alien pcre pcre2 regex regularexpression)],
        description    => 'PCRE2 is the new Perl Compatible Regular Expression engine, written in C, compiled and installed via Alien',
        resources => {
            license    => ['http://dev.perl.org/licenses/'],
            homepage   => 'http://www.pcre.org',
            bugtracker => { web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Alien-PCRE2' },
            repository => {
                type => 'git',
                url  => 'git://github.com/wbraswell/alien-pcre2.git',
                web  => 'https://github.com/wbraswell/alien-pcre2',
            },
            x_IRC         => "irc://irc.perl.org/#native",
            x_mailinglist => "https://lists.exim.org/lurker/list/pcre-dev.html",
            x_wiki        => "https://en.wikipedia.org/wiki/Perl_Compatible_Regular_Expressions",
        },
    },
));

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
