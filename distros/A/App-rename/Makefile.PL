use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'App::rename',
	      LICENSE => 'Perl_5',
	      ABSTRACT => 'rename multiple files using perl expressions',
	      AUTHOR => 'Peder Stray <peder.stray@gmail.com>',
	      VERSION_FROM => 'lib/App/rename.pm',
	      PL_FILES => { 'bin/rename.PL' => 'bin/rename' },
	      EXE_FILES => [ 'bin/rename' ],
	      dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
