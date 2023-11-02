use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
$prerequisits = 
	{
	Text::Wrap  => 2001.0929,
	#Devel::Size => 0.58, 
	Class::ISA  => 0,
	Sort::Naturally => 0,
	Check::ISA => 0,
	} ;

if($^O ne 'MSWin32')
	{
	$prerequisits->{'Term::Size'} = 0.2 ;
	}
else
	{
	$prerequisits->{'Win32::Console'} = 0
	}

WriteMakefile(
    'NAME'		=> 'Data::TreeDumper',
    'VERSION_FROM'	=> 'TreeDumper.pm', # finds $VERSION
    'PREREQ_PM'		=> $prerequisits,
    
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'TreeDumper.pm', # retrieve abstract from module
       AUTHOR     => 'Khemir Nadim ibn Hamouda. <nadim@khemir.net>') : ()),
);
