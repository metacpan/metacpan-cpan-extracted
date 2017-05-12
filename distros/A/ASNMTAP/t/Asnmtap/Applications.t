use Test::More tests => 15;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Applications' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:APPLICATIONS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:COMMANDS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:_HIDDEN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:ARCHIVE) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:DBARCHIVE) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:COLLECTOR) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:DBCOLLECTOR) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:DISPLAY) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:DBDISPLAY) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications', qw(:CGI) ) };

TODO: {
  my $objectApplications = ASNMTAP::Asnmtap::Applications->new (
    _programName        => 'Applications.t',
    _programDescription => 'Test ASNMTAP::Asnmtap::Applications',
    _programVersion     => '3.002.003',
    _debug              => 0);

  isa_ok( $objectApplications, 'ASNMTAP::Asnmtap::Applications' );
  can_ok( $objectApplications, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
}
