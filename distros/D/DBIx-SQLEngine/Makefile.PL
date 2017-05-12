use ExtUtils::MakeMaker;

########################################################################

WriteMakefile(
    'NAME'		=> 'DBIx::SQLEngine',
    'VERSION_FROM'	=> 'SQLEngine.pm', 
    'PREREQ_PM'		=> {
	DBI				=> 1.0,
	DBIx::AnyDBD			=> 2.0,
	Class::MakeMethods		=> 1.006,
	Class::MixinFactory		=> 0.9,
    }, 
    ($] >= 5.005 ? (
      ABSTRACT_FROM => 'SQLEngine.pm', 
      AUTHOR     => 'Matthew Simon Cavalletto <simonm@cavalletto.org>',
    ) : ()),
);
  
########################################################################

sub MY::postamble { q{

everything: FORCE
	make again; make cleanmanifest; make docs; make compile; make test

cleandist: FORCE
	make again; make cleanmanifest; make docs; make dist

again: FORCE
	make clean; perl Makefile.PL; make pm_to_blib

cleanmanifest: FORCE
	rm MANIFEST ; touch MANIFEST; make manifest

test.cfg: FORCE
	perl test_cfg.pl

%.t: pm_to_blib FORCE
	perl -Iblib/lib -w $@

compile: pm_to_blib FORCE
	perl make_extras/compile.pl $(MAN3PODS)

htmldoc: pm_to_blib FORCE
	perl make_extras/htmldoc.pl $(MAN3PODS)

cover: FORCE
	cover -delete; HARNESS_PERL_SWITCHES="-MDevel::Cover=+inc,test_core,test_drivers" make test; cover

docs : README CHANGES TODO

README: SQLEngine/Docs/ReadMe.pod
	pod2text SQLEngine/Docs/ReadMe.pod > README

CHANGES: SQLEngine/Docs/Changes.pod
	pod2text SQLEngine/Docs/Changes.pod > CHANGES

TODO: SQLEngine/Docs/ToDo.pod
	pod2text SQLEngine/Docs/ToDo.pod > TODO

} }

########################################################################
1;
