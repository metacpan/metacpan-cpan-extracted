use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Apache::Access::Headers',
    'VERSION_FROM'	=> 'Headers.pm',
    'PREREQ_PM'		=> {
    	Apache			=> 0.1,
		XML::Simple		=> 0.1,
    	Data::Dumper	=> 0.1,
    },
);
