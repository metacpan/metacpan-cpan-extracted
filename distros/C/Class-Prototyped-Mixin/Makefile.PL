

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Class::Prototyped::Mixin',
    VERSION_FROM => 'lib/Class/Prototyped/Mixin.pm', # finds \$VERSION
    AUTHOR       => 'Terrence Brannon (metaperl@gmail.com)',
    ABSTRACT     => 'Mixin Support for Class::Prototyped',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'Class::Prototyped' => 1.11
                    },
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

README: lib/Class/Prototyped/Mixin.pm
	pod2text lib/Class/Prototyped/Mixin.pm > README

CHANGES: lib/Class/Prototyped/Mixin/Changes.pod
	pod2text lib/Class/Prototyped/Mixin/Changes.pod > CHANGES

}; }
