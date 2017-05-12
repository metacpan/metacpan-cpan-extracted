use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'Data::Faker',
    VERSION_FROM        => 'lib/Data/Faker.pm',
    LICENSE             => 'perl',
    PREREQ_PM           => {
		'POSIX'         => 0,
	},
	EXE_FILES			=> [qw(datafaker)],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM    => 'lib/Data/Faker.pm', # retrieve abstract from module
       AUTHOR           => 'Jason Kohles <email@jasonkohles.com>') : ()),
);
