use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Date::HolidayParser',
    VERSION_FROM      => 'lib/Date/HolidayParser.pm', # finds $VERSION
    PREREQ_PM         => {
		'Any::Moose' => 0,
	},
	BUILD_REQUIRES	=> {
		'Test::More' => 0,
	},
	LICENSE => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Date/HolidayParser.pm', # retrieve abstract from module
       AUTHOR         => 'Eskild Hustvedt <zerodogg@cpan.org>') : ()),
);
