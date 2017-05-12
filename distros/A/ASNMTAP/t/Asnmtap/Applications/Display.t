use Test::More tests => 10;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Applications::Display' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Display' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Display', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Display', qw(:APPLICATIONS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Display', qw(:COMMANDS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Display', qw(:_HIDDEN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Display', qw(:DISPLAY) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Applications::Display', qw(:DBDISPLAY) ) };

TODO: {
  my $objectDisplay = ASNMTAP::Asnmtap::Applications::Display->new (
    _programName        => 'Display.t',
    _programDescription => 'Test ASNMTAP::Asnmtap::Applications::Display',
    _programVersion     => '3.002.003',
    _debug             => 0);

  isa_ok( $objectDisplay, 'ASNMTAP::Asnmtap::Applications::Display' );
  can_ok( $objectDisplay, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
}
