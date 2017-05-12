use ExtUtils::MakeMaker;

########################################################################

BEGIN {
	if ( $^O =~ m/Win32/ or $ENV{THIS_IS_WIN32} ) {
	    die "Benchmark::Forking requires fork(), which is not supported on Windows.\n"
	}
}

########################################################################

WriteMakefile(
    'NAME'		=> 'Benchmark::Forking',
	AUTHOR            => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
	ABSTRACT_FROM     => 'Forking.pm', 
    'VERSION_FROM'	=> 'Forking.pm', 
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
    	? ('LICENSE'=> 'perl')
    	: ()
	),
    'PREREQ_PM'		=> {}, 
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Escape-*' },
);

########################################################################

sub MY::postamble { <<'<<' }

again: realclean FORCE
	perl Makefile.PL; make pm_to_blib

cleanmanifest: realclean FORCE
	rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

%.t: pm_to_blib FORCE
	make; perl -Iblib/lib $@

cover: FORCE
	cover -delete; HARNESS_PERL_SWITCHES=-MDevel::Cover make test; cover

<<

1;