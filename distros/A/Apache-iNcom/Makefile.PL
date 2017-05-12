use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME	    => 'Apache::iNcom',
	      VERSION_FROM  => 'lib/Apache/iNcom.pm',
	      AUTHOR	    => 'Francis J. Lacoste <francis.lacoste\@iNsu.Com>',
	      PREREQ_PM	    => { HTML::Embperl   => 1.2,
				 Apache::Session => 1.03,
				 Storable	 => 0,
				 Apache::Request => 0,
				 Digest::MD5	 => 0,
				 DBI		 => 1.13,
			       },
);
