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

ModPerl::MM::WriteMakefile(
    NAME              => 'Apache2::ClickPath',
    VERSION_FROM      => 'lib/Apache2/ClickPath.pm', # finds $VERSION
    PREREQ_PM         => {
			  "Apache::Test" => "",
			  mod_perl2=>0,
			  "LWP::UserAgent" => '',
			  "Crypt::CBC" => '2.14',
			  "Crypt::Blowfish" => '',
			  "Digest::CRC" => '',
			 },
    clean             => {
			  FILES => "t/TEST",
			 },
    depend            => {
			 },
    dist              => {
			  PREOP => './mk_README.sh',
			 },
    ABSTRACT_FROM     => 'lib/Apache2/ClickPath.pm',
    AUTHOR            => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
);

sub MY::postamble {
  return <<'EOF';
COMPRESS = gzip -9f

README: lib/Apache2/ClickPath.pm mk_README.sh
	./mk_README.sh

rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Apache2-ClickPath.spec
	rpmbuild -ba perl-Apache2-ClickPath.spec
EOF
}
