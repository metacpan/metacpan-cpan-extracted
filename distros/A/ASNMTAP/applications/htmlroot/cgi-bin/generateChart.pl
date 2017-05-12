#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, generateChart.pl for ASNMTAP::Asnmtap::Applications::CGI
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
use Date::Calc qw(Add_Delta_Days Date_to_Text_Long Delta_Days);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications::CGI v3.002.003;
use ASNMTAP::Asnmtap::Applications::CGI qw(:APPLICATIONS :CGI :REPORTS :DBREADONLY :DBTABLES);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use lib ( "$CHARTDIRECTORLIB" );
use perlchartdir;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "generateChart.pl";
my $prgtext     = "Generate Chart";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($rv, $dbh, $sth, $sql, $sqlPeriode, $debugMessage, $errorMessage, $dbiErrorCode, $dbiErrorString);
my ($background, $forGround, $axisColor, $numberOfDays, $numberOfLabels, $dummy, $trendvalue, $chartTitle);
my ($endDateIN, $i, $j, $yearFrom, $monthFrom, $dayFrom, $yearTo, $monthTo, $dayTo, $goodDate, $slaWindow);

my (@avg1, @avg2, @avg3, @data, @dataOK, @dataWarning, @dataCritical, @dataUnknown, @dataNoTest, @dataOffline);
my (@icons, @labels, @labels1, @labels2, @labels3, $applicationTitle1, $applicationTitle2, $applicationTitle3);

my ($currentYear, $currentMonth, $currentDay) = (((localtime)[5] + 1900), ((localtime)[4] + 1), (localtime)[3]);

$applicationTitle1 = $applicationTitle2 = $applicationTitle3 = '<NIHIL>';
my @arrMonths      = qw(January Februari March April May June July August September October November December);

# Chart Parameters
my $width		= 1000; 	 # graph width
my $hight       = 380;       # graph height
my $xOffset     = 74;        # x offset grapharea
my $yOffset     = 28;        # y offset grapharea
my $AreaBOffset = 78;
my $trendZone   = 0xFFFF99;

# URL Access Parameters
my $cgi = new CGI;
my $pagedir      = (defined $cgi->param('pagedir'))      ? $cgi->param('pagedir')      : 'index';    $pagedir =~ s/\+/ /g;
my $pageset      = (defined $cgi->param('pageset'))      ? $cgi->param('pageset')      : 'index-cv'; $pageset =~ s/\+/ /g;
my $debug        = (defined $cgi->param('debug'))        ? $cgi->param('debug')        : 'F';
my $sessionID    = (defined $cgi->param('CGISESSID'))    ? $cgi->param('CGISESSID')    : '';
my $selChart     = (defined $cgi->param('chart'))        ? $cgi->param('chart')        : 'ErrorDetails';
my $CcatalogID   = (defined $cgi->param('catalogID'))    ? $cgi->param('catalogID')    : $CATALOGID;
my $uKey1        = (defined $cgi->param('uKey1'))        ? $cgi->param('uKey1')        : 'none';
my $uKey2        = (defined $cgi->param('uKey2'))        ? $cgi->param('uKey2')        : 'none';
my $uKey3        = (defined $cgi->param('uKey3'))        ? $cgi->param('uKey3')        : 'none';
my $startDateIN  = (defined $cgi->param('startDate'))    ? $cgi->param('startDate')    : 'none';
my $inputType    = (defined $cgi->param('inputType'))    ? $cgi->param('inputType')    : 'none';
my $selQuarter   = (defined $cgi->param('quarter'))      ? $cgi->param('quarter')      : 0;
my $selMonth     = (defined $cgi->param('month'))        ? $cgi->param('month')        : 0;
my $selWeek      = (defined $cgi->param('week'))         ? $cgi->param('week')         : 0;
my $selYear      = (defined $cgi->param('year'))         ? $cgi->param('year')         : 0;
my $timeperiodID = (defined $cgi->param('timeperiodID')) ? $cgi->param('timeperiodID') : 1;
my $pf           = (defined $cgi->param('pf'))           ? $cgi->param('pf')           : 'off';

# set: endDate
$endDateIN = $cgi->param('endDate') if ( $cgi->param('endDate') ne '' );

# set: debug
if ( $debug eq 'T' ) {
  $debugMessage = "chart: $selChart, uKey1: $uKey1, uKey2: $uKey2, uKey3: $uKey3, startDate: $startDateIN, endDate: $endDateIN, inputType: $inputType, selMonth: $selMonth, selWeek: $selWeek, selYear: $selYear.";
  $AreaBOffset += 18;
}

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

