use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::Factory',
    VERSION_FROM      => 'lib/Class/DBI/Plugin/Factory.pm', # finds $VERSION
    PREREQ_PM         => {
		Class::DBI			=> 0.96,
		UNIVERSAL::require	=> 0,
		Class::Inspector	=> 0,
	}, # e.g., Module::Name => 1.1
);
