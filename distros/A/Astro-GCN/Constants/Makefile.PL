use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::GCN::Constants',
	       'VERSION_FROM'   => 'Constants.pm',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'Class for constants relating to the GCN',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

