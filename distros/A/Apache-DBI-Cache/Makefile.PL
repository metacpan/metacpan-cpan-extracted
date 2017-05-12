use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::DBI::Cache',
    VERSION_FROM      => 'lib/Apache/DBI/Cache.pm', # finds $VERSION
    PREREQ_PM         => {
			  DBI=>'1.37',
			  'DBD::SQLite'=>0,
			 }, # e.g., Module::Name => 1.1
    dist              => {
                          PREOP => './mk_README.sh',
                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache/DBI/Cache.pod', # retrieve abstract from module
       AUTHOR         => 'Torsten Foertsch <torsten.foertsch@gmx.net>') : ()),
);

sub MY::postamble {
  return <<'EOF';
README: lib/Apache/DBI/Cache.pm mk_README.sh
	./mk_README.sh

rpm: dist
	rpmbuild -ba perl-Apache-DBI-Cache.spec
EOF
}
