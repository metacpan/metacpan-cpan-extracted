use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::GCN::Util',
	       'VERSION_FROM'   => 'Util.pm',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'A general utility class',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

