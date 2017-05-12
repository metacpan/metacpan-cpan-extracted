#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, generatePluginCrontabSchedulingReport.pl for ASNMTAP::Asnmtap::Applications::CGI
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use CGI;
use DBI;
use Time::Local;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :MODERATOR :REPORTS :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use lib ( "$CHARTDIRECTORLIB" );
use perlchartdir;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "generatePluginCrontabSchedulingReport.pl";
my $prgtext     = "Plugin Crontab Scheduling Report";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($rv, $dbh, $sth, $sql, $debugMessage, $errorMessage, $dbiErrorCode, $dbiErrorString);
my ($background, $forGround, $axisColor, $numberOfLabels, $chartTitle);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($localYear, $localMonth, $currentYear, $currentMonth, $currentDay, $currentHour, $currentMin) = ((localtime)[5], (localtime)[4], ((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3,2,1]);
my $currentSec = 0;

# URL Access Parameters
my $cgi = new CGI;
my $pagedir          = (defined $cgi->param('pagedir'))         ? $cgi->param('pagedir')         : '<NIHIL>';   $pagedir =~ s/\+/ /g;
my $pageset          = (defined $cgi->param('pageset'))         ? $cgi->param('pageset')         : 'moderator'; $pageset =~ s/\+/ /g;
my $debug            = (defined $cgi->param('debug'))           ? $cgi->param('debug')           : 'F';
my $sessionID        = (defined $cgi->param('CGISESSID'))       ? $cgi->param('CGISESSID')       : '';
my $CcatalogID       = (defined $cgi->param('catalogID'))       ? $cgi->param('catalogID')       : $CATALOGID;
my $CuKey            = (defined $cgi->param('uKey'))            ? $cgi->param('uKey')            : '';
my $width            = (defined $cgi->param('width'))           ? $cgi->param('width')           : 1000;
my $xOffset          = (defined $cgi->param('xOffset'))         ? $cgi->param('xOffset')         : 48;
my $yOffset          = (defined $cgi->param('yOffset'))         ? $cgi->param('yOffset')         : 42;
my $labelOffset      = (defined $cgi->param('labelOffset'))     ? $cgi->param('labelOffset')     : 18;
my $AreaBOffset      = (defined $cgi->param('AreaBOffset'))     ? $cgi->param('AreaBOffset')     : 78;
my $hightMin         = (defined $cgi->param('hightMin'))        ? $cgi->param('hightMin')        : 195;
my $pf               = (defined $cgi->param('pf'))              ? $cgi->param('pf')              : 'off';

# Chart Parameters
my $hight           = $yOffset + $AreaBOffset + 2;

# set: colors
if ($pf eq 'on') {
  $background = 0xF7F7F7;
  $forGround  = 0x000000;
  $axisColor  = 0x0C0C0C;
} else {
  $background = 0x000000;
  $forGround  = 0xF7F7F7;
  $axisColor  = 0x0000FF;
}

$chartTitle = "$prgtext for '$CuKey' from '$CcatalogID'";

my (%uKeys, @stepValue, @labels, @colorsCrontab, @colorsTimeslot, @dataPoints, @crontabStartDate, @crontabEndDate, @crontabEndTimeslot);

my $masterOrSlave = '<NIHIL>';
$masterOrSlave = 'master' if (-s "$APPLICATIONPATH/master/asnmtap-collector.sh");
$masterOrSlave = 'slave'  if (-s "$APPLICATIONPATH/slave/asnmtap-collector.sh");
$rv = ($masterOrSlave eq '<NIHIL>') ? 0 : 1;

if ( $rv ) {
  if ( $CuKey ) {
    $rv = 1;
  } else {
    $hight = $hightMin; $rv = 0; $errorMessage = "NO DATA FOR THIS PERIOD";
  }

  # open connection to database and query data
  $dbh = DBI->connect("DBI:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("Cannot connect to the database", $debug, '', "", '', "", '', 0, '', $sessionID) if ( $rv );

  if ( $dbh and $rv ) {
    my ($startDate, $startTime, $endDate, $endTime, $status, $timeslot);
    $sql = "select $SERVERTABLCRONTABS.collectorDaemon, $SERVERTABLCRONTABS.uKey, $SERVERTABLCRONTABS.lineNumber, $SERVERTABLCRONTABS.minute, $SERVERTABLCRONTABS.hour, $SERVERTABLCRONTABS.dayOfTheMonth, $SERVERTABLCRONTABS.monthOfTheYear, $SERVERTABLCRONTABS.dayOfTheWeek, $SERVERTABLCRONTABS.noOffline from $SERVERTABLCRONTABS, $SERVERTABLPLUGINS where $SERVERTABLCRONTABS.catalogID = '$CcatalogID' and $SERVERTABLCRONTABS.uKey = '$CuKey' and $SERVERTABLCRONTABS.activated = 1 and $SERVERTABLCRONTABS.catalogID = $SERVERTABLPLUGINS.catalogID and $SERVERTABLCRONTABS.uKey = $SERVERTABLPLUGINS.uKey and $SERVERTABLPLUGINS.activated = 1 and $SERVERTABLPLUGINS.production = 1 order by $SERVERTABLCRONTABS.catalogID, $SERVERTABLCRONTABS.collectorDaemon, $SERVERTABLCRONTABS.uKey, $SERVERTABLCRONTABS.lineNumber";
    ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $hight, $numberOfLabels) = get_sql_crontab_scheduling_report_data ($dbh, $sql, $rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $sessionID, $hight, $hightMin, \%uKeys, \@labels, \@stepValue, $CcatalogID, undef, $debug);
    $dbh->disconnect or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', 0, '', $sessionID) if (defined $dbh) ;
  }
  
  if ( $rv ) {
    my $restPreviousTimeslot = 0;
    my $stepValue = $stepValue[0] * 60;
    my $restCurrentTimeslot = $stepValue;
    my $applicationTitle = $labels[0];
    $chartTitle = "$prgtext for '$applicationTitle' from '$CcatalogID'";
    my ($mon, $mday) = (1, 1);
    @labels = ();
    my @dayOfTheWeek = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

    FORDAYOFTHEWEEK: for (my $wday = 0; $wday < 7; $wday++) {
      my $dataPointOffset = ($wday * 24);

      FORHOUR: for (my $hour = 0; $hour < 24; $hour++) {
        my $dataPoint = $dataPointOffset + $hour;

        my $label = sprintf ("%s-%02d", $dayOfTheWeek[$wday], $hour);
        push (@labels, $label);
		
        FORMIN: for (my $min = 0; $min < 60; $min++) {
          my $currentDate = timelocal(0, $min, 0, 1, 0, 105);

          UKEY: foreach my $uKey (keys %uKeys) {
            my $collectorDaemon = $uKeys{$uKey}->{collectorDaemon} if ($uKeys{$uKey}->{collectorDaemon} !~ /\|/);

            unless ( defined $collectorDaemon ) {
              $hight = $hightMin; $rv = 0; $errorMessage = "'$uKey' from '$CcatalogID' into more then one Collector Daemon available: '". $uKeys{$uKey}->{collectorDaemon} ."'";
              last FORHOUR;
            } else {
              my $noOFFLINE = $uKeys{$uKey}->{noOffline} if ($uKeys{$uKey}->{noOffline} !~ /\|/);

              unless ( defined $noOFFLINE ) {
                $hight = $hightMin; $rv = 0; $errorMessage = "For '$uKey' from '$CcatalogID' is there more then one noOffline type available: '". $uKeys{$uKey}->{noOffline} ."'";
                last FORHOUR;
              } else {
                my $insertStatus;

                foreach my $lineNumber (keys %{$uKeys{$uKey}{lineNumbers}}) {
                  my $tmin  = $uKeys{$uKey}->{lineNumbers}->{$lineNumber}->{minute};
                  my $thour = $uKeys{$uKey}->{lineNumbers}->{$lineNumber}->{hour};
                  my $tmday = $uKeys{$uKey}->{lineNumbers}->{$lineNumber}->{dayOfTheMonth};
                  my $tmon  = $uKeys{$uKey}->{lineNumbers}->{$lineNumber}->{monthOfTheYear};
                  my $twday = $uKeys{$uKey}->{lineNumbers}->{$lineNumber}->{dayOfTheWeek};

                  my ($doIt, $doOffline) = set_doIt_and_doOffline ($min, $hour, $mday, $mon, $wday, $tmin, $thour, $tmday, $tmon, $twday);

                  if ($doIt || $doOffline) {
                    if ($doIt) {
                      $insertStatus = $ERRORS{UNKNOWN};
                    } elsif ($doOffline) {
                      if ($noOFFLINE) {
                       if ($noOFFLINE eq "noOFFLINE") {
                          $insertStatus = $ERRORS{DEPENDENT} unless ( defined $insertStatus );
                        } elsif ($noOFFLINE eq 'multiOFFLINE') {
                          $insertStatus = $ERRORS{OFFLINE} unless ( defined $insertStatus );
                        } elsif ($noOFFLINE eq 'noTEST') {
                          $insertStatus = $ERRORS{'NO TEST'} unless ( defined $insertStatus );
                        }
                      } else {
                        $insertStatus = $ERRORS{OFFLINE} unless ( defined $insertStatus );
                      }
                    }
                  }
                }

                if (defined $insertStatus) {
                  if ($restPreviousTimeslot) {
                    push (@colorsCrontab,      $COLORSRRD{$STATE{$insertStatus}});
                    push (@colorsTimeslot,     $COLORSRRD{'IN PROGRESS'});
                    push (@dataPoints,         $dataPoint);
                    push (@crontabStartDate,   perlchartdir::chartTime2($currentDate));
                    push (@crontabEndDate,     perlchartdir::chartTime2($currentDate));
                    push (@crontabEndTimeslot, perlchartdir::chartTime2($currentDate - $restPreviousTimeslot));
                    $restPreviousTimeslot = 0;
                    $restCurrentTimeslot  = $stepValue;
                  }

                  my $endpointCurrentTimeslot = (($min * 60) + $stepValue);

                  if ($endpointCurrentTimeslot > 3600) {
                    $restPreviousTimeslot = $endpointCurrentTimeslot - 3600;
                    $restCurrentTimeslot  = $stepValue - $restPreviousTimeslot;
                  }

                  # the color for each crontab bar
                  push (@colorsCrontab,      $COLORSRRD{$STATE{$insertStatus}});

                  # the color for each timeslot bar
                  push (@colorsTimeslot,     $COLORSRRD{'IN PROGRESS'});

                  # the data points for each test result matching the corresponding label
                  push (@dataPoints,         $dataPoint);

                  # the timeslot start dates and end dates for the tasks
                  push (@crontabStartDate,   perlchartdir::chartTime2($currentDate));
                  push (@crontabEndDate,     perlchartdir::chartTime2($currentDate + 60));
                  push (@crontabEndTimeslot, perlchartdir::chartTime2($currentDate + $restCurrentTimeslot));
                }
              }
            }
          }
        }
      }
    }
  }
} else {
  $hight = $hightMin; $errorMessage = "PROBLEM REGARDING FINDING MASTER OR SLAVE";
}

# exit;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# calculatie hight
$hight += ($labelOffset * 24 * 7);
$hight = $hightMin if ($hight < $hightMin);

# Create XYChart object with: width, hight, backgroundcolor, bordercolor, pxp-3d borden
my $c = new XYChart($width, $hight, $background, $background, 1);

# Add a title box to the chart using 10 pts Arial Bold Italic font.
$chartTitle = "Error for '$chartTitle'" unless ( defined $chartTitle and $rv );
$c->addText($width/2, 14, $chartTitle, "arialbi.ttf", 10, $forGround, 5, 0);

# Add debugMessage and errorMessage
$c->addText($width - 18, $hight - 33, $debugMessage, "arial.ttf", 8, $forGround, 6, 0) if ( defined $debugMessage );
$c->addText($width/2, (($hight - $yOffset - $AreaBOffset)/2) + $yOffset + 16, $errorMessage, "arial.ttf", 12, 0xFF0000, 5, 0) if ( defined $errorMessage );
$c->addText($width/2, (($hight - $yOffset - $AreaBOffset)/2) + $yOffset - 16, $dbiErrorCode, "arial.ttf", 10, 0xFF0000, 5, 0) if ( defined $dbiErrorCode );
$c->addText($width/2, (($hight - $yOffset - $AreaBOffset)/2) + $yOffset + 48, $dbiErrorString, "arial.ttf", 10, 0xFF0000, 5, 0) if ( defined $dbiErrorString );

# Add a custom CDML text at the bottom right of the plot area as the logo
$c->addText($width - 3, 92, $APPLICATION . " @ " . $BUSINESS, "arial.ttf", 8, $forGround, 6, 270);
$c->addText($width - 18, $hight - 18, $DEPARTMENT . " @ " . $BUSINESS . ", created on: " . scalar(localtime()) . ".", "arial.ttf", 8, $forGround, 6, 0);

unless ( defined $errorMessage or defined $dbiErrorCode or defined $dbiErrorString ) {
  # Set the plotarea at (xOffset, yOffset) and of size ($width - $xOffset - 21) x ($hight - $AreaBOffset) pixels, with white background. Set border and grid line colors to 0xa08040.
  $c->setPlotArea($xOffset, $yOffset, $width - $xOffset - 21, $hight - $AreaBOffset, 0xffffff, 0xeeeeee, $axisColor, 0xCCCCCC, 0xCCCCCC)->setGridWidth(1, 1, 1, 1);

  # swap the x and y axes to create a horziontal box-whisker chart
  $c->swapXY();

  # Set the axes width to 1 pixels
  $c->xAxis()->setWidth(1);
  $c->yAxis()->setWidth(1);

  # Set the axis colors
  $c->xAxis()->setColors($axisColor);
  $c->yAxis()->setColors($axisColor);

  # Set the y-axis scale to be hh:nn
  my $lowerLimit = timelocal(0, 0, 0, 1, 0, 105);
  my $upperLimit = timelocal(0, 0, 1, 1, 0, 105);
  my @dateScalelabels = ('0'..'59', '0');
  $c->yAxis()->setDateScale2(perlchartdir::chartTime2($lowerLimit), perlchartdir::chartTime2($upperLimit), \@dateScalelabels);
  $c->yAxis()->setLabelStyle("tahoma.ttf", 8, $forGround);

  # Set the y-axis to shown on the top (right + swapXY = top)
  $c->setYAxisOnRight();

  # Set the labels on the x axis
  $c->xAxis()->setLabels(\@labels);
  $c->xAxis()->setLabelStyle("tahoma.ttf", 8, $forGround);

  # Reverse the x-axis scale so that it points downwards.
  $c->xAxis()->setReverse();

  # Set the horizontal ticks and grid lines to be between the bars
  $c->xAxis()->setTickOffset(0.5);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Add a box-whisker layer to represent the timeslot schedule date
  my $crontabLayer = $c->addBoxWhiskerLayer2(\@crontabStartDate, \@crontabEndDate, undef, undef, undef, \@colorsCrontab, 0);
  $crontabLayer->setXData(\@dataPoints);

  # Set the bar height to 10 pixels so they will not block the bottom bar
  $crontabLayer->setDataWidth(10);
  
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  # Add a box-whisker layer to represent the crontab timeslot schedule date
  my $timeslotLayer = $c->addBoxWhiskerLayer2(\@crontabEndDate, \@crontabEndTimeslot, undef, undef, undef, \@colorsTimeslot, 0);
  $timeslotLayer->setXData(\@dataPoints);

  # Set the bar height to 4 pixels so they will not block the bottom bar
  $timeslotLayer->setDataWidth(4);

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  
  if ($pf eq 'on') {
    $c->addLegend(2, $hight - 32, 0, "arial.ttf", 8)->setBackground($perlchartdir::Transparent);
  } else {
    $c->addLegend(2, $hight - 32, 0, "arial.ttf", 8)->setFontColor($forGround);
  }
}

# Output the chart
binmode(STDOUT);
print "Content-type: image/png\n\n";
print $c->makeChart2($perlchartdir::PNG);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

