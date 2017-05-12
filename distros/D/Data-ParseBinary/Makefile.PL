use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Data::ParseBinary',
    VERSION_FROM  => 'lib/Data/ParseBinary.pm',
    ABSTRACT_FROM => 'lib/Data/ParseBinary.pm',
    AUTHOR        => 'Shmuel Fomberg <owner@semuel.co.il>',
    PREREQ_PM     => {	
        'Math::BigInt' => 1.993,
		'Test::More' => 0.96,
    },
);


