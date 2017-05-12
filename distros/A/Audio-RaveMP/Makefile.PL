use 5.005;
use ExtUtils::MakeMaker;

unless ($^O eq 'linux') {
    print "sorry, Audio::RaveMP is linux specific\n";
    exit 1;
}

my @insure = ();
if ($ENV{USER} eq 'dougm') {
    push @insure, DEFINE => '-g';
}

if (0) {
    @insure = (
       CC => 'insure gcc',
       LD => 'insure gcc',
    );
}

WriteMakefile(
    @insure,
    'NAME'	=> 'Audio::RaveMP',
    'VERSION_FROM' => 'RaveMP.pm',
    'macro' => {
	  CVSROOT => 'modperl.com:/local/cvs_repository',
    },
    OBJECT => 'ravemp.o RaveMP.o',
);

sub MY::postamble { 
    return <<'EOF'; 

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) . 
	@echo update RaveMP.pm VERSION now 
EOF
} 
