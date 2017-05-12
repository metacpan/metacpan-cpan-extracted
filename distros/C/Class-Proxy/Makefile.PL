use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Proxy',
    'VERSION_FROM'	=> 'Proxy.pm', # finds $VERSION
    'PREREQ_PM'		=>
	{
		Class::Maker => 0,
		IO::Extended => 0,

	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Proxy.pm', # retrieve abstract from module
       AUTHOR     => 'Murat Uenalan  <muenalan@cpan.org>') : ()),
);
