use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Audio::CD',
    'VERSION_FROM' => 'CD.pm',
    'macro' => {
	  CVSROOT => 'modperl.com:/local/cvs_repository',
    },
    'LIBS'	=> ["-lcdaudio"],
    DEFINE => '-g',
    OBJECT => 'cddb_lookup.o CD.o',
);

sub MY::postamble { 
    return <<'EOF'; 

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) . 
	@echo update CD.pm VERSION now 
EOF
} 
