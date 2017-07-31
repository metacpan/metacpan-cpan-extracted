#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 0.018_000;

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

WriteMakefile($abmm->mm_args(
    NAME         => 'Alien::PCRE2',
    DISTNAME     => 'Alien-PCRE2',
    ABSTRACT     => 'Find Or Download/Build/Install libpcre2 In PCRE2',
    VERSION_FROM => 'lib/Alien/PCRE2.pm',
    AUTHOR           => 'Will Braswell <wbraswell@cpan.org>',
    LICENSE          => 'perl_5',
#    EXE_FILES        => ['bin/pcre2-config', 'bin/pcre2grep', 'bin/pcre2test'],  # error, no rule to make target 'bin/pcre2grep'

    CONFIGURE_REQUIRES => {
        'IO::Socket::SSL'       => '2.043',
        'Alien::Build'          => '0.66',  # provides Alien::Build::MM
        %{$configure_requires_windows}
    },

    PREREQ_PM => {
        'Test2::Suite'          => '0.000072',  # provides Test2::V0
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
