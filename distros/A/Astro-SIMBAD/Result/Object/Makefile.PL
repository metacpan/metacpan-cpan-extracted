use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::SIMBAD::Result::Object',
	       'VERSION_FROM'   => 'Object.pm',
               'PREREQ_PM'      => { },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT_FROM  => 'Object.pm',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

