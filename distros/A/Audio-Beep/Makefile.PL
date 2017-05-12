use ExtUtils::MakeMaker;
use File::Copy;
use File::Spec::Functions;
use File::Path;

my %prereq = (
    'Test::More'    =>  0,
);
my @libs = ();

if ($^O eq 'MSWin32') {
    prompt(<<EOM) unless Win32::IsWinNT;
Currently the only Windows systems supported are NT, 2000 and XP.
I will install anyway, but beware the module won't work as supposed to.
PRESS [ENTER]
EOM
    $prepreq{'Win32::API'} = 0;
    @libs = (catdir(qw(lib Audio Beep Win32)));
} elsif ($^O eq 'freebsd') {
    prompt( <<EOM );
The port to FreeBSD is largely sperimental: please read documentation for
Audio::Beep::BSD::beep and report success or failure. Thank you.
PRESS [ENTER]
EOM
    #I include only FreeBSD cause i found a port of "beep" for that BSD
    #if you know of other BSDs where "beep" works, let me know
    @libs = (catdir(qw(lib Audio Beep BSD)));
} elsif ($^O eq 'linux') {
    @libs = (catdir(qw(lib Audio Beep Linux)));
} else {
    prompt( <<EOM );
Your operating system is not supported: 
i will install only the Audio::Beep module (no submodules)
NB: 'make test' will fail
PRESS [ENTER]
EOM
}

my $message = <<EOM;
Would you like to install Japanese documentation? 
If you enter 'y' then i will try to install Japanese docs alongside 
English ones. On platforms using 'man' manpages (typically on UN*X)
Japanese documentation will be available transparently to users whose 
locale language is set to Japanese.
On other platforms the documentation will be available as Audio::Beep_jp
Default is to not install Japanese docs. [N/y]
EOM
chop($message);

my $jp_docs = prompt($message);

$jp_docs = ($jp_docs =~ /^y(es)?$/i ? 1 : 0);

if ($jp_docs) {
    copy(catfile(qw(pods jp Beep.pod)), 'Beep_jp.pod');
}

WriteMakefile(
    NAME            => 'Audio::Beep',
    VERSION_FROM    => 'Beep.pm', 
    PREREQ_PM       => \%prereq,
    PMLIBDIRS       => \@libs,
    ($] >= 5.005 
        ? (
            ABSTRACT_FROM   => 'Beep.pod', 
            AUTHOR          => 'Giulio Motta <GIULIENK@cpan.org>'
        ) 
        : ()
    ),
);

if ($jp_docs) {
    local $| = 1;
    print "Tweaking Makefile for Japanese docs... ";
    my ($hack, $man3_dir);
    open(IN, 'Makefile') or die "Cannot read Makefile: $!";
    open(OUT, '> Makefile.hacked') or die "Cannot write to Makefile.hacked: $!";
    while (<IN>) {
        if (not $man3_dir and /INST_MAN3DIR\s*=\s*(\S+)/) {
            $man3_dir = $1;
        }
        if (/manifypods\s*:\s*/ .. /^$/) {
            s/Audio::Beep_jp/catfile(qw(jp Audio::Beep))/e and
                $hack = 1;
        }
        print OUT;
    }
    close(IN) or die "Cannot close Makefile: $!";
    close(OUT) or die "Cannot close Makefile.hacked: $!";
    if ($hack and $man3_dir) {
        mkpath(catdir($man3_dir, 'jp'));
        unlink('Makefile') or die "Cannot unlink Makefile: $!";
        rename('Makefile.hacked', 'Makefile') 
            or die "Cannot rename Makefile.hacked: $!";
        print "DONE (install with locale support)\n";
    } else {
        unlink 'Makefile.hacked';
        print "DONE (install as Audio::Beep_jp)\n";
    }
}

