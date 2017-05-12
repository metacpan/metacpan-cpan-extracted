use Test::More tests => 103;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Plugins' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins', qw(:COMMANDS) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins', qw(:_HIDDEN) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins', qw(:PLUGINS %ERRORS %STATE %TYPE) ) };

TODO: {
  $ENV{ASNMTAP_PROXY} = "username:password\@server";

  my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
    _programName        => 'Plugins.t',
    _programDescription => 'Test ASNMTAP::Asnmtap::Plugins',
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

  isa_ok( $objectPlugins, 'ASNMTAP::Asnmtap::Plugins' );
  can_ok( $objectPlugins, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
  can_ok( $objectPlugins, qw(appendPerformanceData browseragent SSLversion clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );

  my ($returnCode, $errorStatus, $status, $stdout, $stderr);

  $returnCode = $objectPlugins->browseragent () eq 'Mozilla/5.0 (compatible; ASNMTAP; U; ASNMTAP 3.002.003 postfix; nl-BE; rv:3.002.003) Gecko/yyyymmdd libwww-perl/5.813' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::browseragent(): get');

  $returnCode = $objectPlugins->browseragent ( 'Mozilla/4.7' ) eq 'Mozilla/4.7' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::browseragent(): set');


  $returnCode = $objectPlugins->SSLversion ( 2 ) == 2 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::SSLversion(): set 2');

  $returnCode = $objectPlugins->SSLversion ( 3 ) == 3 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::SSLversion(): set 3');

  $returnCode = $objectPlugins->SSLversion ( 23 ) == 23 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::SSLversion(): set 23');

  $returnCode = $objectPlugins->SSLversion ( 32 ) == 3 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::SSLversion(): set 32');


  $returnCode = $objectPlugins->clientCertificate ('certFile') eq 'ssl/crt/alex-peeters.crt' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): get certFile');

  $returnCode = $objectPlugins->clientCertificate ('certFile' => 'certFile') eq 'certFile' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): set certFile');

  $returnCode = $objectPlugins->clientCertificate ('keyFile') eq 'ssl/key/alex-peeters-nopass.key' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): get keyFile');

  $returnCode = $objectPlugins->clientCertificate ('keyFile' => 'keyFile') eq 'keyFile' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): set keyFile');
  
  $returnCode = $objectPlugins->clientCertificate ('caFile') eq 'CA CERT PEER VERIFICATION FILE' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): get caFile');

  $returnCode = $objectPlugins->clientCertificate ('caFile' => 'caFile') eq 'caFile' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): set caFile');

  $returnCode = $objectPlugins->clientCertificate ('caDir') eq 'CA CERT PEER VERIFICATION DIR' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): get caDir');

  $returnCode = $objectPlugins->clientCertificate ('caDir' => 'caDir') eq 'caDir' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): set caDir');

  $returnCode = $objectPlugins->clientCertificate ('pkcs12File') eq 'CLIENT PKCS12 CERT SUPPORT FILE' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): get pkcs12File');

  $returnCode = $objectPlugins->clientCertificate ('pkcs12File' => 'pkcs12File') eq 'pkcs12File' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): set pkcs12File');

  $returnCode = $objectPlugins->clientCertificate ('pkcs12Password') eq 'CLIENT PKCS12 CERT SUPPORT PASSWORD' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): get pkcs12Password');

  $returnCode = $objectPlugins->clientCertificate ('pkcs12Password' => 'pkcs12Password') eq 'pkcs12Password' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): set pkcs12Password');

  $returnCode = $objectPlugins->clientCertificate ('pkcs12Password' => 'pkcs12Password') eq 'pkcs12Password' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::clientCertificate(): set pkcs12Password');


  $returnCode = $objectPlugins->programName () eq  'Plugins.t' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::programName(): get');

  $returnCode = $objectPlugins->programName ('-Change programName-') eq '-Change programName-' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::programName(): set');


  $returnCode = $objectPlugins->programDescription () eq 'Test ASNMTAP::Asnmtap::Plugins' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::programDescription(): get');

  $returnCode = $objectPlugins->programDescription ('-change programDescription-') eq '-change programDescription-' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::programDescription(): set');


  $returnCode = $objectPlugins->programVersion () eq '3.002.003' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::programVersion(): get');

  $returnCode = $objectPlugins->programVersion ('x.xxx.xxx') eq 'x.xxx.xxx' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::programVersion(): set');


  my $startTime = $objectPlugins->pluginValue('startTime');
  $errorStatus = ($startTime eq $objectPlugins->pluginValue('startTime')) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::PLUGINS::pluginValue(): get startTime');

  my $responseTime = $objectPlugins->setEndTime_and_getResponsTime($startTime);
  $errorStatus = (defined $responseTime) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::PLUGINS::setEndTime_and_getResponsTime(): set/get');

  my $endTime = $objectPlugins->pluginValue('endTime');
  $errorStatus = (defined $endTime) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::PLUGINS::endTime(): get');

  $returnCode = $objectPlugins->appendPerformanceData ();
  $errorStatus = (defined $returnCode) ? 1 : 0;
  ok ($errorStatus, 'ASNMTAP::Asnmtap::Plugins::PLUGINS::appendPerformanceData(): get');

  $returnCode = $objectPlugins->appendPerformanceData ('Plugin='.$startTime.'ms;;;;');
  $errorStatus = ($returnCode eq 'Plugin='.$startTime.'ms;;;;') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::appendPerformanceData(): set');

  $returnCode = $objectPlugins->pluginValue ('performanceData');
  $errorStatus = ($returnCode eq 'Plugin='.$startTime.'ms;;;;') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): get performanceData');


  $returnCode = $objectPlugins->timeout () == 30 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::timeout(): get');

  $returnCode = $objectPlugins->timeout (60) == 60 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::timeout(): set');

  $returnCode = $objectPlugins->debug () == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::debug(): get');

  $returnCode = $objectPlugins->debug (2) == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::debug(): set 2');

  $returnCode = $objectPlugins->debug (1) == 1 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::debug(): set 1');
  
  $returnCode = $objectPlugins->debug (0) == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::debug(): set 0');


  $returnCode = $objectPlugins->getOptionsValue ('boolean_debug_all') == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::getOptionsValue(): get boolean_debug_all');

  $returnCode = $objectPlugins->getOptionsValue ('boolean_debug_all') == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::getOptionsValue(): get boolean_debug_all');

  $returnCode = $objectPlugins->getOptionsValue ('boolean_debug_NOK') == 0 ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::getOptionsValue(): get boolean_debug_NOK');


  $returnCode = ($objectPlugins->proxy( server => 'server' ) eq 'server') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::proxy(): set server');

  $returnCode = ($objectPlugins->proxy( username => 'username' ) eq 'username') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::proxy(): set username');

  $returnCode = ($objectPlugins->proxy( password => 'password' ) eq 'password') ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::proxy(): set password');


  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{DEPENDENT} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): get stateValue');


  $objectPlugins->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateValue OK/OK');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError OK/OK');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue OK/OK');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{OK} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError OK/OK');


  $objectPlugins->pluginValue ( stateValue => $ERRORS{WARNING} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{WARNING} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue WARNING/WARNING');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{WARNING}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError WARNING/WARNING');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue WARNING/WARNING');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{WARNING}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError WARNING/WARNING');


  $objectPlugins->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateValue OK/WARNING');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError OK/WARNING');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue OK/WARNING');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{WARNING} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError OK/WARNING');

  
  $objectPlugins->pluginValue ( stateValue => $ERRORS{CRITICAL} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{CRITICAL} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue CRITICAL/CRITICAL');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{CRITICAL}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError CRITICAL/CRITICAL');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue CRITICAL/CRITICAL');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{CRITICAL}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError CRITICAL/CRITICAL');

  
  $objectPlugins->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateValue OK/CRITICAL');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError OK/CRITICAL');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue OK/CRITICAL');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError OK/CRITICAL');


  $objectPlugins->pluginValue ( stateValue => $ERRORS{WARNING} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{CRITICAL} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue WARNING/CRITICAL');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{WARNING}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError WARNING/CRITICAL');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue WARNING/CRITICAL');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{WARNING}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{CRITICAL} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError WARNING/CRITICAL');

  
  $objectPlugins->pluginValue ( stateValue => $ERRORS{UNKNOWN} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue UNKNOWN/UNKNOWN'); 

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{UNKNOWN}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError UNKNOWN/UNKNOWN');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{UNKNOWN} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue UNKNOWN/UNKNOWN');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{UNKNOWN}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError UNKNOWN/UNKNOWN');


  $objectPlugins->pluginValue ( stateValue => $ERRORS{OK} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateValue OK/UNKNOWN');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{OK}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError OK/UNKNOWN');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue OK/UNKNOWN');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{OK}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError OK/UNKNOWN');

  
  $objectPlugins->pluginValue ( stateValue => $ERRORS{WARNING} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue WARNING/UNKNOWN');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{WARNING}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError WARNING/UNKNOWN');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue WARNING/UNKNOWN');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{WARNING}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError WARNING/UNKNOWN');
  

  $objectPlugins->pluginValue ( stateValue => $ERRORS{CRITICAL} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue CRITICAL/UNKNOWN');

  $objectPlugins->pluginValue ( stateError => $STATE{$ERRORS{CRITICAL}} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): set/get stateError CRITICAL/UNKNOWN');

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateValue CRITICAL/UNKNOWN');

  $objectPlugins->pluginValues ( { stateError => $STATE{$ERRORS{CRITICAL}} }, $TYPE{APPEND} );
  $returnCode = $objectPlugins->pluginValue ( 'stateValue' ) eq $ERRORS{UNKNOWN} ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get stateError CRITICAL/UNKNOWN');


  $objectPlugins->pluginValue ( message => 'message' );
  $returnCode = $objectPlugins->pluginValue ( 'message' ) eq 'message' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): get message');

  $objectPlugins->pluginValue ( alert => 'alert' );
  $returnCode = $objectPlugins->pluginValue ( 'alert' ) eq 'alert' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): get alert');

  $objectPlugins->pluginValue ( error => 'error' );
  $returnCode = $objectPlugins->pluginValue ( 'error' ) eq 'error' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): get error');

  $objectPlugins->pluginValue ( result => 'result' );
  $returnCode = $objectPlugins->pluginValue ( 'result' ) eq 'result' ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValue(): get result');
  
  $objectPlugins->pluginValues ( { statusValue => $ERRORS{OK}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{APPEND} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectPlugins->pluginValue ( 'message' ) eq 'message' and $objectPlugins->pluginValue ( 'alert' ) eq 'alert - alert' and $objectPlugins->pluginValue ( 'error' ) eq 'error - error' and $objectPlugins->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get statusValue OK, message, alert, error and result, 1');

  $objectPlugins->pluginValues ( { statusValue => $ERRORS{OK}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{REPLACE} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectPlugins->pluginValue ( 'message' ) eq 'message' and $objectPlugins->pluginValue ( 'alert' ) eq 'alert' and $objectPlugins->pluginValue ( 'error' ) eq 'error' and $objectPlugins->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get statusValue OK, message, alert, error and result, 0');

  $objectPlugins->pluginValues ( { statusError => $STATE{$ERRORS{OK}}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{APPEND} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectPlugins->pluginValue ( 'message' ) eq 'message' and $objectPlugins->pluginValue ( 'alert' ) eq 'alert - alert' and $objectPlugins->pluginValue ( 'error' ) eq 'error - error' and $objectPlugins->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get statusError OK, message, alert, error and result, 1');

  $objectPlugins->pluginValues ( { statusError => $STATE{$ERRORS{OK}}, message => 'message', alert => 'alert', error => 'error', result => 'result' }, $TYPE{REPLACE} );
  $returnCode = ( $objectPlugins->pluginValue ( 'stateValue' ) == $ERRORS{UNKNOWN} and $objectPlugins->pluginValue ( 'message' ) eq 'message' and $objectPlugins->pluginValue ( 'alert' ) eq 'alert' and $objectPlugins->pluginValue ( 'error' ) eq 'error' and $objectPlugins->pluginValue ( 'result' ) eq 'result' ) ? 1 : 0;
  ok ($returnCode, 'ASNMTAP::Asnmtap::Plugins::pluginValues(): set/get statusError OK, message, alert, error and result, 0');


  $returnCode = $objectPlugins->call_system("echo 'ASNMTAP'");
  ok ( $returnCode == $ERRORS{OK}, 'ASNMTAP::Asnmtap::Plugins::call_system("echo \'ASNMTAP\'")' );

  $returnCode = $objectPlugins->call_system("ASNMTAP 'ASNMTAP'");
  ok ( $returnCode == $ERRORS{UNKNOWN}, 'ASNMTAP::Asnmtap::Plugins::call_system("ASNMTAP \'ASNMTAP\'")' );

  no warnings 'deprecated';
  $objectPlugins->{_pluginValues}->{stateValue} = $ERRORS{OK};
  $objectPlugins->{_pluginValues}->{stateError} = $STATE{$ERRORS{OK}};
  $objectPlugins->exit (0);
}