# set: forceIndex
my $forceIndex = "force index (key_startDate)"; $forceIndex = '';

# Init return value to true
$rv = 1;

# Chart specific settings
if ( $selChart eq "Status" ) {
  $yOffset     = 0;
  $AreaBOffset = 0;
} elsif ( $selChart eq "ErrorDetails" ) {
  $hight       = 500;
  $yOffset     = 0;
  $AreaBOffset = 0;
} elsif ( $selChart eq "HourlyAverage" ) {
  my ($tmpStartDate, $tmpEndDate);
  ($goodDate, $tmpStartDate, $tmpEndDate, $numberOfDays) = get_sql_startDate_sqlEndDate_numberOfDays_test ($STRICTDATE, $FIRSTSTARTDATE, $inputType, $selYear, $selQuarter, $selMonth, $selWeek, $startDateIN, $endDateIN, $currentYear, $currentMonth, $currentDay, 0);

  unless ( $goodDate ) {
    $rv = 0; $errorMessage = "Wrong Startdate and/or Enddate";
  } elsif ( $numberOfDays > 7 ) {
    $rv = 0; $errorMessage = "Hourly Average Not Available";
  } else {
    ($yearFrom, $monthFrom, $dayFrom) = split (/-/, $tmpStartDate) if (defined $tmpStartDate);
    ($yearTo, $monthTo, $dayTo) = split (/-/, $tmpEndDate) if (defined $tmpEndDate);
  }
}

