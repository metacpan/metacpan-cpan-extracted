use 5.6.1;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::RDF',
    VERSION_FROM      => 'RDF.pm', # finds $VERSION
    PREREQ_PM         => {
	"Class::DBI"  => 0.95,
	"DBD::SQLite" => 0.29,
        "RDF::Simple" => 0.13,
        "File::Temp"  => 0.14,
    }, # e.g., Module::Name => 1.1
);
