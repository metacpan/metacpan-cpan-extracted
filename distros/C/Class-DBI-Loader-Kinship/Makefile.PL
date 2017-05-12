use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    LICENSE           => 'perl',
    NAME              => 'Class::DBI::Loader::Kinship',
    VERSION_FROM      => 'lib/Class/DBI/Loader/Kinship.pm',
    PREREQ_PM         => { Class::DBI::Loader => 0,
                           Class::DBI::Pg     => 0
			 }, 
    ABSTRACT_FROM     => 'lib/Class/DBI/Loader/Kinship.pm',
    AUTHOR            => 'Ioannis Tambouras <ioannis@cpan.org>',
    PL_FILES          => {},
    dist             => { PREOP => 'pod2text lib/Class/DBI/Loader/Kinship.pm > $(DISTVNAME)/README',},
);
