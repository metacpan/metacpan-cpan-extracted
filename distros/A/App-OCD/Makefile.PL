use 5.014;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'App::OCD',
    VERSION_FROM      => 'lib/App/OCD.pm', # finds $VERSION
    LICENSE           => 'GPL-2',
    PREREQ_PM         => { # module dependencies: Module::Name => version
			 },
    ABSTRACT          => "Top-level documentation for CPAN packages in the App::OCD name space",
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       AUTHOR         => 'Declan Malone <idablack@users.sorceforge.net>') : ()
    ),
    EXE_FILES          => [],
);
