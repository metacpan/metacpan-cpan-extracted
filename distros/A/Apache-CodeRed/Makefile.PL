use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      'NAME'		=> 'Apache::CodeRed',
	      'VERSION_FROM'	=> 'CodeRed.pm', # finds $VERSION

	      'PREREQ_PM' => { 'Apache::Constants' => 1.09,
			       'Mail::Sendmail' => 0.78,
			       'Net::DNS' => 0.12,
			       'Cache::Cache' => 0.08,
			       'Time::Zone' => 2.20}, 

	      ($] >= 5.005 ? ## Add these new keywords supported since 5.005

	       (ABSTRACT => 'Responds to CodeRed worm attacks with e-mail warnings', 
		AUTHOR     => 'Reuven M. Lerner <reuven@lerner.co.il>') : ()),

	     );
