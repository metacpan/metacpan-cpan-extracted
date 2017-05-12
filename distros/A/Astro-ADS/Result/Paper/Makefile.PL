use ExtUtils::MakeMaker;

WriteMakefile( 
               'NAME'           => 'Astro::ADS::Result::Paper',
	       'VERSION_FROM'   => 'Paper.pm',
               'PREREQ_PM'      => { },
	       'dist'           => { COMPRESS => "gzip -9f"},
	       ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       ( ABSTRACT_FROM  => 'Paper.pm',
		 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),
             );

