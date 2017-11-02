#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 0.051_000;

use ExtUtils::MakeMaker;
use Alien::Build::MM;

BEGIN { 
    use Config;
    use English qw(-no_match_vars);  # for $OSNAME
}

# MS Windows OS, fix read-only blib/lib directory & enable GNU configure/make
my $configure_requires_windows = {};
if ( $OSNAME eq 'MSWin32' ) {
    push( @ExtUtils::MakeMaker::Overridable, qw(pm_to_blib) );
    $configure_requires_windows = {
        'Alien::MSYS'  => '0.08',
        'Alien::gmake' => '0.20',
    };
}

my $abmm = Alien::Build::MM->new;

my %WriteMakefile_args = $abmm->mm_args(
    NAME         => 'Alien::JPCRE2',
    DISTNAME     => 'Alien-JPCRE2',
    ABSTRACT     => 'Find Or Download/Build/Install libjpcre2 In JPCRE2',
    VERSION_FROM => 'lib/Alien/JPCRE2.pm',
    AUTHOR           => 'Will Braswell <wbraswell@cpan.org>',
    LICENSE          => 'perl_5',
#    EXE_FILES        => ['bin/foo'],  # error, no rule to make target 'bin/foo'
    MAKE             => 'gmake',

    CONFIGURE_REQUIRES => {
        # DEV NOTE, CORRELATION #ap001: must install IO::Socket::SSL & Alien::Build from Makefile.PL (which becomes META.json, for CPAN) & .travis.yml & appveyor.yml 
        'IO::Socket::SSL'       => '2.043',
        'Alien::Build'          => '0.66',  # provides Alien::Build::MM
        'Alien::PCRE2'          => '0.014',
        %{$configure_requires_windows}
    },

    TEST_REQUIRES => {
        'Test2::Suite'          => '0.000072',  # provides Test2::V0
    },

    META_MERGE => {
        'meta-spec' => {
            version => '2',
            url     => 'https://metacpan.org/pod/CPAN::Meta::Spec'
        },

        release_status => 'stable',
        keywords       => [qw(alien pcre pcre2 jpcre2 regex regularexpression)],
        description    => 'JPCRE2 is the C++ wrapper for the new Perl Compatible Regular Expression engine, written in C, compiled and installed via Alien',
        resources => {
            license    => ['http://dev.perl.org/licenses/'],
            homepage   => 'https://neurobin.org/projects/softwares/libs/jpcre2/',
            bugtracker => { web => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Alien-JPCRE2' },
            repository => {
                type => 'git',
                url  => 'git://github.com/wbraswell/alien-jpcre2.git',
                web  => 'https://github.com/wbraswell/alien-jpcre2',
            },
            x_IRC         => "irc://irc.perl.org/#native",
#            x_mailinglist => "https://NONE",
#            x_wiki        => "https://NONE",
        },
    },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefile_args{TEST_REQUIRES};
    my $build_requires = delete $WriteMakefile_args{BUILD_REQUIRES};
    $WriteMakefile_args{PREREQ_PM}{$_} = $test_requires->{$_} for keys %$test_requires;
    $WriteMakefile_args{PREREQ_PM}{$_} = $build_requires->{$_} for keys %$build_requires;
}

delete $WriteMakefile_args{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };

WriteMakefile(%WriteMakefile_args);


package MY;
BEGIN { use English; }

sub postamble {
    $abmm->mm_postamble;
}

sub pm_to_blib {
    my $self = shift;
    my $blib = $self->SUPER::pm_to_blib(@_);

    # un-read-only blib/lib for tests to pass, files are modified at runtime there
    if ( $OSNAME eq 'MSWin32' ) {
        my ( $lastline, $start ) = qq{\t\$(NOECHO) \$(TOUCH) pm_to_blib\n};
        ( $start = index( $blib, $lastline ) ) == -1
            && die "Can't find replacement string for pm_to_blib target";
        substr( $blib, $start, 0, "\t" . 'attrib -R /S  blib/lib/*' . "\n" );
    }
    return $blib;
}
