#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_file-counter.pl
# ----------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Plugins v3.002.003;
use ASNMTAP::Asnmtap::Plugins qw(:PLUGINS);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use constant DAY => 86400;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_file-counter.pl',
  _programDescription => 'File Counter',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '-p|--parameters <directory> -m|--message <plugin massage> -w|--wNumber INTEGER -c|--cNumber INTEGER [-W|--wDays INTEGER] [-C|--cDays INTEGER]',
  _programHelpPrefix  => '-p, --parameters=<directory>
   <directory> for which the number of files need to be counted  
-m, --message=<plugin massage>
    <plugin massage> is the name displayed into the monitoring tool
-w, --wNumber=INTEGER
   number of counted files above which a WARNING status will result 
-c, --cNumber=INTEGER
   number of counted files abowe which a CRITICAL status will result
-W, --wDays=INTEGER
   days of oldest file above which a WARNING status will result
-C, --cDays=INTEGER
   days of oldest file above which a CRITICAL status will result',
  _programGetOptions  => ['parameters|p=s', 'message|m=s', 'wNumber|w=s', 'cNumber|c=s', 'wDays|W:f', 'cDays|C:f', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 10,
  _debug              => 0);

my $parameters = $objectPlugins->getOptionsArgv ('parameters');
$objectPlugins->printUsage ('Missing command line argument parameters') unless ( defined $parameters);

my $tMessage = $objectPlugins->getOptionsArgv ('message');
$objectPlugins->printUsage ('Missing command line argument message') unless ( defined $tMessage);

my $wNumber = $objectPlugins->getOptionsArgv ('wNumber');
$objectPlugins->printUsage ('Missing command line argument wNumber') unless ( defined $wNumber);

my $cNumber = $objectPlugins->getOptionsArgv ('cNumber');
$objectPlugins->printUsage ('Missing command line argument cNumber') unless ( defined $cNumber);

my $wDays = $objectPlugins->getOptionsArgv ('wDays');
my $cDays = $objectPlugins->getOptionsArgv ('cDays');

my $debug = $objectPlugins->getOptionsValue ('debug');

my $message = $objectPlugins->pluginValue ('message');
$message =~ s/File Counter/$tMessage/g;
$objectPlugins->pluginValue ( message => $message );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $wOffset = DAY * $wDays if (defined $wDays);
my $cOffset = DAY * $cDays if (defined $cDays);

my ($nFiles, $cTime, $cFiles, $wFiles) = (0, time(), 0 , 0);

my @files = glob ("$parameters/*");
use Fcntl ':mode';

foreach (@files){
  my ($mode, $ctime) = ( stat($_) )[2,10];
  my $dTime = $cTime - $ctime;

  if ( S_ISREG($mode) ) {
    $nFiles++;
    $wFiles++ if ( defined $wOffset and $dTime > $wOffset );
    $cFiles++ if ( defined $cOffset and $dTime > $cOffset );
  }
};

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( $nFiles ) {
  $objectPlugins->appendPerformanceData ( "'". $parameters ."'=". $nFiles .';'. $wNumber .';'. $cNumber .';0;' );

  if ( $nFiles > $cNumber ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "$nFiles > $cNumber files into $parameters" }, $TYPE{APPEND} );
  } elsif ($nFiles > $wNumber) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING}, alert => "$nFiles > $wNumber files into $parameters" }, $TYPE{APPEND} );
  } else {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{OK}, alert => "$nFiles files into $parameters" }, $TYPE{APPEND} );
  } 
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "$wFiles older then $wDays days" }, $TYPE{COMMA_APPEND} ) if ( defined $wOffset and $wFiles );
$objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, alert => "$cFiles older then $cDays days" }, $TYPE{COMMA_APPEND} ) if ( defined $wOffset and $cFiles );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

