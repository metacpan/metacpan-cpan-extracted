#!/usr/bin/perl

use strict;
use warnings;
our $VERSION = 0.036_000;

use ExtUtils::MakeMaker;
use Alien::Build::MM;

BEGIN { 
    use Config;
    use English qw(-no_match_vars);  # for $OSNAME
    use Data::Dumper;  # DEBUG

    # remove previous Alien build directory, ensure only one build process to be found by t/02_make_check.t
    use File::Path qw(remove_tree);
    my $removed_count = remove_tree('_alien');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after calling remove_tree('_alien'), have $removed_count = }, $removed_count, "\n\n";

#=begin DISABLED_PCRE2_KLUDGE

    # DEV NOTE, CORRELATION #aj00: DOES work here FOR NON-WINDOWS ONLY SO FAR, Alien::PCRE2 must be installed in Makefile.PL BEGIN block
    # install Alien::PCRE2 if not already present, must be done here rather than in CONFIGURE_REQUIRES section below or "configure requires" section of alienfile,
    # otherwise Alien::PCRE2 will not be installed early enough to be used in the alienfile itself
    my $eval_retval = eval 'use Alien::PCRE2; 1;';
    if (not defined $eval_retval) {  # runtime error occurred, Alien::PCRE2 presumably not installed
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after calling eval 'use Alien::PCRE2; 1;', have $EVAL_ERROR = '}, $EVAL_ERROR, q{'}, "\n\n";
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, attempting to install Alien::PCRE2 via cpanm...}, "\n\n";

=begin DISABLED_CPAN

        $eval_retval = eval 'use CPAN; 1;';
        if (not defined $eval_retval) {  # runtime error occurred, CPAN presumably not installed
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after calling eval 'use CPAN; 1;', have $EVAL_ERROR = '}, $EVAL_ERROR, q{'}, "\n\n";
            die 'ERROR EAP00: Alien::PCRE2 and CPAN distributions are not installed, can not automatically install Alien::PCRE2 for use in alienfile, please manually install Alien::PCRE2, dying';
        }

        use Cwd;
        my $pre_cpan_dir = getcwd();
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, have $pre_cpan_dir = '}, $pre_cpan_dir, q{'}, "\n\n";

=end DISABLED_CPAN

=cut

        # NEED REMOVE: not needed?
#        use Env;
#        if ( $OSNAME eq 'MSWin32' ) {
#            $ENV{'MAKE'} = 'gmake_FROM_PERL_ENV';
#            $ENV{'HOWDY'} = 'YALL_FROM_PERL_ENV';  # NEED REMOVE, DEBUG
#        }
#print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, have %ENV = }, Dumper(\%ENV), "\n\n";

        # use cpanm to install Alien::PCRE2
        use IPC::Cmd qw(can_run);
        my $cpanm_path = can_run('cpanm');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, have $cpanm_path = '}, $cpanm_path, q{'}, "\n\n";
        if ((not defined $cpanm_path) or ($cpanm_path eq q{})) {
            die 'ERROR EAJ00: Alien::PCRE2 and cpanm are not installed, can not automatically install Alien::PCRE2 for use in alienfile, please manually install Alien::PCRE2, dying';
        }

        use Capture::Tiny qw( capture_merged );
        # run `cpanm Alien::PCRE2`, check for valid output
        my $cpanm_output;
        if ( $OSNAME eq 'MSWin32' ) { 
            $cpanm_output = [ split /\r?\n/, capture_merged { system 'set MAKE=gmake&& set MAKE_FROM=MAKEFILE_PL_SYSTEM && echo [[[ DEBUG ]]] INSIDE SYSTEM CALL  echo set && set && ' . $cpanm_path . ' --verbose Alien::PCRE2'; }];
#            $cpanm_output = [ split /\r?\n/, capture_merged { system 'set MAKE=gmake&& set MAKE_FROM=MAKEFILE_PL_SYSTEM && echo [[[ DEBUG ]]] INSIDE SYSTEM CALL && rename C:\strawberry\c\bin\dmake.exe Ddmake.exe && echo set && set && ' . $cpanm_path . ' --verbose Alien::PCRE2 && rename C:\strawberry\c\bin\Ddmake.exe dmake.exe'; }];
        }
        else {
            $cpanm_output = [ split /\r?\n/, capture_merged { system $cpanm_path . ' --verbose Alien::PCRE2'; }];
        }
print {*STDERR} "\n\n", '<<< DEBUG >>> in Makefile.PL, have $cpanm_output =', Dumper($cpanm_output), "\n\n";
        my $cpanm_output_success = 0;
        foreach my $cpanm_output_line (@{$cpanm_output}) {
#print {*STDERR} "\n\n", '<<< DEBUG >>> in Makefile.PL, have $cpanm_output_line =', $cpanm_output_line, "\n\n";
            if (substr($cpanm_output_line, 0, 34) eq 'Successfully installed Alien-PCRE2') {
print {*STDERR} "\n\n", '<<< DEBUG >>> in Makefile.PL, have $cpanm_output_line SUCCESS MATCH', "\n\n";
                $cpanm_output_success = 1;
                last;
            }
        }
        if (not $cpanm_output_success) {
            die 'ERROR EAJ01: `cpanm Alien::PCRE2` did not successfully install, can not automatically install Alien::PCRE2 for use in alienfile, please manually install Alien::PCRE2, dying';
        }

=begin DISABLED_CPAN

        # DISABLED: use cpanm to install Alien::PCRE2, because cpan keeps getting stuck at interactive configuration
        use CPAN;
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, about to call CPAN o conf defaults...}, "\n\n";
        CPAN::Shell->o('conf', 'defaults');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, about to call CPAN o conf commit...}, "\n\n";
        CPAN::Shell->o('conf', 'commit');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, about to call CPAN to install Alien::PCRE2...}, "\n\n";
        CPAN::Shell->install('Alien::PCRE2');
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, returned from call CPAN to install Alien::PCRE2}, "\n\n";

        my $post_cpan_dir = getcwd();
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, have $post_cpan_dir = '}, $post_cpan_dir, q{'}, "\n\n";
        chdir $pre_cpan_dir;
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, after chdir, have getcwd() = '}, getcwd(), q{'}, "\n\n";

=end DISABLED_CPAN

=cut

    }
    else {
print {*STDERR} q{<<< DEBUG >>> in Makefile.PL, NOT attempting to install Alien::PCRE2 via cpanm, it is already installed!  :-)}, "\n\n";
    }

#=end DISABLED_PCRE2_KLUDGE

#=cut

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
    MAKE_FROM        => 'MAKEFILE_PL_WRITEMAKEFILE',

    CONFIGURE_REQUIRES => {
        # DEV NOTE, CORRELATION #ap001: must install IO::Socket::SSL & Alien::Build from Makefile.PL (which becomes META.json, for CPAN) & .travis.yml & appveyor.yml 
        'IO::Socket::SSL'       => '2.043',
        'Alien::Build'          => '0.52',  # provides Alien::Build::MM
        'Alien::PCRE2'          => '0.006',  # DEV NOTE, CORRELATION #aj00: NEED ANSWER, DOES THIS WORK VIA cpanm???
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
