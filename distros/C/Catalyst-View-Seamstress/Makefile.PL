use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'Catalyst::View::Seamstress',
    AUTHOR    => 'Terrence Brannon (metaperl@gmail.com)',
    PREREQ_PM => {
        Catalyst          => '5.5',
        Template          => 0,
        HTML::Seamstress  => 0,
    },
    VERSION_FROM => 'lib/Catalyst/View/Seamstress.pm'
);

sub MY::postamble { q{

cleandist: FORCE
	make again; make cleanmanifest; make docs; make dist

again: FORCE
	make clean; perl Makefile.PL; make pm_to_blib

cleanmanifest: realclean FORCE
	rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

%.t: pm_to_blib FORCE
	make; perl -Iblib/lib $@

docs : README CHANGES

README: lib/Catalyst/View/Seamstress.pm
	pod2text lib/Catalyst/View/Seamstress.pm > README

CHANGES: lib/Catalyst/View/Seamstress/Changes.pod
	pod2text lib/Catalyst/View/Seamstress/Changes.pod > CHANGES

}; }
