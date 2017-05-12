use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::GCN::Util::SWIFT',
	       'VERSION_FROM'   => 'SWIFT.pm',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'A class for SWIFT specific utilities',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

