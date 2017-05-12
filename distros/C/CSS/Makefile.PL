use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'CSS',
    'VERSION_FROM'	=> 'CSS.pm',
    'PREREQ_PM'		=> {
					Parse::RecDescent	=> 1.0,
					Test::Simple		=> 0,
				},
);
