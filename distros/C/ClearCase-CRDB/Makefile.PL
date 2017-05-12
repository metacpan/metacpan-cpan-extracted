use ExtUtils::MakeMaker;
if (! -e 'README' && open(RM, '>README')) {
    print RM "TBD ...\n";
    close(RM);
}
if (! -e 'WHOUSES.html' && open(RM, '>WHOUSES.html')) {
    print RM "TBD ...\n";
    close(RM);
}

WriteMakefile(
    'NAME'		=> 'ClearCase::CRDB',
    'VERSION_FROM'	=> 'lib/ClearCase/CRDB.pm',
    'EXE_FILES'		=> [ 'whouses' ],
    'PREREQ_PM'		=> {
	Data::Dumper	=> 2.101,
	File::Spec	=> 0.82,
    },
    'dist'		=> {
	COMPRESS	=>   'gzip --force --best',
	TAR		=>   'gtar',
	TARFLAGS	=>   '--mode=u+w -cvf',
	PREOP		=>   'pod2text whouses > README; ' .
				 'pod2html whouses > WHOUSES.html',
	POSTOP	 	=>   'rm -f pod2html-*cache',
    },
    clean		=> {
	FILES		=> 'README WHOUSES.html t/*.o t/*.a t/*.so t/.cmake.state t/prog1* t/recu/rx* t/recu/r?/.cmake.state t/recu/r?/*.so t/recu/r?/*.o',
    },
);
