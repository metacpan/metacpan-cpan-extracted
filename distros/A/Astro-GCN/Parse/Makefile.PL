use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::GCN::Parse',
	       'VERSION_FROM'   => 'Parse.pm',
               'PREREQ_PM'      => {  },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT       => 'A class to parse GCN binary packets',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

