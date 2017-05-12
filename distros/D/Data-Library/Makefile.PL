use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::Library',
    'VERSION_FROM'	=> 'Library.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    "Class::Virtual" => 0.03,
			    "Log::Channel" => 0.6,
			   },
);
