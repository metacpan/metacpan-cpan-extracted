use ExtUtils::MakeMaker;

# Hack: works around a catch-22 problem for the maintainer.
# This should be a no-op for anyone else ...
if (! -e 'SYNCTREE.html' && open(HTML, '>SYNCTREE.html')) {
    print HTML "TBD ...\n";
    close(HTML);
}

WriteMakefile(
    'NAME'		=> 'ClearCase::SyncTree',
    'VERSION_FROM'	=> 'SyncTree.pm',
    'EXE_FILES'		=> [ 'synctree' ],
    'PREREQ_PM'		=> {
	Argv		=> 1.00,
	ClearCase::Argv	=> 1.00,
	File::Spec	=> 0.82,
    },
    'dist'		=> {
	COMPRESS	=>   'gzip --force --best',
	PREOP		=>   'pod2html synctree > SYNCTREE.html',
	TAR		=>   'gtar',
	TARFLAGS	=>   '--mode=u+w -cvf',
    },
    clean		=> {
	FILES		=> 'SYNCTREE.html',
    },
);
