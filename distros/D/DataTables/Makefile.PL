use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DataTables',
    VERSION_FROM      => 'lib/DataTables.pm', # finds $VERSION
    PREREQ_PM         => {
							'CGI::Simple' => '1.113',
							DBI=>1.611,
							JSON::XS=>2.32,
							Carp=>0.00,
							'SQL::Abstract::Limit' => 0,
							'ExtUtils::MakeMaker' => '6.64',
						 }, # e.g., Module::Name => 1.1
    TEST_REQUIRES => {
        'Data::Compare' => 1.23,
    },
    AUTHOR         => 'Adam Hopkins <srchulo@cpan.org>',
    LICENSE        => 'perl_5',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/srchulo/DataTables',
        },
    },
    MIN_PERL_VERSION => 5.008008,
);
