use Test::More tests => 102;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Plugins::Nagios' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Nagios' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Nagios', qw(:COMMANDS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Nagios', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Nagios', qw(:NAGIOS %ERRORS %STATE %TYPE) ) };

TODO: {
  $ENV{ASNMTAP_PROXY} = "username:password\@server";

  my $objectNagios = ASNMTAP::Asnmtap::Plugins::Nagios->new (
    _programName        => 'Nagios.t',
    _programDescription => 'Test ASNMTAP::Asnmtap::Plugins::Nagios',
    _programVersion     => '3.002.003',
    _programUsagePrefix => '[--commandLineOption]',
    _programHelpPrefix  => '--commandLineOption ...',
    _programGetOptions  => ['commandLineOption=s', 'host|H:s', 'url|U:s', 'port|P:i', 'password|p|passwd:s', 'username|u|loginname:s', 'community|C:s', 'timeout|t:i', 'trendline|T:i', 'environment|e:s', 'proxy:s'],
    _SSLversion         => 23,
    _clientCertificate  => { certFile       => 'ssl/crt/alex-peeters.crt', 
                             keyFile        => 'ssl/key/alex-peeters-nopass.key', 
                             caFile         => 'CA CERT PEER VERIFICATION FILE',
                             caDir          => 'CA CERT PEER VERIFICATION DIR',
                             pkcs12File     => 'CLIENT PKCS12 CERT SUPPORT FILE',
                             pkcs12Password => 'CLIENT PKCS12 CERT SUPPORT PASSWORD'},
    _timeout            => 30,
    _debug              => 0);

  isa_ok( $objectNagios, 'ASNMTAP::Asnmtap::Plugins::Nagios' );
  can_ok( $objectNagios, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
  can_ok( $objectNagios, qw(appendPerformanceData browseragent SSLversion clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );

  my ($returnCode, $errorStatus, $status, $stdout, $stderr);

  $returnCode = $objectNagios->browseragent () eq 'Mozilla/5.0 (compatible; ASNMTAP; U; ASNMTAP 3.002.003 postfix; nl-BE; rv:3.002.003) Gecko/yyyymmdd libwww-perl/5.813' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::browseragent(): get');

  $returnCode = $objectNagios->browseragent ( 'Mozilla/4.7' ) eq 'Mozilla/4.7' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::browseragent(): set');


  $returnCode = $objectNagios->SSLversion ( 2 ) == 2 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::SSLversion(): set 2');

  $returnCode = $objectNagios->SSLversion ( 3 ) == 3 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::SSLversion(): set 3');

  $returnCode = $objectNagios->SSLversion ( 23 ) == 23 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::SSLversion(): set 23');

  $returnCode = $objectNagios->SSLversion ( 32 ) == 3 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::SSLversion(): set 32');


  $returnCode = $objectNagios->clientCertificate ('certFile') eq 'ssl/crt/alex-peeters.crt' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): get certFile');

  $returnCode = $objectNagios->clientCertificate ('certFile' => 'certFile') eq 'certFile' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): set certFile');

  $returnCode = $objectNagios->clientCertificate ('keyFile') eq 'ssl/key/alex-peeters-nopass.key' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): get keyFile');

  $returnCode = $objectNagios->clientCertificate ('keyFile' => 'keyFile') eq 'keyFile' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): set keyFile');
  
  $returnCode = $objectNagios->clientCertificate ('caFile') eq 'CA CERT PEER VERIFICATION FILE' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): get caFile');

  $returnCode = $objectNagios->clientCertificate ('caFile' => 'caFile') eq 'caFile' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): set caFile');

  $returnCode = $objectNagios->clientCertificate ('caDir') eq 'CA CERT PEER VERIFICATION DIR' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): get caDir');

  $returnCode = $objectNagios->clientCertificate ('caDir' => 'caDir') eq 'caDir' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): set caDir');

  $returnCode = $objectNagios->clientCertificate ('pkcs12File') eq 'CLIENT PKCS12 CERT SUPPORT FILE' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): get pkcs12File');

  $returnCode = $objectNagios->clientCertificate ('pkcs12File' => 'pkcs12File') eq 'pkcs12File' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): set pkcs12File');

  $returnCode = $objectNagios->clientCertificate ('pkcs12Password') eq 'CLIENT PKCS12 CERT SUPPORT PASSWORD' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): get pkcs12Password');

  $returnCode = $objectNagios->clientCertificate ('pkcs12Password' => 'pkcs12Password') eq 'pkcs12Password' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): set pkcs12Password');

  $returnCode = $objectNagios->clientCertificate ('pkcs12Password' => 'pkcs12Password') eq 'pkcs12Password' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::clientCertificate(): set pkcs12Password');


  $returnCode = $objectNagios->programName () eq  'Nagios.t' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::programName(): get');

  $returnCode = $objectNagios->programName ('-Change programName-') eq '-Change programName-' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::programName(): set');


  $returnCode = $objectNagios->programDescription () eq 'Test ASNMTAP::Asnmtap::Plugins::Nagios' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::programDescription(): get');

  $returnCode = $objectNagios->programDescription ('-change programDescription-') eq '-change programDescription-' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::programDescription(): set');


  $returnCode = $objectNagios->programVersion () eq '3.002.003' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::programVersion(): get');

  $returnCode = $objectNagios->programVersion ('x.xxx.xxx') eq 'x.xxx.xxx' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::programVersion(): set');


  my $startTime = $objectNagios->pluginValue('startTime');
  $errorStatus = ($startTime eq $objectNagios->pluginValue('startTime')) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::Nagios::PLUGINS::pluginValue(): get startTime');

  my $responseTime = $objectNagios->setEndTime_and_getResponsTime($startTime);
  $errorStatus = (defined $responseTime) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::Nagios::PLUGINS::setEndTime_and_getResponsTime(): set/get');

  my $endTime = $objectNagios->pluginValue('endTime');
  $errorStatus = (defined $endTime) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::Nagios::PLUGINS::endTime(): get');

  $returnCode = $objectNagios->appendPerformanceData ();
  $errorStatus = (defined $returnCode) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::Nagios::PLUGINS::appendPerformanceData(): get');

  $returnCode = $objectNagios->appendPerformanceData ('Plugin='.$startTime.'ms;;;;');
  $errorStatus = ($returnCode eq 'Plugin='.$startTime.'ms;;;;') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::appendPerformanceData(): set');

  $returnCode = $objectNagios->pluginValue ('performanceData');
  $errorStatus = ($returnCode eq 'Plugin='.$startTime.'ms;;;;') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): get performanceData');


  $returnCode = $objectNagios->timeout () == 30 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::timeout(): get');

  $returnCode = $objectNagios->timeout (60) == 60 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::timeout(): set');

  $returnCode = $objectNagios->debug () == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::debug(): get');

  $returnCode = $objectNagios->debug (2) == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::debug(): set 2');

  $returnCode = $objectNagios->debug (1) == 1 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::debug(): set 1');
  
  $returnCode = $objectNagios->debug (0) == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::debug(): set 0');


  $returnCode = $objectNagios->getOptionsValue ('boolean_debug_all') == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::getOptionsValue(): get boolean_debug_all');

  $returnCode = $objectNagios->getOptionsValue ('boolean_debug_all') == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::getOptionsValue(): get boolean_debug_all');

  $returnCode = $objectNagios->getOptionsValue ('boolean_debug_NOK') == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::getOptionsValue(): get boolean_debug_NOK');


  $returnCode = ($objectNagios->proxy( server => 'server' ) eq 'server') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::proxy(): set server');

  $returnCode = ($objectNagios->proxy( username => 'username' ) eq 'username') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::proxy(): set username');

  $returnCode = ($objectNagios->proxy( password => 'password' ) eq 'password') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::proxy(): set password');


  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{DEPENDENT} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): get stateValue');


  $objectNagios->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateValue OK/OK');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError OK/OK');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue OK/OK');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError OK/OK');


  $objectNagios->pluginValue ( stateValue => $ERRORS{WARNING} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{WARNING} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue WARNING/WARNING');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{WARNING}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError WARNING/WARNING');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{WARNING} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue WARNING/WARNING');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{WARNING}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError WARNING/WARNING');


  $objectNagios->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateValue OK/WARNING');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError OK/WARNING');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue OK/WARNING');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError OK/WARNING');

  
  $objectNagios->pluginValue ( stateValue => $ERRORS{CRITICAL} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{CRITICAL} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue CRITICAL/CRITICAL');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{CRITICAL}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError CRITICAL/CRITICAL');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue CRITICAL/CRITICAL');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{CRITICAL}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError CRITICAL/CRITICAL');

  
  $objectNagios->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateValue OK/CRITICAL');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError OK/CRITICAL');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue OK/CRITICAL');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError OK/CRITICAL');


  $objectNagios->pluginValue ( stateValue => $ERRORS{WARNING} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{CRITICAL} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue WARNING/CRITICAL');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{WARNING}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError WARNING/CRITICAL');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{WARNING} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue WARNING/CRITICAL');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{WARNING}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError WARNING/CRITICAL');

  
  $objectNagios->pluginValue ( stateValue => $ERRORS{UNKNOWN} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue UNKNOWN/UNKNOWN'); 

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{UNKNOWN}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError UNKNOWN/UNKNOWN');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{UNKNOWN} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue UNKNOWN/UNKNOWN');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{UNKNOWN}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError UNKNOWN/UNKNOWN');


  $objectNagios->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateValue OK/UNKNOWN');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError OK/UNKNOWN');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue OK/UNKNOWN');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError OK/UNKNOWN');

  
  $objectNagios->pluginValue ( stateValue => $ERRORS{WARNING} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue WARNING/UNKNOWN');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{WARNING}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError WARNING/UNKNOWN');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{WARNING} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue WARNING/UNKNOWN');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{WARNING}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError WARNING/UNKNOWN');
  

  $objectNagios->pluginValue ( stateValue => $ERRORS{CRITICAL} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue CRITICAL/UNKNOWN');

  $objectNagios->pluginValue ( stateError => $STATE{$ERRORS{CRITICAL}} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): set/get stateError CRITICAL/UNKNOWN');

  $objectNagios->pluginValues ( { stateValue => $ERRORS{CRITICAL} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateValue CRITICAL/UNKNOWN');

  $objectNagios->pluginValues ( { stateError => $STATE{$ERRORS{CRITICAL}} }, $TYPE{APPEND} );
  $returnCode = $objectNagios->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get stateError CRITICAL/UNKNOWN');


  $objectNagios->pluginValue ( message => 'message' );
  $returnCode = $objectNagios->pluginValue ( 'message' ) eq 'message' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): get message');

  $objectNagios->pluginValue ( alert => 'alert' );
  $returnCode = $objectNagios->pluginValue ( 'alert' ) eq 'alert' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): get alert');

  $objectNagios->pluginValue ( error => 'error' );
  $returnCode = $objectNagios->pluginValue ( 'error' ) eq 'error' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): get error');

  $objectNagios->pluginValue ( result => 'result' );
  $returnCode = $objectNagios->pluginValue ( 'result' ) eq 'result' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValue(): get result');
  
  $objectNagios->pluginValues ( { statusValue => $ERRORS{OK}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{APPEND} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectNagios->pluginValue ( 'message' ) eq 'message' and $objectNagios->pluginValue ( 'alert' ) eq 'alert - alert' and $objectNagios->pluginValue ( 'error' ) eq 'error - error' and $objectNagios->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get statusValue OK, message, alert, error and result, 1');

  $objectNagios->pluginValues ( { statusValue => $ERRORS{OK}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{REPLACE} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectNagios->pluginValue ( 'message' ) eq 'message' and $objectNagios->pluginValue ( 'alert' ) eq 'alert' and $objectNagios->pluginValue ( 'error' ) eq 'error' and $objectNagios->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get statusValue OK, message, alert, error and result, 0');

  $objectNagios->pluginValues ( { statusError => $STATE{$ERRORS{OK}}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{APPEND} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectNagios->pluginValue ( 'message' ) eq 'message' and $objectNagios->pluginValue ( 'alert' ) eq 'alert - alert' and $objectNagios->pluginValue ( 'error' ) eq 'error - error' and $objectNagios->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get statusError OK, message, alert, error and result, 1');

  $objectNagios->pluginValues ( { statusError => $STATE{$ERRORS{OK}}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{REPLACE} );
  $returnCode = ( $objectNagios->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectNagios->pluginValue ( 'message' ) eq 'message' and $objectNagios->pluginValue ( 'alert' ) eq 'alert' and $objectNagios->pluginValue ( 'error' ) eq 'error' and $objectNagios->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::Nagios::pluginValues(): set/get statusError OK, message, alert, error and result, 0');


  $returnCode = $objectNagios->call_system("echo 'ASNMTAP'");
  ok ( $returnCode == $ERRORS{OK}, 'ASNMTAP::Asnmtap::Plugins::Nagios::call_system("echo \'ASNMTAP\'")' );
  
  $returnCode = $objectNagios->call_system("ASNMTAP 'ASNMTAP'");
  ok ( $returnCode == $ERRORS{UNKNOWN}, 'ASNMTAP::Asnmtap::Plugins::Nagios::call_system("ASNMTAP \'ASNMTAP\'")' );


  no warnings 'deprecated';
  $objectNagios->{_pluginValues}->{stateValue} = $ERRORS{OK};
  $objectNagios->{_pluginValues}->{stateError} = $STATE{$ERRORS{OK}};
  $objectNagios->exit (0);
}
