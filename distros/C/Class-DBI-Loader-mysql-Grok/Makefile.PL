use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::DBI::Loader::mysql::Grok',
    VERSION_FROM      => 'lib/Class/DBI/Loader/mysql/Grok.pm', # finds $VERSION
    PREREQ_PM         => {
    	Time::Piece::MySQL			=>	0.05,
    	Class::DBI::Loader::mysql	=>	0.22,
    	Lingua::EN::Inflect			=>	1.88,
    	Class::DBI::mysql			=>	0.22,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Class/DBI/Loader/mysql/Grok.pm', # retrieve abstract from module
       AUTHOR         => 'James Tolley <james@bitperfect.com>') : ()),
);


