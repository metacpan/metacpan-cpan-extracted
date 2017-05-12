use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Config::Tiny::Singleton',
    VERSION_FROM      => 'lib/Config/Tiny/Singleton.pm', # finds $VERSION
    PREREQ_PM         => {
		Config::Tiny				=> 0,
		Class::Singleton			=> 0,
		Class::Data::Inheritable	=> 0,
	},
);
