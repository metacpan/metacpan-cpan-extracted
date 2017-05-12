use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib qw(../blib/lib lib );

use Apache::TestMM qw(test clean); #enable 'make test'
  
# prerequisites
my @scripts = qw(t/TEST);
  
# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

WriteMakefile(
    NAME                => 'Acme::PETEK::Testkit',
    AUTHOR              => 'Pete Krawczyk <petek@cpan.org>',
    VERSION_FROM        => 'lib/Acme/PETEK/Testkit.pm',
    ABSTRACT_FROM       => 'lib/Acme/PETEK/Testkit.pm',
    PL_FILES            => {},
    PREREQ_PM => {
	'Apache::Test' => 0,
	'DBD::SQLite' => 0,
	'Test::DatabaseRow' => 0,
	'Test::Expect' => 0,
	'Test::Inline' => 0,
	'Test::Legacy' => 0,
	'Test::Pod' => 1.14,
	'Test::Pod::Coverage' => 1.04,
	'Test::WWW::Mechanize' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => [ 'Acme-PETEK-Testkit-*', 't/TEST' ] },
);
