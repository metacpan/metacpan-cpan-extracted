use ExtUtils::MakeMaker;
WriteMakefile( NAME => "CDB_File-BiIndex",
	       VERSION_FROM => "lib/CDB_File/BiIndex.pm",
	       dist => {COMPRESS => "gzip",
			SUFFIX => "gz" },
	       PREREQ_PM => { CDB_File=>0.86,
			      CDB_File::Generator=>0.018,
			    },
	     );
