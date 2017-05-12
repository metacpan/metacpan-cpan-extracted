use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::Brev',
    VERSION_FROM      => 'lib/DBIx/Brev.pm', # finds $VERSION
    PREREQ_PM         => {
        "Config::General" => 2.51,
        "DBIx::Connector" => 0.53,
        "DBI"   => 1.625,
        'SQL::SplitStatement' => 1.00020, 
    }, # e.g., Module::Name => 1.1
    BUILD_REQUIRES    => { 'Parse::CPAN::Meta' => 1.4404, 'ExtUtils::MakeMaker' => 6.66, },
    TEST_REQUIRES     => { 'DBD::SQLite' => 1.27, }, # ExtUtils::MakeMaker => 6.66
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'framework for laconic DBI', # retrieve abstract from module
       AUTHOR         => 'Oleksandr Kharchenko <okharch@okharch.com>') : ()),
);
