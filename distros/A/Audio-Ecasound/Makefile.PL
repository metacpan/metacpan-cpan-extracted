use ExtUtils::MakeMaker;
$| = 1;

WriteMakefile(
    NAME            => 'Audio::Ecasound',
    VERSION_FROM    => 'Ecasound.pm', 
    PREREQ_PM       => {}, # e.g., Module::Name => 1.1
    # next two could be from libecasoundc-config --libs --cflags
    # not for now since want it to install w/o libecasoundc-config
    LIBS            => ['-lecasoundc'], 
    INC             => '',
    ABSTRACT_FROM   => 'Ecasound.pm', 
    AUTHOR          => 'Brad Bowman <eci-perl@bereft.net>', 
    LICENSE         => 'artistic_2',
    dist            => { 
        # expand my tabs to 4
        PREOP => "(cd \$(DISTVNAME); \\
                    perl -MExtUtils::Manifest=maniread \\
                        -pi -e 'BEGIN{\@ARGV=keys \%{maniread()}; } \\
                                s/\\t/    /g' \\
                    )" },
    CONFIGURE       => 
        sub {
            my %cfg;
            use Config;

            unless ($Config{usethreads} eq 'define'
                ||  $Config{ccflags} =~ /\b-D_REENTRANT\b/) 
            {
                prompt_cont(<<EOT, 'y');
Your perl was not built with -Dusethreads or -D_REENTRANT
This may cause problems loading the multithreaded library 
ecasoundc  (hanging on loading).  It has worked fine for some.
You are welcome to try...

Proceed anyway?
EOT
            }
            
            # ecasound 2.4.4 http://www.eca.cx/ecasound-list/2006/12/0007.html
            # old: ecasound < 2.2 (v2.1dev8) mv'd headers and config prgm
            # old: ecasound < 2.0.1 didn't have reentrant C interface
            my $eca_version = `libecasoundc-config --version`;
            if(!defined($eca_version)) {
                warn "Running ecasoundc-config failed: $!\n";
                
                prompt_cont(<<EOT, 'y');
The ecasoundc-config program is used to find the version of the
ecasoundc library.  You need 2.4.5 or higher.

Proceed anyway?
EOT
            } else {
                chomp $eca_version;
                # Compare versions pre v-strings 
                my @ev = split /\./, $eca_version;
                # maj > 2 & rest >= 4.5
                unless($ev[0] >2 || ($ev[0] == 2 && "$ev[1].$ev[2]" >= '4.5')) {
                    prompt_cont(<<EOT, 'n');
Version 2.4.5+ of ecasound is required, you have $eca_version.
                   
Proceed anyway? (bad idea)
EOT
                }
            }
            unless ($ENV{ECASOUND}) {
                print <<EOT;

ECI now uses the "ECASOUND" env var to find the ecasound executable.
Set it correctly to suppress the library warning. 
(The PATH is searched so ECASOUND=ecasound usually works)

EOT
            }
            unless ($Config{ivsize} >= $Config{longsize}) {
                warn "long int is bigger than IV, may cause problems with last_long_interger\n";
            }
            return \%cfg;
        },
);

sub prompt_cont {
    my ($message, $default) = @_;
    local $_;

    chomp($message); # because prompt() adds "[y]\n"

    while (1) {
        $_ = prompt($message, $default);
        if(/^n/i) { print "Aborting\n"; exit; }
        if(/^y/i) { print "Continuing\n"; last; }
    }
}
