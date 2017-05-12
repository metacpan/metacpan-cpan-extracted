#!perl

use 5.8.8;
BEGIN {
  eval {
    require ModPerl::MM;
    require Apache::TestMM;
  };
  if( $@ ) {
    exit 0;
  }
  Apache::TestMM->import( qw(test clean) );
}

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

my %prereq=(
            mod_perl2=>0,
            'DBI'=>0,
            'DBD::SQLite'=>0,
            'BerkeleyDB'=>0.31,
            'Class::Member'=>1.3,
            'Tie::Cache::LRU'=>0.21,
            'Test::Deep'=>0,
            'Template'=>2.15,
            'Apache2::ModSSL'=>0,
            'Apache2::Request'=>0,
            'YAML'=>0,
            'MMapDB'=>0,
           );

ModPerl::MM::WriteMakefile(
  NAME              => 'Apache2::Translation',
  VERSION_FROM      => 'lib/Apache2/Translation.pm',
  PREREQ_PM         => \%prereq,
  EXE_FILES         => [qw!script/cpprov script/diffprov!],
  ABSTRACT_FROM     => 'lib/Apache2/Translation.pod',
  AUTHOR            => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
  dist              => {
			PREOP => './mk_README.sh',
		       },
  clean             => {
			FILES=>"t/TEST",
		       },
);

sub MY::postamble {
  return <<'EOF';
COMPRESS = gzip -9f

README: lib/Apache2/Translation.pod mk_README.sh
	./mk_README.sh

rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Apache2-Translation.spec
	rpmbuild -ba perl-Apache2-Translation.spec
EOF
}
