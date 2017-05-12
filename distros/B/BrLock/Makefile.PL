use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'BrLock',
    VERSION_FROM      => 'lib/BrLock.pm', # finds $VERSION
    PREREQ_PM         => {IO::Socket => 1.23, 
                          Switch => 2.10_01,
                          threads => 1.07,
			  threads::shared => 0.94,
			  } # e.g., Module::Name => 1.1
);
