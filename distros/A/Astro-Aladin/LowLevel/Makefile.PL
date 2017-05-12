use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::Aladin::LowLevel',
	       'VERSION_FROM'   => 'LowLevel.pm',
               'PREREQ_PM'      => { },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT => 'Low level odule designed to drive CDS Aladin',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

