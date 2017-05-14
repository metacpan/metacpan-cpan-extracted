use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Class::MakeMethods',
    'VERSION_FROM'	=> 'MakeMethods.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ? (
      ABSTRACT_FROM     => 'MakeMethods.pm', 
      AUTHOR            => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);
sub MY::postamble { q{

cleanmanifest:
	make realclean; rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

docs : README CHANGES

CHANGES: MakeMethods/Docs/Changes.pod
	pod2text MakeMethods/Docs/Changes.pod > CHANGES

README: MakeMethods/Docs/ReadMe.pod
	pod2text MakeMethods/Docs/ReadMe.pod > README

}; }
