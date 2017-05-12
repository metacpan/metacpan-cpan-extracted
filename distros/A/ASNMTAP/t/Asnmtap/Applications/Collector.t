use Test::More tests => 10;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Applications::Collector' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Collector' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Collector', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Collector', qw(:APPLICATIONS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Collector', qw(:COMMANDS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Collector', qw(:_HIDDEN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Collector', qw(:COLLECTOR) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Collector', qw(:DBCOLLECTOR) ) };

TODO: {
  my $objectCollector = ASNMTAP::Asnmtap::Applications::Collector->new (
    _programName        => 'Collector.t',
    _programDescription => 'Test ASNMTAP::Asnmtap::Applications::Collector',
    _programVersion     => '3.002.003',
    _debug             => 0);

  isa_ok( $objectCollector, 'ASNMTAP::Asnmtap::Applications::Collector' );
  can_ok( $objectCollector, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
}
