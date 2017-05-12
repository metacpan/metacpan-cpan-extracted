use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::BeyondPerl::ToSQL',
    'VERSION_FROM'	=> 'lib/Acme/BeyondPerl/ToSQL.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	DBI         => 0,
    	Test::More  => 0,
    	DBD::SQLite => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Acme/BeyondPerl/ToSQL.pm', # retrieve abstract from module
       AUTHOR     => 'A. U. Thor <a.u.thor@a.galaxy.far.far.away>') : ()),
);
