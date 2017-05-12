use ExtUtils::MakeMaker;
if (! -e 'README.html' && open(RM, '>README.html')) {
    print RM "TBD ...\n";
    close(RM);
}
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ClearCase::Argv',
    'VERSION_FROM'	=> 'Argv.pm', # finds $VERSION
    'PREREQ_PM'		=> { Argv => 1.28 },
    'dist'		=> {
	COMPRESS => 'gzip --force --best',
	PREOP	 => 'pod2html README --title="ClearCase::Argv README" > $(DISTNAME)-$(VERSION)/README.html',
	POSTOP	 => 'rm -f pod2html-*cache',
	TAR	 => 'gtar',
	TARFLAGS => '--mode=u+w -cvf',
    },
    clean		=> {
	FILES	=> 'README.html',
    },
);
