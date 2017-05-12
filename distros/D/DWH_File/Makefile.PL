use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "DWH_File",
              DISTNAME => "DWH_File",
              VERSION_FROM => 'lib/DWH_File.pm',
	      PREREQ_PM => { URI => 0 },
             );
