use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME => 'Archive::SelfExtract',
	      VERSION_FROM => 'lib/Archive/SelfExtract.pm',
	      AUTHOR => 'Greg Fast <gdf@speakeasy.net>',
	      PREREQ_PM =>
	      { Compress::Zlib => 0,
		File::Spec => 0,
		Archive::Zip => 0,
		File::Temp => 0,
		File::Path => 0,
		IO::Scalar => 0,
	      },
	      EXE_FILES => [ "bin/mkselfextract" ],
	     );
