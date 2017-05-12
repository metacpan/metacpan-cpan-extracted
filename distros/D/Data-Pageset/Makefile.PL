use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Data::Pageset',
    'VERSION_FROM'	=> 'lib/Data/Pageset.pm',
    'PREREQ_PM'		=> {
		'Data::Page'	=> 2.00,
		'Test::More' 	=> 0.1,
    }, 
);
