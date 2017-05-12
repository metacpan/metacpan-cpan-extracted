use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::TreeDumper::Renderer::GTK',
    'VERSION_FROM'	=> 'GTK.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	{
	Glib => 0,
	Gtk2 => 0,
	Cairo => 0,
	Data::TreeDumper => 0.33,
	}, 
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'GTK.pm', # retrieve abstract from module
       AUTHOR     => 'Nadim Khemir') : ()),
);
