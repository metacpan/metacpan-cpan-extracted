use Test::More tests => 7;

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Mail' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::Mail', qw(:ALL) ) };

TODO: {
  use ASNMTAP::Asnmtap::Plugins v3.002.003;
  use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS %STATE);

  my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
    _programName        => 'Mail.t',
    _programDescription => 'Test ASNMTAP::Asnmtap::Plugins::MAIL',
    _programVersion     => '3.002.003',
    _programGetOptions  => ['environment|e:s', 'timeout|t:i', 'trendline|T:i'],
    _timeout            => 30,
    _debug              => 0);

  no warnings 'deprecated';
  $objectPlugins->{_getOptionsArgv}->{environment} = 'P';

  isa_ok( $objectPlugins, 'ASNMTAP::Asnmtap::Plugins' );
  can_ok( $objectPlugins, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp) );
  can_ok( $objectPlugins, qw(appendPerformanceData browseragent SSLversion clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );

  my $body = "\nThis is the body of the email !!! ...\n";

  use ASNMTAP::Asnmtap::Plugins::Mail v3.002.003;

  my $objectMAIL = ASNMTAP::Asnmtap::Plugins::Mail->new (
    _asnmtapInherited => \$objectPlugins,
    _SMTP             => { smtp => [ qw(smtp.citap.be) ], mime => 0 },
    _mailType         => 0,
    _mail             => {
                           from   => 'alex.peeters@citap.com',
                           to     => 'asnmtap@citap.com',
                           status => $APPLICATION .' Status UP',
                           body   => $body
                         }
  );

  isa_ok( $objectMAIL, 'ASNMTAP::Asnmtap::Plugins::Mail' );
  can_ok( $objectMAIL, qw(sending_fingerprint_mail) );

  no warnings 'deprecated';
  $objectPlugins->{_pluginValues}->{stateValue} = $ERRORS{OK};
  $objectPlugins->{_pluginValues}->{stateError} = $STATE{$ERRORS{OK}};
  $objectPlugins->exit (0);
}