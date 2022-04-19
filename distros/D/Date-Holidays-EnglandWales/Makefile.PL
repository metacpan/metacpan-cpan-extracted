use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Date::Holidays::EnglandWales',
    VERSION_FROM      => 'lib/Date/Holidays/EnglandWales.pm', # finds $VERSION
    PREREQ_PM         => {
        Time::Piece => undef,
        Time::Seconds => undef,
        DateTime::Event::Easter => undef
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Date/Holidays/EnglandWales.pm', # retrieve abstract from module
       AUTHOR         => 'Jason Clifford <jason@ukfsn.org>') : ()),
);
