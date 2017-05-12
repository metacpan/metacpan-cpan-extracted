use ExtUtils::MakeMaker;
    WriteMakefile(
        'NAME'              => 'CaCORE',
        'VERSION_FROM'      => 'lib/CaCORE/ApplicationService.pm', # finds $VERSION
        'PREREQ_PM' => {
	                XML::DOM => 1.25,
        }
    );