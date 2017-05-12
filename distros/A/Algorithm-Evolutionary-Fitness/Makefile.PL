use ExtUtils::MakeMaker; #-*-cperl-*-

my @scripts = grep {-f } glob("scripts/*.pl "); # Ripped from Text::PDF

my %make;
if ($ExtUtils::MakeMaker::VERSION > 6.64) {
   $make{META_MERGE} = {
    'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/JJ/algorithm-evolutionary-fitness.git',
                web  => 'https://github.com/JJ/algorithm-evolutionary-fitness',
            },
        },
    };
}

WriteMakefile(
	      NAME                => 'Algorithm::Evolutionary::Fitness',
	      AUTHOR              => 'JJ Merelo <jj /at/ merelo.net>',
	      VERSION_FROM        => 'lib/Algorithm/Evolutionary/Fitness.pm',
	      ABSTRACT_FROM       => 'lib/Algorithm/Evolutionary/Fitness.pm',
	      EXE_FILES => \@scripts,
	      LICENSE => 'gpl',
	      PL_FILES            => {},
	      PREREQ_PM => {'Algorithm::Evolutionary::Utils' => 3.403,
			    constant => 0,
			    'Math::Random' => 0.63,
			    'String::Random' => 0,
			    'Test::More' => 0,
			    'Test::Pod' => 0,
			    'Test::Exception' => 0,
			    'version'    => 0,
			    YAML => 0
			   },
	      dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	      clean               => { FILES => 'Algorithm-Evolutionary-*' }
	     );

#Add new targets
sub MY::postamble {
    return <<'MAKE_FRAG';
docs:
	pod2html --verbose --htmlroot .. --podpath=Evolutionary/Individual:Evolutionary/Op:Evolutionary --outfile index.html Evolutionary.pm; \
	cd examples; for i in *.pl; do pod2html --verbose --htmlroot ../..  --podpath=../Evolutionary/Individual:../Evolutionary/Op:../Evolutionary --outfile $$i.html $$i; done ; \
	cd ../Evolutionary; for i in *.pm; do base=`basename $$i .pm`; echo $$base; pod2html --verbose --htmlroot ../.. --podpath=Individual:Op --outfile $$base.html $$i; done ; \
	for i in *.pod; do base=`basename $$i .pod`; echo $$base; pod2html --verbose --htmlroot ../..   --podpath=Individual:Op --outfile $$base.html $$i; done; \
	cd Op; for i in *.pm; do base=`basename $$i .pm`; echo $$base; pod2html --verbose --htmlroot ../../.. --podroot ..  --outfile $$base.html $$i; done ; \
	cd ../Individual; for i in *.pm; do base=`basename $$i .pm`; echo $$base; pod2html --verbose --htmlroot ../../.. --podroot .. --outfile $$base.html $$i; done
	
$(DISTVNAME)-examples.tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME)-examples.tar $(DISTVNAME)/examples
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME)-examples.tar
	$(POSTOP)

examplesdist : $(DISTVNAME)-examples.tar$(SUFFIX)
	$(NOECHO) $(NOOP)

MAKE_FRAG
}

#Version 3.8
