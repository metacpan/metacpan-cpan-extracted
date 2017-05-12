#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, purge_table.pl for ASNMTAP
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Time v3.002.003;
use ASNMTAP::Time qw(&get_epoch &get_year &get_month &get_day);

use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS &init_email_report &send_email_report);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectASNMTAP = ASNMTAP::Asnmtap::Applications->new (
  _programName        => 'purge_table.pl',
  _programDescription => 'Purge table',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-H|--host <HOST> [-P|--port <PORT>] -D|--database=<database> -T|--table=<table> [-A|--ago=<ago by STRING>] -u|--username|--loginname
 <USERNAME> -p|--password|--passwd <PASSWORD>',
  _programHelpPrefix  => "-H, --host=<HOST>
   hostname or ip address
-P, --port=<PORT> (default: 3306)
-D, --database=<database>
-T, --table=<table>
-A, --ago=<ago by STRING>
-u, --username/--loginname=<USERNAME>
-p, --password/--passwd=<PASSWORD>",
  _programGetOptions  => ['host|H=s', 'port|P:i', 'database|D=s', 'table|T=s', 'ago|A:s', 'username|u|loginname=s', 'password|p|passwd=s'],
  _debug              => 0);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $host     = $objectASNMTAP->getOptionsArgv ('host');
$objectASNMTAP->printUsage ('Missing command line argument host') unless ( defined $host );

my $port     = $objectASNMTAP->getOptionsArgv ('port') ? $objectASNMTAP->getOptionsArgv ('port') : 3306;
$port = ( $port =~ m/^([1-9]?(?:\d*))$/ ) ? $1 : undef;
$objectASNMTAP->printUsage ('Invalid port: '. $port) unless (defined $port);

my $database = $objectASNMTAP->getOptionsArgv ('database');
$objectASNMTAP->printUsage ('Missing command line argument database') unless ( defined $database );

my $table    = $objectASNMTAP->getOptionsArgv ('table');
$objectASNMTAP->printUsage ('Missing command line argument table') unless ( defined $table );

my $username = $objectASNMTAP->getOptionsArgv ('username');
$objectASNMTAP->printUsage ('Missing command line argument username') unless ( defined $username );

my $password = $objectASNMTAP->getOptionsArgv ('password');
$objectASNMTAP->printUsage ('Missing command line argument password') unless ( defined $password );

my $ago      = $objectASNMTAP->getOptionsArgv ('ago');
$ago = '-1 month' unless ( defined $ago );

my $debug    = $objectASNMTAP->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($emailReport, $rvOpen) = init_email_report (*EMAILREPORT, "purgeEmailReport.txt", $debug);

unless ( $rvOpen ) {
  print "Can't create $emailReport\n";
  exit; 
}

purgeTables ( $ago );
my ($rc) = send_email_report (*EMAILREPORT, $emailReport, $rvOpen, 'Purge table', 'F');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub purgeTables {
  my ($tableAgo) =  @_;

  print EMAILREPORT "\nPurge '$table' table:\n--------------------------------------------------\n" unless ( $debug );

  # Init parameters
  my ($rv, $dbh, $sth, $sql, $year, $month, $day, $purgetime);

  $rv  = 1;
  $dbh = DBI->connect("dbi:mysql:$database:$host:$port", "$username", "$password" ) or $rv = _ErrorTrapDBI("Cannot connect to the database", $debug);

  if ($dbh and $rv) {
    $year  = get_year  ($tableAgo);
    $month = get_month ($tableAgo);
    $day   = get_day   ($tableAgo);

    $purgetime = timelocal ( 0, 0, 0, $day, ($month-1), ($year-1900) );

    if ($debug) {
      print "\nTable: '$table', Year: '$year', Month: '$month', Day: '$day', Purgetime: '$purgetime', Date: " .scalar(localtime($purgetime)). "\n<$sql>\n";
    } else {
      print EMAILREPORT "\nTable: '$table', Year: '$year', Month: '$month', Day: '$day', Purgetime: '$purgetime'\n";
    }

    $sql = 'DELETE FROM `' .$table. '` WHERE archivetime < "' .$purgetime. '"';
    print "$sql\n" if ($debug);
    $dbh->do( $sql ) or $rv = _ErrorTrapDBI("Cannot dbh->do: $sql", $debug) unless ( $debug );

    $dbh->disconnect or $rv = _ErrorTrapDBI("Sorry, the database was unable to add your entry.", $debug);
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub _ErrorTrapDBI {
  my ($error_message, $debug) = @_;

  print EMAILREPORT "   DBI Error:\n", $error_message, "\nERROR: $DBI::err ($DBI::errstr)\n";
  return 0;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
