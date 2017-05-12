#!/usr/bin/env perl
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 by Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, check_fs-stat.pl
# ----------------------------------------------------------------------------------------------------------
# ./check_fs-stat.pl --message=DisplayCT --directory=/opt/asnmtap/pid/ --wildcard=DisplayCT-*.pid --type=F --files=m --wAge=120 --cAge=300
# ./check_fs-stat.pl --message=CollectorCT --directory=/opt/asnmtap/pid/ --wildcard=CollectorCT-*.pid --type=F --files=n --wAge=120 --cAge=300
# ./check_fs-stat.pl --message='rsync mirror distributed' --directory=/opt/asnmtap/pid/ --wildcard=rsync-mirror-distributed-*.conf.pid --type=F --files=x --wAge=120 --cAge=300
# ./check_fs-stat.pl --message='results directories' --directory=/opt/asnmtap/results --type=D --wAge=300 --cAge=900 --dirs=y
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

my $objectPlugins = ASNMTAP::Asnmtap::Plugins->new (
  _programName        => 'check_fs-stat.pl',
  _programDescription => 'Filesystem Stat',
  _programVersion     => '3.002.003',
  _programUsagePrefix => '[--message <plugin massage>] --directory <directory> [--type <F|D|B>] [--dirs <INTEGER>] [--files <INTEGER>] [--wildcard <wildcard>] --wAge INTEGER --cAge INTEGER',
  _programHelpPrefix  => '--message=<plugin massage>
    <plugin massage> is the name displayed into the monitoring tool
--directory=<directory>
    <directory> for which the action need to be taken
--type <F|D|B>
    <F|D|B>=F(ile), D(irectory) or B(oth)
--dirs=INTEGER
    number of expected dirs, if not equal CRITICAL status will result
--files=INTEGER
    number of expected files, if not equal CRITICAL status will result
--wildcard <wildcard>
    <wildcard> for a file
--wAge=INTEGER
    age seconds for a files above which a WARNING status will result 
--cAge=INTEGER
    age seconds for a files above which a CRITICAL status will result',
  _programGetOptions  => ['message:s', 'directory=s', 'type:s', 'dirs:i', 'files:i', 'wildcard:s', 'cAge=i', 'wAge=i', 'environment|e:s', 'timeout|t:i', 'trendline|T:i'],
  _timeout            => 10,
  _debug              => 0);

my $environment = $objectPlugins->getOptionsArgv ('environment');

my $directory = $objectPlugins->getOptionsArgv ('directory');
$objectPlugins->printUsage ('Missing command line argument directory') unless ( defined $directory );

my $type = $objectPlugins->getOptionsArgv ('type');

if ( defined $type ) {
  $objectPlugins->printUsage ('Missing command line argument message') unless ( $type =~ /^[FDB]$/ );
} else {
  $type = 'B';
}

my $dirs = $objectPlugins->getOptionsArgv ('dirs');

my $files = $objectPlugins->getOptionsArgv ('files');

my $wildcard = $objectPlugins->getOptionsArgv ('wildcard');
$wildcard = '*' unless ( defined $wildcard );

my $tMessage = $objectPlugins->getOptionsArgv ('message');

if ( defined $tMessage ) {
  my $message = $objectPlugins->pluginValue ('message');
  $message =~ s/Filesystem Stat/$tMessage/g;
  $objectPlugins->pluginValue ( message => $message );
}

my $wAge = $objectPlugins->getOptionsArgv ('wAge');
$objectPlugins->printUsage ('Missing command line argument wAge') unless ( defined $wAge );

my $cAge = $objectPlugins->getOptionsArgv ('cAge');
$objectPlugins->printUsage ('Missing command line argument cAge') unless ( defined $cAge );

$objectPlugins->printUsage ("cAge '$cAge' must be greather then wAge '$wAge'" ) unless ( $cAge > $wAge );

my $debug = $objectPlugins->getOptionsValue ('debug');

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Start plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $now = time();
use Fcntl ':mode';

my @files = glob ("$directory/$wildcard");

my ($nDirectories, $wDirectories, $cDirectories, $nFiles, $wFiles, $cFiles) = (0, 0, 0, 0, 0, 0);

foreach (@files){
  my ($mode, $mtime) = ( stat($_) )[2, 10];
  my $dTime = ( defined $mtime ) ? $now - $mtime : 0;

  if ( $type =~ /^[FB]$/ and S_ISREG($mode) ) {
    $nFiles++;
    $wFiles++ if ( $dTime > $wAge );
    $cFiles++ if ( $dTime > $cAge );
    print "file     : $_, $now, $mtime, $dTime, $mode, $nFiles, $wFiles, $cFiles\n" if ( $debug );
  } elsif ( $type =~ /^[DB]$/ and S_ISDIR($mode) ) {
    $nDirectories++;
    $wDirectories++ if ( $dTime > $wAge );
    $cDirectories++ if ( $dTime > $cAge );
    print "directory: $_, $now, $mtime, $dTime, $mode, $nDirectories, $wDirectories, $cDirectories\n" if ( $debug );
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if ( $type =~ /^[BD]$/ ) {
  if ( $cDirectories || $cFiles ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "Directory Aging: $cDirectories/$nDirectories" }, $TYPE{APPEND} );
  } elsif ( $wDirectories || $wFiles ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING}, error => "Directory Aging: $wDirectories/$nDirectories" }, $TYPE{APPEND} );
  } else {
    $objectPlugins->pluginValue ( stateValue => $ERRORS{OK} );
  }

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "Expected Directories: $nDirectories/$dirs" }, $TYPE{APPEND} ) if ( defined $dirs and $nDirectories != $dirs );
}

if ( $type =~ /^[BF]$/ ) {
  if ( $cDirectories || $cFiles ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "File Aging: $cFiles/$nFiles" }, $TYPE{APPEND} );
  } elsif ( $wDirectories || $wFiles ) {
    $objectPlugins->pluginValues ( { stateValue => $ERRORS{WARNING}, error => "File Aging: $wFiles/$nFiles" }, $TYPE{APPEND} );
  } else {
    $objectPlugins->pluginValue ( stateValue => $ERRORS{OK} );
  }

  $objectPlugins->pluginValues ( { stateValue => $ERRORS{CRITICAL}, error => "Expected Files: $nFiles/$files" }, $TYPE{APPEND} ) if ( defined $files and $nFiles != $files );
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# End plugin  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$objectPlugins->exit (7);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

