use ExtUtils::MakeMaker;

########################################################################

WriteMakefile(
    'NAME'		=> 'Class::MakeMethods',
    'VERSION_FROM'	=> 'MakeMethods.pm', 
    'PREREQ_PM'		=> {}, 

    ($] >= 5.005 ? (
      ABSTRACT_FROM     => 'MakeMethods.pm', 
      AUTHOR            => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);

########################################################################

sub MY::postamble { q{

again: realclean FORCE
	perl Makefile.PL; make pm_to_blib

cleanmanifest: realclean FORCE
	rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

%.t: pm_to_blib FORCE
	make; perl -Iblib/lib $@

cover: FORCE
	cover -delete; HARNESS_PERL_SWITCHES=-MDevel::Cover make test; cover

docs : README CHANGES

README: MakeMethods/Docs/ReadMe.pod
	pod2text MakeMethods/Docs/ReadMe.pod > README

CHANGES: MakeMethods/Docs/Changes.pod
	pod2text MakeMethods/Docs/Changes.pod > CHANGES

}; }
