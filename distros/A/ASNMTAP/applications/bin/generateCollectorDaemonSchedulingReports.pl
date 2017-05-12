#!/usr/bin/env perl
# ---------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, generateCollectorDaemonSchedulingReports.pl
# ---------------------------------------------------------------------------------------------------------
#  http://asnmtap.citap.be/results/_ASNMTAP/reports/yyyymmdd-collectorDaemonSchedulingReports.pl-_ASNMTAP-FQDN-Daily.pdf
# ---------------------------------------------------------------------------------------------------------

use strict;
use warnings;           # Must be used in test mode only. This reduces a little process speed
#use diagnostics;       # Must be used in test mode only. This reduces a lot of process speed

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

BEGIN { if ( $ENV{ASNMTAP_PERL5LIB} ) { eval 'use lib ( "$ENV{ASNMTAP_PERL5LIB}" )'; } }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use Time::Local;
use Getopt::Long;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use ASNMTAP::Asnmtap::Applications v3.002.003;
use ASNMTAP::Asnmtap::Applications qw(:APPLICATIONS &call_system

                                      $CATALOGID
                                      $REPORTDIR
                                      $RESULTSPATH
                                      $REMOTE_HOST $HTTPSURL
                                      $HTMLTOPDFPRG $HTMLTOPDFOPTNS
                                      &create_header &create_footer
                                      &init_email_report &send_email_report &encode_html_entities
                                     );

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use vars qw($opt_V $opt_h $opt_D $PROGNAME);

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

$PROGNAME       = "generateCollectorDaemonSchedulingReports.pl";
my $prgtext     = "Generate Collector Daemon Scheduling Reports for the '$APPLICATION'";
my $version     = do { my @r = (q$Revision: 3.002.003$ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r }; # must be all on one line or MakeMaker will get confused.

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $debug       = 0;                                            # default

my $currentYear = sprintf ("%04d", (localtime)[5]+1900 );       # default
my $currentMonth= sprintf ("%02d", ((localtime)[4])+1 );        # default
my $currentDay  = sprintf ("%02d", ((localtime)[3]) );          # default

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help ();
sub print_usage ();

Getopt::Long::Configure('bundling');

GetOptions (
  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  "D:s" => \$opt_D, "debug:s"       => \$opt_D,
  "V"   => \$opt_V, "version"       => \$opt_V,
  "h"   => \$opt_h, "help"          => \$opt_h
);

if ($opt_V) { print_revision($PROGNAME, $version); exit $ERRORS{OK}; }
if ($opt_h) { print_help(); exit $ERRORS{OK}; }

if ($opt_D) {
  if ($opt_D eq 'F' || $opt_D eq 'T' || $opt_D eq 'L') {
    $debug = 0 if ($opt_D eq 'F');
    $debug = 1 if ($opt_D eq 'T');
    $debug = 2 if ($opt_D eq 'L');
  } else {
    usage("Invalid debug: $opt_D\n");
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $sqlPeriode            = 3600;
my $width                 = 1000;
my $xOffset               = 300;
my $yOffset               = 42;
my $labelOffset           = 32;
my $AreaBOffset           = 78;
my $hightMin              = 195;
my $currentTimeslot       = 0;
my $printerFriendlyOutput = 0;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($emailReport, $rvOpen) = init_email_report (*EMAILREPORT, "generateCollectorDaemonSchedulingReports.txt", $debug);

create_dir ($RESULTSPATH);

my $emailMessage = "\n";

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my $urlAccessParameters;

$urlAccessParameters  = "htmlToPdf=1";
$urlAccessParameters .= "&catalogID=$CATALOGID";
$urlAccessParameters .= "&sqlPeriode=$sqlPeriode";
$urlAccessParameters .= "&width=$width";
$urlAccessParameters .= "&xOffset=$xOffset";
$urlAccessParameters .= "&yOffset=$yOffset";
$urlAccessParameters .= "&labelOffset=$labelOffset";
$urlAccessParameters .= "&AreaBOffset=$AreaBOffset";
$urlAccessParameters .= "&hightMin=$hightMin";
$urlAccessParameters .= "&currentTimeslot=on" if ($currentTimeslot);
$urlAccessParameters .= "&pf=on" if ($printerFriendlyOutput);

my $logging = $RESULTSPATH .'/_ASNMTAP';
create_dir ($logging);

my $reports = $logging .'/'. $REPORTDIR;
create_dir ($reports);

$logging .= "/";
create_header ($logging."HEADER.html");
create_footer ($logging."FOOTER.html");

$reports .= "/";
create_header ($reports."HEADER.html");
create_footer ($reports."FOOTER.html");

use Sys::Hostname;
my $hostname = hostname();
$hostname =~ s/\./_/g;
my $pdfFilename = "$RESULTSPATH/_ASNMTAP/$REPORTDIR/$currentYear$currentMonth$currentDay-collectorDaemonSchedulingReports.pl-_ASNMTAP-$hostname-Daily.pdf";
my $encodedUrlAccessParameters = encode_html_entities('U', $urlAccessParameters);
my $command = "$HTMLTOPDFPRG -f '$pdfFilename' $HTMLTOPDFOPTNS 'http://${REMOTE_HOST}$HTTPSURL/cgi-bin/moderator/collectorDaemonSchedulingReports.pl?$encodedUrlAccessParameters'";

if ( -e "$pdfFilename" ) {
  $emailMessage .= "  > $pdfFilename already generated\n";
} else {
  $emailMessage .= "  > $pdfFilename will be generated\n";

  if ($HTMLTOPDFPRG eq 'HTMLDOC') {
    $ENV{HTMLDOC_NOCGI} = 1;
    select(STDOUT);  $| = 1;
  }

  my ($status, $stdout, $stderr) = call_system ("$command", $debug);

  unless ( $status == 0 and $stdout eq '' and $stderr eq '' ) {
    $emailMessage .= $pdfFilename. " generation failed\n";
    $emailMessage .= "call_system: command: $command, status: $status, stdout: $stdout, stderr: $stderr\n" if ( $debug );
  } else {
    $emailMessage .= $pdfFilename. " generated\n";
  }
}

$emailMessage .= "\n";

if ( $debug ) { print $emailMessage; } else { print EMAILREPORT $emailMessage; }

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

my ($rc) = send_email_report (*EMAILREPORT, $emailReport, $rvOpen, $prgtext, $debug);
exit;

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub create_dir {
  my ($directory) = @_;

  unless ( -e "$directory" ) {                        # create $directory
    my ($status, $stdout, $stderr) = call_system ("mkdir $directory", $debug);

    if (!$status and ($stdout ne '' or $stderr ne '')) {
      my $error = "  > create_dir: mkdir $directory: status: $status, stdout: $stdout, stderr: $stderr\n";
      if ( $debug ) { print $error; } else { print EMAILREPORT $error; }
    }
  }
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_usage () {
  print "Usage: $PROGNAME [-D <debug>] [-V version] [-h help]\n";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sub print_help () {
  print_revision($PROGNAME, $version);
  print "ASNMTAP Generate Collector Daemon Scheduling Reports for the '$APPLICATION'

-D, --debug=F|T|L
   F(alse)  : screendebugging off (default)
   T(true)  : normal screendebugging on
   L(ong)   : long screendebugging on
-V, --version
-h, --help

Send email to $SENDEMAILTO if you have questions regarding
use of this software. To submit patches or suggest improvements, send
email to $SENDEMAILTO

";
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

