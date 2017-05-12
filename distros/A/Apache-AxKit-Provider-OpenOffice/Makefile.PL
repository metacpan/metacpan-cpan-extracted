use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::AxKit::Provider::OpenOffice',
    'VERSION_FROM' => 'OpenOffice.pm', # finds $VERSION
    'PREREQ_PM' => { 
        AxKit => 1.6,
	Archive::Zip => 1.01,
	Apache::Request => 1.0,
                },
);
