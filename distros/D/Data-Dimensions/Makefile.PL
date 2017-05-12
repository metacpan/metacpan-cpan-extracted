use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Data::Dimensions',
    'VERSION_FROM' => 'lib/Data/Dimensions.pm', # finds $VERSION
    'PM'=> {
	'lib/Data/Dimensions.pm' => '$(INST_LIBDIR)/Dimensions.pm',
	'lib/Data/Dimensions/Map.pm' => '$(INST_LIBDIR)/Dimensions/Map.pm',
	'lib/Data/Dimensions/SickTie.pm' => '$(INST_LIBDIR)/Dimensions/SickTie.pm',
    },
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
