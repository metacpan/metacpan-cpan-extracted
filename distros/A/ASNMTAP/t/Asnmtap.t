use Test::More tests => 27;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap', qw(:ASNMTAP) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap', qw(:COMMANDS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap', qw(:_HIDDEN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap', qw(:APPLICATIONS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap', qw(:PLUGINS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap', qw(
  $APPLICATION $BUSINESS $DEPARTMENT $COPYRIGHT $SENDEMAILTO
  $CAPTUREOUTPUT
  $PREFIXPATH $APPLICATIONPATH $PLUGINPATH $LOGPATH $PIDPATH $PERL5LIB $MANPATH $LD_LIBRARY_PATH
  %ERRORS %STATE %TYPE
  $CHATCOMMAND $DIFFCOMMAND $KILLALLCOMMAND $PERLCOMMAND $PPPDCOMMAND $ROUTECOMMAND $RSYNCCOMMAND $SCPCOMMAND $SSHCOMMAND
  &_checkAccObjRef
  &_checkSubArgs0 &_checkSubArgs1 &_checkSubArgs2
  &_checkReadOnly0 &_checkReadOnly1 &_checkReadOnly2
  &_dumpValue
) ) };
														 
TODO: {
  my $objectAsnmtap = ASNMTAP::Asnmtap->new (
    _programName        => 'Asnmtap.t',
    _programDescription => 'Test ASNMTAP::Asnmtap',
    _programVersion     => '3.002.003',
    _programUsagePrefix => '[--commandLineOption]',
    _programHelpPrefix  => "--commandLineOption ...",
    _programGetOptions  => ['commandLineOption=s'],
    _timeout            => 30,
    _debug              => 0);

  isa_ok( $objectAsnmtap, 'ASNMTAP::Asnmtap' );
  can_ok( $objectAsnmtap, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp call_system) );

  is ( $objectAsnmtap->programName(), 'Asnmtap.t', 'ASNMTAP::Asnmtap::programName()' );
  is ( $objectAsnmtap->programName('-Change programName-'), '-Change programName-', 'ASNMTAP::Asnmtap::programName(\'-Change programName-\')' );

  is ( $objectAsnmtap->programDescription(), 'Test ASNMTAP::Asnmtap', 'ASNMTAP::Asnmtap::programDescription()' );
  is ( $objectAsnmtap->programDescription('-change programDescription-'), '-change programDescription-', 'ASNMTAP::Asnmtap::programDescription(\'-change programDescription-\')' );

  is ( $objectAsnmtap->programVersion(), '3.002.003', 'ASNMTAP::Asnmtap::programVersion()' );
  is ( $objectAsnmtap->programVersion('-change programVersion-'), '-change programVersion-', 'ASNMTAP::Asnmtap::programVersion(\'-change programVersion-\')' );

  is ( $objectAsnmtap->getOptionsArgv('commandLineOption'), undef, 'ASNMTAP::Asnmtap::getOptionsArgv(\'commandLineOption\')' );

  is ( $objectAsnmtap->getOptionsValue ('commandLineOption'), undef, 'ASNMTAP::Asnmtap::getOptionsValue(\'commandLineOption\')' );

  is ( $objectAsnmtap->debug(), 0, 'ASNMTAP::Asnmtap::debug()' );
  is ( $objectAsnmtap->debug(1), 1, 'ASNMTAP::Asnmtap::debug(1)' );
  is ( $objectAsnmtap->debug(2), 1, 'ASNMTAP::Asnmtap::debug(2)' );
  is ( $objectAsnmtap->debug(0), 0, 'ASNMTAP::Asnmtap::debug()' );

  is ( $objectAsnmtap->dumpData(1), 1, 'ASNMTAP::Asnmtap::dumpData(1)' );
  is ( $objectAsnmtap->dumpData(), 0, 'ASNMTAP::Asnmtap::dumpData(1)' );

  my ( $status, $stdout, $stderr ) = $objectAsnmtap->call_system("echo 'ASNMTAP'");
  ok ( $status == 1, 'ASNMTAP::Asnmtap::call_system("echo \'ASNMTAP\'")' );

  ( $status, $stdout, $stderr ) = $objectAsnmtap->call_system("ASNMTAP 'ASNMTAP'");
  ok ( $status == 0, 'ASNMTAP::Asnmtap::call_system("ASNMTAP \'ASNMTAP\'")' );
}


