use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::GCN',
	       'VERSION'        => '0.1',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'Module designed to parse GCN packets',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

