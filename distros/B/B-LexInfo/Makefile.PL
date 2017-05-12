use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'B::LexInfo',
    'VERSION_FROM' => 'LexInfo.pm',
    'macro' => {
	  CVSROOT => 'modperl.com:/local/cvs_repository',
    },
);

sub MY::postamble { 
    return <<'EOF'; 

cvs_tag :
	cvs -d $(CVSROOT) tag v$(VERSION_SYM) . 
	@echo update LexInfo.pm VERSION now 
EOF
} 
