use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Maker',
    'VERSION_FROM'	=> 'lib/Class/Maker.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	{
	  
# the static prerequisites

'XML::LibXSLT' => '0',
'Data::Dumper' => '0',
'IO::Extended' => '0',
'Error' => '0.15',
'Algorithm::FastPermute' => '0.05',
'Array::Compare' => '1.03',

	},

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Class/Maker.pm', # retrieve abstract from module
       AUTHOR     => 'muenalan@cpan.org') : ()),
);
