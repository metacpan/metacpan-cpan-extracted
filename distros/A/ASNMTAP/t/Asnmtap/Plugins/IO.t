use Test::More tests => 21;

BEGIN { require_ok ( 'ASNMTAP::Asnmtap::Plugins::IO' ) };

BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::IO' ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::IO', qw(:ALL) ) };
BEGIN { use_ok ( 'ASNMTAP::Asnmtap::Plugins::IO', qw(:SOCKET) ) };

TODO: {
  use ASNMTAP::Asnmtap::Plugins v3.002.003;
  use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

  my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
    _programName        => 'IO.t',
    _programDescription => 'Test ASNMTAP::Asnmtap::Plugins::IO',
    _programVersion     => '3.002.003',
    _timeout            => 30,
    _debug              => 0);

  isa_ok( $objectPlugins, 'ASNMTAP::Asnmtap::Plugins' );
  can_ok( $objectPlugins, qw(programName programDescription programVersion getOptionsArgv getOptionsValue debug dumpData printRevision printRevision printUsage printHelp call_system) );
  can_ok( $objectPlugins, qw(appendPerformanceData browseragent SSLversion clientCertificate pluginValue pluginValues proxy timeout setEndTime_and_getResponsTime write_debugfile call_system exit) );

  my ($returnCode, $errorStatus);

  $returnCode = scan_socket_info ( asnmtapInherited => \$objectPlugins );
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute protocol\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::protocol: Missing attribute protocol' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'rfc'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QWrong value for attribute protocol: rfc\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::protocol: Wrong value for attribute protocol: rfc' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute host\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::host: Missing attribute host' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'host name'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QWrong value for attribute host: host name\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::host: Wrong value for attribute host: host name' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute port\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::port: Missing attribute port' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 'pop3(110)'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QWrong value for attribute port: pop3(110)\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::port: Wrong value for attribute port: pop3(110)' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute service\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::service: Missing attribute service' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110,
    service          => 'pop3'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute username\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::username: Missing attribute username' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110,
    service          => 'pop3',
    POP3             => { username => 'username' },
    socketTimeout    => 'timeout'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute password\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::password: Missing attribute password' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110,
    service          => 'pop3',
    POP3             => { username => 'username', password => 'password' },
    socketTimeout    => 'timeout'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute serviceReady\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::serviceReady: Missing attribute serviceReady' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110,
    service          => 'pop3',
    POP3             => { username => 'username', password => 'password', serviceReady => 'serviceReady' },
    socketTimeout    => 'timeout'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute passwordRequired\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::passwordRequired: Missing attribute passwordRequired' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110,
    service          => 'pop3',
    POP3             => { username => 'username', password => 'password', serviceReady => 'serviceReady', passwordRequired => 'passwordRequired' },
    socketTimeout    => 'timeout'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute mailMessages\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::mailMessages: Missing attribute mailMessages' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110,
    service          => 'pop3',
    POP3             => { username => 'username', password => 'password', serviceReady => 'serviceReady', passwordRequired => 'passwordRequired', mailMessages => 'mailMessages' },
    socketTimeout    => 'timeout'
  );

  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QMissing attribute closingSession\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::closingSession: Missing attribute closingSession' );

  $returnCode = scan_socket_info (
    asnmtapInherited => \$objectPlugins,
    protocol         => 'tcp',
    host             => 'smtp.citap.com',
    port             => 110,
    service          => 'pop3',
    POP3             => { username => 'username', password => 'password', serviceReady => 'serviceReady', passwordRequired => 'passwordRequired', mailMessages => 'mailMessages', closingSession => 'closingSession' },
    socketTimeout    => 'timeout'
  );
  
  $errorStatus = ($returnCode == 3 && $objectPlugins->pluginValue ('error') =~ /\QWrong value for attribute socketTimeout: timeout\E/);
  ok ( $errorStatus, 'ASNMTAP::Asnmtap::Plugins::IO::scan_socket_info::socketTimeout: Wrong value for attribute socketTimeout: timeout' );

  no warnings 'deprecated';
  $objectPlugins->{_pluginValues}->{stateValue} = $ERRORS{OK};
  $objectPlugins->{_pluginValues}->{stateError} = $STATE{$ERRORS{OK}};
  $objectPlugins->exit (0);
}