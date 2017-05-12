use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'AxKit::XSP::Swish',
    'VERSION_FROM'	=> 'Swish.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			'SWISHE' =>'0.02',
			   } 
);
