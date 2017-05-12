use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::Plugin::Calendar',
    VERSION_FROM      => 'lib/Class/DBI/Plugin/Calendar.pm', # finds $VERSION
    PREREQ_PM         => {
    	Calendar::Simple	=>	1.13,
    	Time::Piece			  =>	1.08,
			DBI								=>	1,
			DBD::mysql				=>	1,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/DBI/Plugin/Calendar.pm', # retrieve abstract from module
       AUTHOR         => 'James Tolley <james@bitperfect.com>') : ()),
);
