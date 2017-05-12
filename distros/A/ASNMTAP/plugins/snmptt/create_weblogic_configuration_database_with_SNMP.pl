#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, create_weblogic_configuration_database_with_SNMP.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Data::Dumper;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'create_weblogic_configuration_database_with_SNMP.pl',
  _programDescription => 'Create Weblogic Configuration Database with SNMP',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--uKey|-K=<uKey>] [-s|--server <hostname>] [--database=<database>]',
  _programHelpPrefix  => "-K, --uKey=<uKey>
-s, --server=<hostname> (default: localhost)
--database=<database> (default: weblogic)",
  _programGetOptions  => ['uKey|K:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $serverDB  = $objectPlugins->getOptionsArgv ('server')   ? $objectPlugins->getOptionsArgv ('server')   : 'localhost';
my $port      = $objectPlugins->getOptionsArgv ('port')     ? $objectPlugins->getOptionsArgv ('port')     : 3306;
my $database  = $objectPlugins->getOptionsArgv ('database') ? $objectPlugins->getOptionsArgv ('database') : 'weblogicConfig';
my $username  = $objectPlugins->getOptionsArgv ('username') ? $objectPlugins->getOptionsArgv ('username') : 'jUnit';
my $password  = $objectPlugins->getOptionsArgv ('password') ? $objectPlugins->getOptionsArgv ('password') : '<PASSWORD>';

my $uniqueKey = $objectPlugins->getOptionsArgv ('uKey');
my $debug     = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my %serverTable  = ( serverName          => "SNMPv2-SMI::enterprises.140.625.730.1.15",      # `SERVER_NAME`
                     serverParent        => "SNMPv2-SMI::enterprises.140.625.730.1.20",      # `DOMAIN_NAME`
                     serverMachine       => "SNMPv2-SMI::enterprises.140.625.730.1.115",     # `MACHINE`
                     serverListenPort    => "SNMPv2-SMI::enterprises.140.625.730.1.120",     # `LISTEN_PORT`
                     serverCluster       => "SNMPv2-SMI::enterprises.140.625.730.1.130",     # `CLUSTER_NAME`
                     serverExpectedToRun => "SNMPv2-SMI::enterprises.140.625.730.1.155",     # `EXPECTED_TO_RUN`
                     serverListenAddress => "SNMPv2-SMI::enterprises.140.625.730.1.220" );   # `LISTEN_ADDRESS`

my %clusterTable = ( clusterName         => "SNMPv2-SMI::enterprises.140.625.510.1.15",      # `CLUSTER_NAME`
                     clusterServers      => "SNMPv2-SMI::enterprises.140.625.510.1.25" );    # `CLUSTER_SERVERS`

my %queueTable =   ( queueOID            => "SNMPv2-SMI::enterprises.140.625.220.1.15.32" ); # `QUEUE_OID`

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $callsystem   = 0;

my %infoServers  = ();
my %infoClusters = ();
my %infoQueues   = ();

my $returnCode   = $ERRORS{OK};
my $alert        = 'OK';

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ( $dbh, $sth, $prepareString );

$dbh = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbh ) {
  my $rv = 1;
  my %adminServers = ();
  my ( $adminName, $hosts, $community, $environment, $version, $activated, $uKey );

  my $sqlSTRING = 'SELECT ADMIN_NAME, HOSTS, COMMUNITY, VERSION, ENV, ACTIVATED, uKey FROM `ADMIN_CONFIG`';
  $sqlSTRING .= " WHERE UKEY='$uniqueKey'" if ( defined $uniqueKey );
  print "    $sqlSTRING\n" if ( $debug );
  $sth = $dbh->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
  $sth->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;
  $sth->bind_columns( \$adminName, \$hosts, \$community, \$version, \$environment, \$activated, \$uKey ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->bind: '. $sqlSTRING ) if $rv;

  if ( $rv ) {
    while( $sth->fetch() ) {
      $adminServers{"$adminName"}->{hosts}       = $hosts;
      $adminServers{"$adminName"}->{community}   = $community;
      $adminServers{"$adminName"}->{version}     = $version;
      $adminServers{"$adminName"}->{environment} = $environment;
      $adminServers{"$adminName"}->{activated}   = $activated;
      $adminServers{"$adminName"}->{uKey}        = $uKey;
    }

    $sth->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->finish: '. $sqlSTRING );
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  while ( my ($domain, $hash) = each( %adminServers ) ) {
    while ( my ($key, $oid) = each( %serverTable ) ) { _snmpwalk ( \$objectPlugins, \%infoServers, $domain, $hash, $key, $oid, $callsystem, 1, $debug ); }
  }

  print $debug, "\n", Dumper ( %infoServers ), "\n" if ( $debug > 3 );

  while ( my ($domain, $hash) = each( %infoServers ) ) {
    print "\n$domain\n" if ( $debug );

    while ( my ($key, $server) = each( %{$hash} ) ) {
      if ( $debug ) {
        print "\n";
        while ( my ($key, $value) = each( %{$server} ) ) { print "$key = $value\n"; }
      }

      my $domain_name = ( defined $server->{serverParent} ? $server->{serverParent} : 'DOMAIN:'. $domain );
      my $sqlSTRING = 'SELECT count(SERVER_NAME) FROM `SERVERS` WHERE SERVER_NAME="'. $server->{serverName} .'" AND DOMAIN_NAME="'. $domain_name .'"';
      print "    $sqlSTRING\n" if ( $debug );
      $sth = $dbh->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sth->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        my $updateRecord = $sth->fetchrow_array();
        $sth->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->finish: '. $sqlSTRING );

        if ( $updateRecord ) {
          $sqlSTRING = 'UPDATE `SERVERS` SET SERVER_NAME="'. $server->{serverName} .'", DOMAIN_NAME="'. $domain_name .'", MACHINE="'. $server->{serverMachine} .'", LISTEN_PORT="'. $server->{serverListenPort} .'", CLUSTER_NAME="'. $server->{serverCluster} .'", EXPECTED_TO_RUN="'. $server->{serverExpectedToRun} .'", ENV="'. $server->{environment} .'", UKEY="'. $server->{uKey} .'", LISTEN_ADDRESS="'. $server->{serverListenAddress} .'" WHERE SERVER_NAME="'. $server->{serverName} .'" AND DOMAIN_NAME="'. $domain_name .'"';
        } else {
          $sqlSTRING = 'INSERT INTO `SERVERS` SET SERVER_NAME="'. $server->{serverName} .'", DOMAIN_NAME="'. $domain_name .'", MACHINE="'. $server->{serverMachine} .'", LISTEN_PORT="'. $server->{serverListenPort} .'", CLUSTER_NAME="'. $server->{serverCluster} .'", EXPECTED_TO_RUN="'. $server->{serverExpectedToRun} .'", ENV="'. $server->{environment} .'", UKEY="'. $server->{uKey} .'", LISTEN_ADDRESS="'. $server->{serverListenAddress} .'"';
        }

        print "    $sqlSTRING\n" if ( $debug );
        $dbh->do ( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlSTRING );
      }

    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  while ( my ($domain, $hash) = each( %adminServers ) ) {
    while ( my ($key, $oid) = each( %clusterTable ) ) { _snmpwalk ( \$objectPlugins, \%infoClusters, $domain, $hash, $key, $oid, $callsystem, 2, $debug ); }
  }

  print $debug, "\n", Dumper ( %infoClusters ), "\n" if ( $debug > 3 );

  while ( my ($domain, $hash) = each( %infoClusters ) ) {
    print "\n$domain\n" if ( $debug );

    while ( my ($key, $cluster) = each( %{$hash} ) ) {
      if ( $debug ) {
        print "\n";
        while ( my ($key, $value) = each( %{$cluster} ) ) { print "$key = $value\n" }
        print "\n". $cluster->{clusterName} .' => '. $cluster->{clusterServers} ."\n";
      }

      my $sqlSTRING = 'SELECT count(CLUSTER_NAME) FROM `CLUSTERS` WHERE CLUSTER_NAME="'. $cluster->{clusterName} .'"';
      print "    $sqlSTRING\n" if ( $debug );
      $sth = $dbh->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sth->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        my $updateRecord = $sth->fetchrow_array();
        $sth->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->finish: '. $sqlSTRING );

        if ( $updateRecord ) {
          $sqlSTRING = 'UPDATE `CLUSTERS` SET CLUSTER_NAME="'. $cluster->{clusterName} .'", CLUSTER_SERVERS="'. $cluster->{clusterServers} .'", ENV="'. $cluster->{environment} .'", UKEY="'. $cluster->{uKey} .'" WHERE CLUSTER_NAME="'. $cluster->{clusterName} .'"';
        } else {
          $sqlSTRING = 'INSERT INTO `CLUSTERS` SET CLUSTER_NAME="'. $cluster->{clusterName} .'", CLUSTER_SERVERS="'. $cluster->{clusterServers} .'", ENV="'. $cluster->{environment} .'", UKEY="'. $cluster->{uKey} .'"';
        }

        print "    $sqlSTRING\n" if ( $debug );
        $dbh->do ( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlSTRING );
      }
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  while ( my ($domain, $hash) = each( %adminServers ) ) {
    while ( my ($key, $oid) = each( %queueTable ) ) { _snmpwalk ( \$objectPlugins, \%infoQueues, $domain, $hash, $key, $oid, $callsystem, 3, $debug ); }
  }

  print $debug, "\n", Dumper ( %infoQueues ), "\n" if ( $debug > 3 );

  while ( my ($domain, $hash) = each( %infoQueues ) ) {
    print "\n$domain\n" if ( $debug );

    while ( my ($key, $queue) = each( %{$hash} ) ) {
      if ( $debug ) {
        print "\n";
        while ( my ($key, $value) = each( %{$queue} ) ) { print "$key = $value\n" }
      }

      my $sqlSTRING = 'SELECT count(*) FROM `QUEUES` WHERE ADMIN_NAME="'. $domain .'" AND QUEUE_OID="'. $queue->{queueOID} .'" AND QUEUE_NAME="'. $queue->{queueNAME} .'"';
      print "    $sqlSTRING\n" if ( $debug );
      $sth = $dbh->prepare( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->prepare: '. $sqlSTRING );
      $sth->execute() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->execute: '. $sqlSTRING ) if $rv;

      if ( $rv ) {
        my $updateRecord = $sth->fetchrow_array();
        $sth->finish() or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->finish: '. $sqlSTRING );

        if ( $updateRecord ) {
          $sqlSTRING = 'UPDATE `QUEUES` SET ADMIN_NAME="'. $domain .'", QUEUE_OID="'. $queue->{queueOID} .'", QUEUE_NAME="'. $queue->{queueNAME} .'", ENV="'. $queue->{environment} .'", UKEY="'. $queue->{uKey} .'" WHERE ADMIN_NAME="'. $domain .'" AND QUEUE_OID="'. $queue->{queueOID} .'" AND QUEUE_NAME="'. $queue->{queueNAME} .'"';
        } else {
          $sqlSTRING = 'INSERT INTO `QUEUES` SET ADMIN_NAME="'. $domain .'", QUEUE_OID="'. $queue->{queueOID} .'", QUEUE_NAME="'. $queue->{queueNAME} .'", ENV="'. $queue->{environment} .'", UKEY="'. $queue->{uKey} .'"';
        }

        print "    $sqlSTRING\n" if ( $debug );
        $dbh->do ( $sqlSTRING ) or $rv = _ErrorTrapDBI ( \$objectPlugins, 'Cannot dbh->do: '. $sqlSTRING );
      }
    }
  }

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  $dbh->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
$objectPlugins->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );
$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _snmpwalk {
  my ($asnmtapInherited, $infoHASH, $domain, $hash, $key, $oid, $call_system, $type, $debug) = @_;

  return unless ( $hash->{ activated } >= 1 );

  my ($hosts, $community, $version) = ( $hash->{hosts}, $hash->{community}, $hash->{version} );
  print "$domain, $hosts, $community, $version, $key, $oid, $type\n" if ( $debug > 4 );

  foreach my $hostPort ( split (',', $hosts) ) {
    my @lines;

    my $command = 'snmpwalk -v '. ( $version eq 'v1' ? '1' : ( $version eq 'v2' ? '2c' : '3' ) );
    $command .= ( $version eq 'v3' ) ? ' -u weblogic_snmp -l authPriv -a MD5 -A weblogic_snmp -x DES -X weblogic_snmp' : " -c $community". ( ( $type == 3 ) ? "\@$domain" : '' );
    $command .= " $hostPort $oid";

    if ( $callsystem ) {
      @lines = split ( /\n/, $$asnmtapInherited->pluginValue ('result') ) unless ( $$asnmtapInherited->call_system ( $command ) );
    } else {
      @lines = `$command`;
    }

    if ( ! @lines ) {
      $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => 'call system failed', error => $command }, $TYPE{APPEND} );
      next;
    }

    foreach my $line (@lines) {
      my ($identifier, $integer, $string) = ( $line =~ /^$oid((?:.\d+)+) = (?:INTEGER: (\d+)|STRING: "(.+)")$/ );

      if ( defined $identifier ) {
        if ( $debug > 4 ) {
          print $line;
          print "$identifier" if ( defined $identifier );
          print " - $integer\n\n" if ( defined $integer );
          print " - $string\n\n" if ( defined $string );
        }

        my $value = ( defined $integer ? $integer : ( defined $string ? $string : undef ) );

        unless ( $type == 3 ) {
          $$infoHASH { $domain } { $identifier } { $key } = $value;
        } else {
          $$infoHASH { $domain } { $identifier } { $key } = $identifier;
          $$infoHASH { $domain } { $identifier } { queueNAME } = $value;
        }

        $$infoHASH { $domain } { $identifier } { uKey } = $hash->{ uKey };
        $$infoHASH { $domain } { $identifier } { environment } = $hash->{ environment };
      } elsif ( $debug ) {
        $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "$command -> $line" }, $TYPE{APPEND} );
        print "$line\n\n";
        sleep 1;
      } else {
        $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, error => "$command -> $line" }, $TYPE{APPEND} );
      }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
