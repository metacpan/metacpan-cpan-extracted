use 5.012004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'BGPmon::Analytics::db',
    VERSION_FROM      => 'lib/BGPmon/Analytics-db.pm', # finds $VERSION
    EXE_FILES         => ['bin/bgpmon_analytics_db_import',
                          'bin/bgpmon_analytics_db_report',
                          'bin/bgpmon_analytics_db_reset',
                          'bin/bgpmon_analytics_db_0_pphTables.psql',
                          'bin/bgpmon_analytics_db_1_pphFunctions.psql',
                          'bin/bgpmon_analytics_db_2_pphQueryFuncs.psql'],
    PREREQ_PM         => { 	'BGPmon::Log' => 0,
				'BGPmon::Translator::XFB2PerlHash::Simple' => 0,
				'BGPmon::Configure'	=> 0,

}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (
       AUTHOR         => 'Jason <jason@>') : ()),
);
