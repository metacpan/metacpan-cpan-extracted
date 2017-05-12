use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::MVC',
    'VERSION_FROM'	=> 'MVC.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	{
		
		Class::Maker => 0,

		Class::Listener => 0,

		Class::Observable => 0,
		
	}, # e.g., Module::Name => 1.1
	
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'MVC.pm', # retrieve abstract from module
       AUTHOR     => 'M. Uenalan <muenalna@cpan.org>') : ()),
);