if ( $rv ) {
  # open connection to database and query data
  $dbh = DBI->connect("DBI:mysql:$DATABASE:$SERVERNAMEREADONLY:$SERVERPORTREADONLY", "$SERVERUSERREADONLY", "$SERVERPASSREADONLY" ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("Cannot connect to the database", $debug, '', "", '', "", '', 0, '', $sessionID);

  if ( $dbh and $rv ) {
    if ( $uKey1 eq 'none' ) {
      $rv = 0; $errorMessage = "URL Access Parameters Error: Application 1";
    } else {
      ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $applicationTitle1, $trendvalue, undef) = get_title( $dbh, $rv, $CcatalogID, $uKey1, $debug, 0, $sessionID );
    }

    if ( $rv ) { if ( $uKey2 ne 'none' ) { ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $applicationTitle2, undef, undef) = get_title( $dbh, $rv, $CcatalogID, $uKey2, $debug, 0, $sessionID ); } }
    if ( $rv ) { if ( $uKey3 ne 'none' ) { ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString, $applicationTitle3, undef, undef) = get_title( $dbh, $rv, $CcatalogID, $uKey3, $debug, 0, $sessionID ); } }

    if ( $rv ) {
      if ( $uKey1 eq 'none' and $applicationTitle1 eq '<NIHIL>' ) {
        $rv = 0; $errorMessage = "URL Access Parameters Error: Application 1: $applicationTitle1";
      } else {
        if ( $uKey2 eq 'none' and $applicationTitle2 eq '<NIHIL>' ) {
          if ( $selChart eq "Status" ) {
            $chartTitle = "Status";
          } elsif ( $selChart eq "ErrorDetails" ) {
            $chartTitle = "Error Details";
          } elsif ( $selChart eq "Bar" ) {
            $chartTitle = "Bar";
          } elsif ( $selChart eq "HourlyAverage" ) {
            $chartTitle = "Hourly Average";
          } elsif ( $selChart eq "DailyAverage" ) {
            $chartTitle = "Daily Average";
          }

          $chartTitle .= " for '$applicationTitle1' ";
        } else {
          $chartTitle = "Comparing '$applicationTitle1'";

          if ( $uKey3 eq 'none' and $applicationTitle3 eq '<NIHIL>' ) {
            $chartTitle .= " and '$applicationTitle2' ";
          } else {
            $chartTitle .= ", '$applicationTitle2' and '$applicationTitle3' ";
          }
        }

        $chartTitle .= " from $CcatalogID ";
      }

      if ( $rv ) {
        my $addAreaBOffset = 22;
        $addAreaBOffset = 8  if ( $selChart eq "HourlyAverage" );
        $addAreaBOffset = 36 if ( $selChart eq "DailyAverage" );

        if ($inputType eq "fromto") {
          if ( defined $endDateIN ) {
            $chartTitle  .= "from $startDateIN to $endDateIN";
          } else {
            $chartTitle  .= "on $startDateIN";	
          }
        } elsif ( $inputType eq "year" ) {
          $chartTitle  .= "for $selYear";
        } elsif ( $inputType eq "quarter" ) {
          $chartTitle .= "for $selYear quarter $selQuarter";
        } elsif ( $inputType eq "month" ) {
          $chartTitle  .= "for ". $arrMonths[$selMonth -1] .' '. $selYear;
        } elsif ( $inputType eq "week" ) {
          $chartTitle .= "for $selYear week $selWeek from $CcatalogID";
        } else {
          $rv = 0; $errorMessage = "Whoops - title error! ($inputType)";
        }

        my ($sqlStartDate, $sqlEndDate);

        if ( $rv ) {
          $AreaBOffset += $addAreaBOffset;
         ($goodDate, $sqlStartDate, $sqlEndDate, undef) = get_sql_startDate_sqlEndDate_numberOfDays_test ($STRICTDATE, $FIRSTSTARTDATE, $inputType, $selYear, $selQuarter, $selMonth, $selWeek, $startDateIN, $endDateIN, $currentYear, $currentMonth, $currentDay, 0);

          if ( $goodDate ) {
            $sqlPeriode = "AND startDate between '$sqlStartDate' AND '$sqlEndDate' ";

            if ( $timeperiodID > 1 ) {
              $sql = "select timeperiodName, sunday, monday, tuesday, wednesday, thursday, friday, saturday from $SERVERTABLTIMEPERIODS where catalogID = '$CcatalogID' and timeperiodID = '$timeperiodID'";
              $sth = $dbh->prepare( $sql ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot dbh->prepare: $sql", $debug, '', "", '', "", 0, '', $sessionID);
              $sth->execute() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->execute: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;

              if ( $rv ) {
                ($slaWindow, my ($sunday, $monday, $tuesday, $wednesday, $thursday, $friday, $saturday)) = $sth->fetchrow_array() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->fetchrow_array: $sql", $debug, '', "", '', "", 0, '', $sessionID) if ($sth->rows);
                $sth->finish() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", 0, '', $sessionID);
                my $slaPeriode = create_sql_query_from_range_SLA_window ($sunday, $monday, $tuesday, $wednesday, $thursday, $friday, $saturday);
                $chartTitle .= ", $slaWindow" if ( defined $slaWindow );
                $sqlPeriode .= "$slaPeriode " if ( defined $slaPeriode );
              }
            }
          } else {
            $rv = 0; $errorMessage = "Wrong Startdate and/or Enddate";
          }
        }

        if ( $rv and $uKey1 ne 'none' ) {
          if ( $selChart eq "Status" ) {
            my ($title, $status, $aantal, %problemSummary);
            $sql = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, "select SQL_NO_CACHE title, status, count(status) as aantal", $forceIndex, "WHERE catalogID = '$CcatalogID' and uKey = '$uKey1'", $sqlPeriode, "AND status !='OFFLINE'", "GROUP BY status", '', "", "ALL");
            $sth = $dbh->prepare( $sql ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot dbh->prepare: $sql", $debug, '', "", '', "", 0, '', $sessionID);
            $sth->execute() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->execute: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;
            $sth->bind_columns( \$title, \$status, \$aantal ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->bind_columns: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;

		        if ( $rv ) {
  		        if ( $sth->rows ) {
                my %labels = ();

                while( $sth->fetch() ) {
                  if ($status eq '<NIHIL>') { $status = "UNKNOWN" }

                  if (exists $labels{$status}) {
                    $labels{$status} += $aantal;
                  } else {
                    $labels{$status}  = $aantal;
                  }
                }

                foreach my $label (keys %labels) {
                  push (@labels, $label);

                  if ($label eq 'OK') {
                    push (@icons, "$IMAGESPATH/$ICONS{OK}");
                    $labels{$label} *= 8 if ($uKey1 eq 'KBO-WI-P-01'); # KBO-WI specific
                  } elsif ($label eq 'WARNING') {
                    push (@icons, "$IMAGESPATH/$ICONS{WARNING}");
                    $labels{$label} *= 8 if ($uKey1 eq 'KBO-WI-P-01'); # KBO-WI specific
                  } elsif ($label eq 'CRITICAL') {
                    push (@icons, "$IMAGESPATH/$ICONS{CRITICAL}");
                  } elsif ($label eq 'UNKNOWN') {
                    push (@icons, "$IMAGESPATH/$ICONS{UNKNOWN}");
                  } elsif ($label eq 'NO TEST') {
                    push (@icons, "$IMAGESPATH/$ICONS{'NO TEST'}");
                  } elsif ($label eq 'NO DATA') {
                    push (@icons, "$IMAGESPATH/$ICONS{'NO DATA'}");	
                  } elsif ($label eq 'OFFLINE') {
                    push (@icons, "$IMAGESPATH/$ICONS{OFFLINE}");
                  }

                  push (@data, $labels{$label});
				        }
              } else {
			          $hight = 380; $rv = 0; $errorMessage = "NO DATA FOR THIS PERIOD (1)";
              }

              $sth->finish() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", 0, '', $sessionID);
            }
          } elsif ( $selChart eq "ErrorDetails" ) {
            my ($title, $statusmessage, $aantal, %problemSummary);
            $sql = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, "select SQL_NO_CACHE title, statusmessage, count(statusmessage) as aantal", $forceIndex, "WHERE catalogID = '$CcatalogID' and uKey = '$uKey1'", $sqlPeriode, "AND status ='CRITICAL'", "GROUP BY statusmessage", '', "", "ALL");
            $sth = $dbh->prepare( $sql ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot dbh->prepare: $sql", $debug, '', "", '', "", 0, '', $sessionID);
            $sth->execute() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->execute: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;
            $sth->bind_columns( \$title, \$statusmessage, \$aantal ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->bind_columns: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;

		        if ( $rv ) {
  		        if ( $sth->rows ) {
                while( $sth->fetch() ) {
                  my ($dummy, $rest) = split(/:/, $statusmessage, 2);
                  $rest = $dummy unless ( $rest );

                  if ($rest) {
                  # ($rest, undef) = split(/\|/, $rest, 2); # remove performance data
                     my $_rest = reverse $rest;
                     my ($_rest, undef) = reverse split(/\|/, $_rest, 2);
                     my $rest = reverse $_rest;

                    ($dummy, $rest) = split(/,/, $rest, 2);
                    $rest = $dummy unless ( $rest);
                  } else {
                    $rest = ' UNDEFINED';
                  }
				  
                  if (exists $problemSummary{$rest}) {
                    $problemSummary{$rest} += $aantal;
                  } else {
                    $problemSummary{$rest}  = $aantal;
                  }
                }

                foreach my $rest (sort {$problemSummary{$b} <=> $problemSummary{$a}} (keys(%problemSummary))) {
                  push (@data, $problemSummary{$rest});
                  push (@labels, substr($rest, 1, 38));
                }
              } else {
			          $hight = 380; $rv = 0; $errorMessage = "NO ERRORS FOR THIS PERIOD";
              }

              $sth->finish() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", 0, '', $sessionID);
            }
          } elsif ( $selChart eq "Bar" ) {
            my ($seconden, $duration, $startDate, $startTime, $status, $step);
            my ($dataOK, $dataWarning, $dataCritical, $dataUnknown, $dataNoTest, $dataOffline);
            $sql = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, "select SQL_NO_CACHE duration, startDate, startTime, status, step", $forceIndex, "WHERE catalogID = '$CcatalogID' and uKey = '$uKey1'", $sqlPeriode, '', "", '', "order by startDate, startTime", "ALL");
            $sth = $dbh->prepare( $sql ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot dbh->prepare: $sql", $debug, '', "", '', "", 0, '', $sessionID);
            $sth->execute() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->execute: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;
            $sth->bind_columns( \$duration, \$startDate, \$startTime, \$status, \$step ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->bind_columns: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;

		        if ( $rv ) {
  		        if ( $sth->rows ) {
                my $counter = 0;
                $numberOfLabels = ($sth->rows < 25) ? $sth->rows : 25;
                my $labelCounter = int($sth->rows / $numberOfLabels);
                my $limitTrendvalue = ($trendvalue) ? $trendvalue * 2.5 : 9000;
                my $moreDays = (defined $endDateIN or $inputType eq "year" or $inputType eq "quarter" or $inputType eq "month" or $inputType eq "week") ? 1 : 0;

                while( $sth->fetch() ) {
                  $dataOK = $dataWarning = $dataCritical = $dataUnknown = $dataNoTest = $dataOffline = "0";
                  $seconden = int(substr($duration, 6, 2)) + int(substr($duration, 3, 2)*60) + int(substr($duration, 0, 2)*3600);
                  $seconden += 0.5 if ($seconden == 0); # correction for to fast testresults

                  if ($status eq 'OK') {
                    $dataOK = ($seconden < $limitTrendvalue) ? $seconden : $limitTrendvalue;
                  } elsif ($status eq 'WARNING') {
                    $dataWarning = "-5";
                  } elsif ($status eq 'CRITICAL') {
                    $dataCritical = "-5";
                  } elsif ($status eq 'UNKNOWN') {
                    $dataUnknown = "-5";
                  } elsif ($status eq 'NO TEST') {
                    $dataNoTest = "-5";
                  } elsif ($status eq 'OFFLINE') {
                    $dataOffline = "-5";
                  }
				
                  push (@dataOK,       $dataOK);
                  push (@dataWarning,  $dataWarning);
                  push (@dataCritical, $dataCritical);
                  push (@dataUnknown,  $dataUnknown);
                  push (@dataNoTest,   $dataNoTest);
                  push (@dataOffline,  $dataOffline);

                  if ($labelCounter == 1 or $labelCounter == $counter or ($counter == 0 and $labelCounter >= 2)) {
                    if ($moreDays) {
                      push (@labels, $startDate . " ~ " . substr($startTime, 0, 5));
                    } else {
                      push (@labels, substr($startTime, 0, 5));
                    }

                    $counter = 1;
                  } else {
                    push (@labels, "");
                    $counter++;
                  }
                }

                $AreaBOffset += 36 if ($moreDays);
              } else {
			          $hight = 380; $rv = 0; $errorMessage = "NO DATA FOR THIS PERIOD (2)";
              }

              $sth->finish() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", 0, '', $sessionID);
            }
          } elsif ( $selChart eq "HourlyAverage" or $selChart eq "DailyAverage" ) {
            ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = getAverage( 1, $dbh, $rv, $uKey1, $sqlStartDate, $sqlEndDate, $sqlPeriode, $selChart, $debug );
          }
        }

        if ( $rv and $uKey2 ne 'none' ) {
          if ( $selChart eq "HourlyAverage" or $selChart eq "DailyAverage" ) {
            ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = getAverage( 2, $dbh, $rv, $uKey2, $sqlStartDate, $sqlEndDate, $sqlPeriode, $selChart, $debug );
          }
        }

        if ( $rv and $uKey3 ne 'none' ) {
          if ( $selChart eq "HourlyAverage" or $selChart eq "DailyAverage" ) {
            ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = getAverage( 3, $dbh, $rv, $uKey3, $sqlStartDate, $sqlEndDate, $sqlPeriode, $selChart, $debug );
          }
        }

        if ( $rv ) {
          if ( $selChart eq "HourlyAverage" ) {
            my @refenentieLabels;
	
            for($i = 0; $i < $numberOfDays; ++$i) {
	          for ($j = 0; $j <= 23; ++$j) {
                my ($Tyear, $Tmonth, $Tday) = Add_Delta_Days($yearFrom, $monthFrom, $dayFrom, $i);
	            push (@refenentieLabels, "$Tyear-$Tmonth-$Tday:$j");
                push (@labels,  $j);
              }
            }

            $width = ( $numberOfDays > 1 ) ? 24 * $numberOfDays * 25 : $width;

            @avg1 = rebuildDataArrayHourlyAverage (\@refenentieLabels, \@labels1, \@avg1);
            @avg2 = rebuildDataArrayHourlyAverage (\@refenentieLabels, \@labels2, \@avg2) if ($uKey2 ne 'none');
            @avg3 = rebuildDataArrayHourlyAverage (\@refenentieLabels, \@labels3, \@avg3) if ($uKey3 ne 'none');
          } elsif ( $selChart eq "DailyAverage" ) {
            my $prev = "2003-10-12";
            @labels = sort(@labels1, @labels2, @labels3);
            @labels = grep($_ ne $prev && ($prev = $_), @labels);
            $numberOfLabels = scalar(@labels);
            $width = ( $numberOfLabels > 40 ) ? $numberOfLabels * 25 : $width;

            @avg1 = rebuildDataArrayDailyAverage (\@labels, \@labels1, \@avg1);
            @avg2 = rebuildDataArrayDailyAverage (\@labels, \@labels2, \@avg2) if ($uKey2 ne 'none');
            @avg3 = rebuildDataArrayDailyAverage (\@labels, \@labels3, \@avg3) if ($uKey3 ne 'none');
          }
        }
	    }
    }

    $dbh->disconnect or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("Sorry, the database was unable to disconnect", $debug, '', "", '', "", '', 0, '', $sessionID);
  }
}

my $c;

if ( $selChart eq "Status" or $selChart eq "ErrorDetails" ) {
  # Create Piehart object with: width, hight, backgroundcolor, ...
  $c = new PieChart($width, $hight, $background, -1, 0);

  # Set the center of the pie at (<>, <>) and the radius to <> pixels
  $c->setPieSize($width/2, $hight/2, 130);

  # Draw the pie in 3D
  $c->set3D();
} else {
  # Create XYChart object with: width, hight, backgroundcolor, bordercolor, pxp-3d borden
  $c = new XYChart($width, $hight, $background, $background, 0);

  # Set the plotarea at (xOffset, yOffset) and of size $width - 95 x $hight - 78 pixels, with white background. Set border and grid line colors to 0xa08040.
  $c->setPlotArea($xOffset, $yOffset, $width - 95, $hight - $AreaBOffset, 0xffffff, -1, 0xaCCCCCC, 0xaCCCCCC, 0xaCCCCCC);

  # Set the axes width to 1 pixels
  $c->xAxis()->setWidth(1);
  $c->yAxis()->setWidth(1);

  # Set the axis colors
  $c->xAxis()->setColors($axisColor);
  $c->yAxis()->setColors($axisColor);

  # Add a title on the the y axis
  my $yAxisTitle = ($selChart eq 'Bar') ? 'Response time' : 'Average response time';
  $c->yAxis()->setTitle($yAxisTitle, "arial.ttf", 9, $forGround);

  # Add a title on the the x axis
  $c->xAxis()->setTitle("<*block,valign=absmiddle*>Date/Time<*/*>")->setFontColor($forGround);
}

# Add a title box to the chart using 10 pts Arial Bold Italic font.
$chartTitle = "Error for '$prgtext'" unless ( defined $chartTitle and $rv );
$c->addText($width/2, 14, $chartTitle, "arialbi.ttf", 10, $forGround, 5, 0);

# Add debugMessage and errorMessage
$c->addText($width - 18, $hight - 33, $debugMessage, "arial.ttf", 8, $forGround, 6, 0) if ( defined $debugMessage );
$c->addText($width/2, (($hight - $yOffset - $AreaBOffset)/2) + $yOffset + 16, $errorMessage, "arial.ttf", 12, 0xFF0000, 5, 0) if ( defined $errorMessage );
$c->addText($width/2, (($hight - $yOffset - $AreaBOffset)/2) + $yOffset - 16, $dbiErrorCode, "arial.ttf", 10, 0xFF0000, 5, 0) if ( defined $dbiErrorCode );
$c->addText($width/2, (($hight - $yOffset - $AreaBOffset)/2) + $yOffset + 48, $dbiErrorString, "arial.ttf", 10, 0xFF0000, 5, 0) if ( defined $dbiErrorString );

# Add a custom CDML text at the bottom right of the plot area as the logo
$c->addText($width - 3, 92, $APPLICATION . " @ " . $BUSINESS, "arial.ttf", 8, $forGround, 6, 270);
$c->addText($width - 18, $hight - 18, $DEPARTMENT . " @ " . $BUSINESS . ", created on: " . scalar(localtime()) . ".", "arial.ttf", 8, $forGround, 6, 0);

if ( $rv ) {
  if ( $selChart eq "Status" or $selChart eq "ErrorDetails" ) {
    # use given color array as the data colors (sector colors)
    if ( $selChart eq "Status" ) {
      my (@colors);
      foreach my $label (@labels) { push (@colors, $COLORSPIE {$label} ); }
      $c->setColors2($perlchartdir::DataColor, \@colors);

      # Add icons to the chart as a custom field
      $c->addExtraField(\@icons);
    } elsif ( $selChart eq "ErrorDetails" ) {
      my $colors = [0xb8bc9c, 0xecf0b9, 0x999966, 0x333366, 0xc3c3e6, 0x594330,0xa0bdc4];
      $c->setColors2($perlchartdir::DataColor, $colors);
    }

    # Use the side label layout method
    $c->setLabelLayout($perlchartdir::SideLayout);
    $c->setLabelStyle("tahoma.ttf", 8, $forGround)->setBackground($perlchartdir::Transparent, $perlchartdir::Transparent, 0);
    $c->setLabelFormat("<*block,valign=absmiddle*><*img={field0}*> {label} (#{value} - {percent}%)");

    # Set the border color of the sector the same color as the fill color. Set the line color of the join line to forgroundcolor
    $c->setLineColor($perlchartdir::SameAsMainColor, $forGround);

    # Set the start angle to 135 degrees
    $c->setStartAngle(135);

    # Set the pie data and the pie labels
    $c->setData(\@data, \@labels);
  } else {
    # Set the labels on the x & y axis
    my $fontAngel = ( $selChart eq "HourlyAverage" ) ? 0 : 45;
    $c->xAxis()->setLabelStyle("Arial.ttf", 8, $forGround)->setFontAngle($fontAngel);
    $c->xAxis()->setLabels(\@labels);
    $c->yAxis()->setLabelStyle("Arial.ttf", 8, $forGround)->setFontAngle(0);
    $c->yAxis()->setLabelFormat("{value|2,.}");

    # Set the margins at the two ends of the axis during auto-scaling, and whether to start the axis from zero.
    $c->yAxis()->setAutoScale(5, 10, 0);

    # Add a mark line ore zone to the chart and add the first two data sets to the chart as a stacked bar group
    if ( $uKey2 eq 'none' and $uKey3 eq 'none' ) {
      $trendvalue = 3600 if ($trendvalue == 0);
      $trendvalue += 0.05;
      $c->yAxis()->addZone($trendvalue, 3600, $trendZone) if ($trendvalue != 0);
    }

    $c->yAxis()->addZone(0, -6, $trendZone);
	  my $layer;
	
    if ( $selChart eq "Bar" ) {
      # Add a line layer to the chart
      $layer = $c->addBarLayer2($perlchartdir::Stack);

      # Set the sub-bar gap to 0, so there is no gap between stacked bars with a group
      $layer->setBarGap(-1.7E-100, 0);
	
      # Add the first two data sets to the chart as a stacked bar group
      $layer->addDataSet(\@dataOK, $layer->yZoneColor($trendvalue, $COLORSRRD {OK}, $COLORSRRD {TRENDLINE}), " Duration");
      $layer->addDataSet(\@dataWarning,  $COLORSRRD {WARNING},  " Warning");
      $layer->addDataSet(\@dataCritical, $COLORSRRD {CRITICAL}, " Critical");
      $layer->addDataSet(\@dataUnknown,  $COLORSRRD {UNKNOWN},  " Unknown");
      $layer->addDataSet(\@dataOffline,  $COLORSRRD {OFFLINE},  " Offline");
      $layer->addDataSet(\@dataNoTest,   $COLORSRRD {"NO TEST"},  " No Test");
    } elsif ( $selChart eq "HourlyAverage" or $selChart eq "DailyAverage" ) {
      if ( $selChart eq "HourlyAverage" ) {
        for($i = 1; $i < $numberOfDays; ++$i) { my $xMark1 = $c->xAxis()->addMark((24 * $i), 0x0000FF); }
        my $xCorrectie = 95 - $xOffset;

        for($i = 0; $i < $numberOfDays; ++$i) {
          my $cdate = Date_to_Text_Long ( Add_Delta_Days($yearFrom, $monthFrom, $dayFrom, $i) );
          my $x = ($numberOfDays > 1) ? ($i * 600) + 300 + $xCorrectie : ($width/2) + $xCorrectie;
          $c->addText($x, 40, $cdate, "arialbi.ttf", 10, 0x000000, 5, 0);
        }
      }

      # Add a line layer to the chart
      $layer = $c->addSplineLayer();

      # Add the first two data sets to the chart as a stacked bar group
      $layer->addDataSet(\@avg1, 0xcf4040, "$applicationTitle1")->setDataSymbol($perlchartdir::DiamondSymbol, 8);
      if ($uKey2 ne 'none') { $layer->addDataSet(\@avg2, 0x6699cc, "$applicationTitle2")->setDataSymbol($perlchartdir::DiamondSymbol, 8); }
      if ($uKey3 ne 'none') { $layer->addDataSet(\@avg3, 0x009900, "$applicationTitle3")->setDataSymbol($perlchartdir::DiamondSymbol, 8); }

      # Enable data label on the data points.
      $layer->setDataLabelFormat("{value|2,.}");
    }

    # Set the bar border to transparent
    $layer->setBorderColor($perlchartdir::Transparent);

    if ($pf eq 'on') {
      $c->addLegend(2, $hight - 32, 0, "arial.ttf", 8)->setBackground($perlchartdir::Transparent);
    } else {
      $c->addLegend(2, $hight - 32, 0, "arial.ttf", 8)->setFontColor($forGround);
    }
  }
}

# Output the chart
binmode(STDOUT);
print "Content-type: image/png\n\n";
print $c->makeChart2($perlchartdir::PNG);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub getAverage {
  my ($number, $dbh, $rv, $uKey, $sqlStartDate, $sqlEndDate, $sqlPeriode, $selChart, $debug) = @_;

  my ($sql, $sth, $errorMessage, $dbiErrorCode, $dbiErrorString, $startDate, $hour, $average, @avg, @labels);

  if ( $selChart eq "HourlyAverage" ) {
    $sql = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, "select SQL_NO_CACHE startDate, hour(startTime) as hour, round(avg(time_to_sec(duration)), 2)", $forceIndex, "WHERE catalogID = '$CcatalogID' and uKey = '$uKey'", $sqlPeriode, "AND status = 'OK'", "GROUP BY startDate, hour(startTime)", '', "order by startDate, hour", "ALL");
  } else {
    $sql = create_sql_query_events_from_range_year_month ($inputType, $sqlStartDate, $sqlEndDate, "select SQL_NO_CACHE startDate, round(avg(time_to_sec(duration)), 2)", $forceIndex, "WHERE catalogID = '$CcatalogID' and uKey = '$uKey'", $sqlPeriode, "AND status = 'OK'", "GROUP BY startDate", '', "order by startDate", "ALL");
  }

  $sth = $dbh->prepare( $sql ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot dbh->prepare: $sql", $debug, '', "", '', "", 0, '', $sessionID);
  $sth->execute() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->execute: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;

  if ( $selChart eq "HourlyAverage" ) {
    $sth->bind_columns( \$startDate, \$hour, \$average ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->bind_columns: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;
  } else {
    $sth->bind_columns( \$startDate, \$average ) or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->bind_columns: $sql", $debug, '', "", '', "", 0, '', $sessionID) if $rv;
  }

  if ( $rv ) {
    if ( $sth->rows ) {
      while( $sth->fetch() ) {
        push (@avg, $average);

        if ( $selChart eq "HourlyAverage" ) {
          push (@labels, $startDate .":". $hour);
        } else {
          push (@labels, $startDate);
        }
      }
    } else {
      $hight = 380; $rv = 0; $errorMessage = "NO DATA FOR THIS PERIOD (3)";
    }

    $sth->finish() or ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString) = error_trap_DBI("", "Cannot sth->finish", $debug, '', "", '', "", 0, '', $sessionID);
  }

  if ( $number == 1 ) {
    @avg1 = @avg; @labels1 = @labels;
  } elsif ( $number == 2 ) {
    @avg2 = @avg; @labels2 = @labels;
  } elsif ( $number == 3 ) {
    @avg3 = @avg; @labels3 = @labels;
  }

  return ($rv, $errorMessage, $dbiErrorCode, $dbiErrorString);
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub rebuildDataArrayHourlyAverage {
  my ($arr_full, $arr_part, $arr_data) = @_;

  my (@arr_res, $found, $cdate1, $time1, $cdate2, $time2, $year1, $month1, $day1, $year2, $month2, $day2);

  for (my $i = 0; $i < @$arr_full; $i++) {			
    ($cdate1, $time1) = split(/:/, @$arr_full[$i]);
	($year1, $month1, $day1) = split(/-/, $cdate1);
    $found = 0;

    for (my $j = 0; $j < @$arr_part; $j++) {
      ($cdate2, $time2) = split(/:/, @$arr_part[$j]);
      ($year2, $month2, $day2) = split(/-/, $cdate2);
				
      if (($time1 == $time2) and ($day1 == $day2)) {
        push (@arr_res, @$arr_data[$j]);
        $found = 1;
      }
    }  			

    push (@arr_res, 0.00) unless ( $found );
  }

  return @arr_res;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub rebuildDataArrayDailyAverage {
  my ($arr_full, $arr_part, $arr_data) = @_;

  my (@arr_res, $found);
	
  for (my $i = 0; $i < @$arr_full; $i++) {			
    $found = 0;

    for (my $j = 0; $j < @$arr_part; $j++) {
      if (@$arr_full[$i] eq @$arr_part[$j]) {
	    push (@arr_res, @$arr_data[$j]);
        $found = 1;
      }
    }
  			
    push (@arr_res, 0.00) unless ( $found );
  }

  return @arr_res;
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

