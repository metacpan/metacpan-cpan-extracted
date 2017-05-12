use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    LICENSE           => 'perl',
    PL_FILES          => {},
    NAME              => 'Config::Format::Ini',
    VERSION_FROM      => 'lib/Config/Format/Ini.pm',
    PREREQ_PM         => { 'Attribute::Handlers' => 0,
	                   'Parse::RecDescent'   => 0,
	                   'File::Slurp'         => 0,
                         },
    ABSTRACT_FROM     => 'lib/Config/Format/Ini.pm',
    AUTHOR            => 'Ioannis Tambouras <ioannis@cpan.org>',
);

