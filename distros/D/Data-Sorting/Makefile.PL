use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'Data::Sorting',
    VERSION_FROM	=> 'Sorting.pm', 
    PREREQ_PM		=> { Test::More => 0, },
    ($] >= 5.005 ? (
      ABSTRACT_FROM     => 'Sorting.pm', 
      AUTHOR            => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);
sub MY::postamble { q{

cleanmanifest:
	make realclean; rm MANIFEST ; perl Makefile.PL; touch MANIFEST; make manifest

docs : README

README: MakeMethods/Docs/ReadMe.pod
	pod2text MakeMethods/Docs/ReadMe.pod > README

}; }
