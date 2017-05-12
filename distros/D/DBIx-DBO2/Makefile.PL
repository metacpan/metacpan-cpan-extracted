use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'DBIx::DBO2',
    'VERSION_FROM'	=> 'DBO2.pm', 
    'PREREQ_PM'		=> {
	DBIx::SQLEngine	   => 0.018, # for new Table interface
	Class::MakeMethods => 1.001, # for Composite::Inheritable:hook
    }, 
    ($] >= 5.005 ? (
      ABSTRACT_FROM => 'DBO2.pm', 
      AUTHOR     => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);
sub MY::postamble { q{

again:
	make clean; perl Makefile.PL; make

cleanmanifest:
	rm MANIFEST ; touch MANIFEST; make manifest

docs : README CHANGES TODO

README: DBO2/Docs/ReadMe.pod
	pod2text DBO2/Docs/ReadMe.pod > README

CHANGES: DBO2/Docs/Changes.pod
	pod2text DBO2/Docs/Changes.pod > CHANGES

TODO: DBO2/Docs/ToDo.pod
	pod2text DBO2/Docs/ToDo.pod > TODO

}; }
