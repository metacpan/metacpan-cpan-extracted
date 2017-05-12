#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_snmptt_traps.pl drop-in replacement for NagTrap
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins::Nagios v3.002.003;
use ASNMTAP::Asnmtap::Plugins::Nagios qw(:NAGIOS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectNagios = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_snmptt_traps.pl',
  _programDescription => 'Nagios SNMPTT Traps Database',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--forceTrapread <F(alse)|T(rue)>] [-F|--FQDN <F(alse)|T(rue)>] [-o|--trapOIDs <trapoid[|<trapoid>]>] [-s|--server <hostname>] [--database=<database>]',
  _programHelpPrefix  => "--forceTrapread=<F(alse)|T(rue)>
-F, --FQDN=<F(alse)|T(rue)>
-o, --trapOIDs=<SNMP trapoid>[|<SNMP trapoid>]
-s, --server=<hostname> (default: localhost)
--database=<database> (default: odbc)",
  _programGetOptions  => ['host|H:s', 'forceTrapread:s', 'FQDN|F:s', 'trapOIDs|o:s', 'server|s:s', 'port|P:i', 'database:s', 'username|u|loginname:s', 'password|p|passwd:s', 'environment|e:s'],
  _timeout            => 30,
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $hostname = $objectNagios->getOptionsArgv ('host') ? $objectNagios->getOptionsArgv ('host') : undef;
$objectNagios->printUsage ('Missing command line argument hostname') unless (defined $hostname);

my $forceTrapread = $objectNagios->getOptionsArgv ('forceTrapread') ? $objectNagios->getOptionsArgv ('forceTrapread') : 'F';
$objectNagios->printUsage ('Invalid parameter forceTrapread') unless ($forceTrapread =~ /^[FT]$/);

my $FQDN     = $objectNagios->getOptionsArgv ('FQDN') ? $objectNagios->getOptionsArgv ('FQDN') : 'T';
$objectNagios->printUsage ('Invalid parameter FQDN') unless ($FQDN =~ /^[FT]$/);

my $trapOIDs = $objectNagios->getOptionsArgv ('trapOIDs') ? $objectNagios->getOptionsArgv ('trapOIDs') : undef;

my $serverDB = $objectNagios->getOptionsArgv ('server')   ? $objectNagios->getOptionsArgv ('server')   : 'localhost';
my $port     = $objectNagios->getOptionsArgv ('port')     ? $objectNagios->getOptionsArgv ('port')     : 3306;
my $database = $objectNagios->getOptionsArgv ('database') ? $objectNagios->getOptionsArgv ('database') : 'snmptt';
my $username = $objectNagios->getOptionsArgv ('username') ? $objectNagios->getOptionsArgv ('username') : 'asnmtap';
my $password = $objectNagios->getOptionsArgv ('password') ? $objectNagios->getOptionsArgv ('password') : 'asnmtap';

my $debug    = $objectNagios->getOptionsValue ('debug');
my $onDemand = $objectNagios->getOptionsValue ('onDemand');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $returnCode = $ERRORS{UNKNOWN};
my $alert = 'UNKNOWN:';

my ( $dbh, $sth, $prepareString );

