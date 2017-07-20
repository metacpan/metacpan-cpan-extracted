#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 0.042_000;

use ExtUtils::MakeMaker;
use Alien::Build::MM;

BEGIN { 
    use Config;
    use English qw(-no_match_vars);  # for $OSNAME

    # remove previous Alien build directory, ensure only one build process to be found by t/02_make_check.t
    use File::Path qw(remove_tree);
    my $removed_count = remove_tree('_alien');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after calling remove_tree('_alien'), have $removed_count = }, $removed_count, "\n\n";
}

# fix read-only blib/lib in MS Windows
if ( $OSNAME eq 'MSWin32' ) {
    push( @ExtUtils::MakeMaker::Overridable, qw(pm_to_blib) );
}

my $abmm = Alien::Build::MM->new;

WriteMakefile($abmm->mm_args(
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
        'Alien::Build'          => '0.61',  # provides Alien::Build::MM
        'Alien::Build::MM'      => '0.61',
        'Alien::PCRE2'          => '0.012',  # DEV NOTE, CORRELATION #aj00: NEED ANSWER, DOES THIS WORK VIA cpanm???
        'File::Find::Rule'      => '0.34',  # used to find config.status file in t/02_make_check.t
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
