use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %reqmodules = ('Test::More' => 0,
                  'DBD::SQLite' => 0,
		  'DBIx::Simple' => 0,
		  'Biblio::Thesaurus' => 0
		 );
		  

WriteMakefile(
    NAME              => 'Biblio::Thesaurus::SQLite',
    VERSION_FROM      => 'lib/Biblio/Thesaurus/SQLite.pm', # finds $VERSION
    PREREQ_PM         => {%reqmodules},
);