$dbh = DBI->connect ("DBI:mysql:$database:$serverDB:$port", "$username", "$password") or _ErrorTrapDBI ( 'Could not connect to MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );

if ( $dbh ) {
  my $hostnameString = ($FQDN eq 'T' ? "hostname = '$hostname'" : "hostname regexp '^$hostname.'");

  my $trapOIDsString = '';

  if ( defined $trapOIDs ) {
    my $teller = 0;
    my @trapOIDsString = split (/\|/, $trapOIDs);
    foreach (@trapOIDsString) { $trapOIDsString[$teller++] = "trapoid = '$_'"; }
    $trapOIDsString = ' and ( '. join (' or ', @trapOIDsString) .' )' if ( @trapOIDsString );
  }

  if (! $onDemand) {
    my $rv = 1;

    my $sqlINSERT = "REPLACE INTO `snmptt_archive` SELECT * FROM `snmptt` WHERE trapread = '1' and $hostnameString $trapOIDsString";
    print "    $sqlINSERT\n" if ( $debug );
    $dbh->do ( $sqlINSERT ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlINSERT );

    if ( $rv ) {
      my $sqlDELETE = "DELETE FROM `snmptt` WHERE trapread = '1' and $hostnameString $trapOIDsString";
      print "    $sqlDELETE\n" if ( $debug );
      $dbh->do( $sqlDELETE ) or $rv = _ErrorTrapDBI ( \$objectNagios,  'Cannot dbh->do: '. $sqlDELETE );
    }
  }

  $prepareString = "select count(id) from snmptt where $hostnameString $trapOIDsString";
  print "    $prepareString\n" if ( $debug );
  $sth = $dbh->prepare($prepareString) or _ErrorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
  $sth->execute or _ErrorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );
  my $count = $sth->fetchrow_array();
  $sth->finish() or _ErrorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );

  $prepareString = "select count(id) from snmptt where trapread = '0' and $hostnameString $trapOIDsString and (severity = 'CRITICAL' or severity = 'MAJOR' or severity = 'SEVERE')";
  print "    $prepareString\n" if ( $debug );
  $sth = $dbh->prepare($prepareString) or _ErrorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
  $sth->execute or _ErrorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );
  my $countCRITICAL = $sth->fetchrow_array();
  $sth->finish() or _ErrorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );

  if ( $countCRITICAL > 0 ) {
    $alert = "CRITICAL: $countCRITICAL Critical Traps for $hostname. $count Traps in Database";
    $returnCode = $ERRORS{CRITICAL};
  } else {
    $prepareString = "select count(id) from snmptt where trapread = '0' and $hostnameString $trapOIDsString and (severity = 'MINOR' or severity = 'WARNING')";
    print "    $prepareString\n" if ( $debug );
    $sth = $dbh->prepare($prepareString) or _ErrorTrapDBI ( 'dbh->prepare '. $prepareString, "$DBI::err ($DBI::errstr)" );
    $sth->execute or _ErrorTrapDBI ( 'sth->execute '. $prepareString, "$DBI::err ($DBI::errstr)" );
    my $countWARNING = $sth->fetchrow_array();
    $sth->finish() or _ErrorTrapDBI ( 'sth->finish '. $prepareString, "$DBI::err ($DBI::errstr)" );

    if ( $countWARNING > 0 ) {
      $alert = "WARNING: $countWARNING Warning Traps for $hostname. $count Traps in Database";
      $returnCode = $ERRORS{WARNING};
    } else {
      $alert = "OK: No Warning or Critical Traps for $hostname. $count Traps in Database";
      $returnCode = $ERRORS{OK};

      if ( $forceTrapread eq 'T' ) {
        my $sqlUPDATE = "UPDATE `snmptt` SET trapread = '1' WHERE trapread = '0' and $hostnameString $trapOIDsString";
        print "    $sqlUPDATE\n" if ( $debug );
        $dbh->do ( $sqlUPDATE ) or _ErrorTrapDBI ( 'dbh->do '. $prepareString, "$DBI::err ($DBI::errstr)" ) if (! $onDemand);
      }
    }
  }

  $dbh->disconnect or _ErrorTrapDBI ( 'Could not disconnect from MySQL server '. $serverDB, "$DBI::err ($DBI::errstr)" );
}

$objectNagios->pluginValues ( { stateValue => $returnCode, alert => $alert }, $TYPE{APPEND} );
$objectNagios->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($asnmtapInherited, $error_message) = @_;

  $$asnmtapInherited->pluginValues ( { stateValue => $ERRORS{UNKNOWN}, alert => $error_message, error => "$DBI::err ($DBI::errstr)" }, $TYPE{APPEND} );
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
