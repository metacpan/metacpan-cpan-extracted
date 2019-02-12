#!/usr/bin/perl -w

## File: dta-cab-http-check.perl
## Author: Bryan Jurish <jurish@bbaw.de>
## Description:
##  + DTA::CAB::Server::HTTP monitoring plugin (for nagios, icinga, etc)

use File::Basename qw(basename dirname);
use Monitoring::Plugin;
use LWP::UserAgent;
use URI::Escape qw(uri_escape_utf8);
use JSON;
use Time::HiRes qw(gettimeofday tv_interval);
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use strict;

##======================================================================
## Version
our $VERSION = 0.02;
our $SVNID   = q(
  $HeadURL: svn+ssh://odo.dwds.de/home/svn/dev/DTA-CAB/trunk/dta-cab-http-check.perl $
  $Id: dta-cab-http-check.perl 29526 2019-02-12 12:21:44Z moocow $
);

##======================================================================
## Globals

our ($help,$version);
our $mp = 'Monitoring::Plugin';   ##-- later: object
our $prog = basename($0);
our $qmode = 'status'; ##-- 'status' or 'query'
our $query = '';
our $expect = ''; ##-- regex for expected response in 'query' mode

our $timeout   = 30;
our $time_warn =  5;
our $time_crit = 10;

our $vl_silent = 0;
our $vl_debug  = 1;
our $vl_trace  = 2;
our $verbose  = $vl_silent;  ##-- 0..2

##======================================================================
## Command-Line
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,

	   ##-- behavior
	   'query-timeout|qt|timeout|t=i' => \$timeout,
	   'time-warn|tw|warn|w=i' => \$time_warn,
	   'time-critical|tc|critical|c=i' => \$time_crit,

	   ##-- query mode
	   'status|s' => sub { $qmode='status'; },
	   'query|q=s' => sub { $qmode='query'; $query=$_[1]; },
	   'expect|e=s' => \$expect,

	   ##-- logging
	   'verbose|v' => sub { ++$verbose; },
	  );

if ($version) {
  print STDERR "${prog} version ${VERSION}${SVNID}";
  exit 0;
}
pod2usage({-exitval=>0, -verbose=>0}) if ($help);


##-- Monitoring::Plugin interface object
$mp = Monitoring::Plugin->new
  (
   shortname => 'CAB',
   usage => 'Usage: %s [OPTIONS] CAB_SERVER_URL(s)...',
   version => $VERSION,
   #blurb   => $blurb,
   #extra   => $extra,
   #url     => $url,
   license => "perl5",
   plugin  => 'CAB',
   timeout => $timeout,
  );

##-- signal handling
$SIG{__DIE__} = sub {
  $mp->plugin_die(UNKNOWN, join('', @_));
};

##======================================================================
## verbose messaging

## undef = vmsg($level,@msg)
sub vmsg {
  my $level = shift;
  return if (!defined($level) || ($verbose < $level));
  print STDERR "$prog: ", @_, "\n";
}


##======================================================================
## MAIN

$mp->plugin_die("no server URL specified") if (!@ARGV);
my $url    = shift(@ARGV);
my ($geturl);
if ($qmode eq 'status' && $url !~ /\bstatus\b/) {
  $geturl = "$url/status?f=json";
}
elsif ($qmode eq 'query') {
  $geturl  = "$url/query" if ($url !~ /\bquery\b/);
  $geturl .= ($url =~ /\?/ ? '&' : '?');
  my $qstr = $query;
  utf8::decode($qstr) if (!utf8::is_utf8($qstr));
  $geturl .= "qd=".uri_escape_utf8("$qstr\n");
}

##-- sanitize thresholds
$time_crit = $timeout    if ($timeout   < $time_crit);
$time_warn = $time_crit  if ($time_crit < $time_warn);

##-- debug output
vmsg($vl_debug, "set url = $url");
vmsg($vl_debug, "set geturl = $geturl");
vmsg($vl_debug, "set timeout = ", $timeout);
vmsg($vl_debug, "set time_warn = ", $time_warn);
vmsg($vl_debug, "set time_crit = ", $time_crit);


##-- query server
my $ua = LWP::UserAgent->new(
			     ssl_opts => {SSL_verify_mode=>'SSL_VERIFY_NONE'}, ##-- avoid "certificate verify failed" errors
			    )
  or die("$prog: failed to create user agent for URL $url: $!");
$ua->timeout($timeout);

my $t0  = [gettimeofday];
my $rsp = $ua->get($geturl)
  or die("failed to retrieve URL $geturl");
my $time  = sprintf("%.3f", tv_interval($t0));

##-- parse response & add perforamance data
$mp->add_perfdata(label=>'time', value=>$time, uom=>'s');
my $status = {};
my $rc  = OK;
my $msg = '';
if ($rsp->is_success) {
  my $data = $rsp->decoded_content;
  vmsg($vl_trace, "got response = ", $data);

  if ($qmode eq 'status') {
    ##-- status check
    eval { $status = from_json($data); };
    die("$prog: failed to parse status response: $@") if (!$status);

    ##-- get status perfdata
    my $memMB = sprintf("%.2f", ($status->{memSize}//0) / 1024);
    my $rssMB = sprintf("%.2f", ($status->{memRSS}//0) / 1024);
    $mp->add_perfdata(label=>'mem', value=>$memMB, uom=>'MB');
    $mp->add_perfdata(label=>'nreq', value=>($status->{nRequests}//0), uom=>'c');
    $mp->add_perfdata(label=>'nerr', value=>($status->{nErrors}//0), uom=>'c');
    {
      no warnings 'numeric';
      $mp->add_perfdata(label=>'ncached', value=>($status->{nCacheHits}+0), uom=>'c');
    };

    ##-- new perfdata for DTA::CAB v1.101 (2018-03-22 14:10:24+0100)
    $mp->add_perfdata(label=>'rss', value=>$rssMB, uom=>'MB');
    foreach (1,5,15) {
      $mp->add_perfdata(label=>"qtavg$_", value=>sprintf("%.4f",1000*($status->{"qtAvg$_"}//0)), uom=>'ms');
    }

    ##-- get return message
    $msg = "$url - ${time}s ${memMB}MB";
  }
  elsif ($qmode eq 'query') {
    ##-- query check
    $msg = "$url - ${time}s";
    if ($expect) {
      if ($data !~ /$expect/o) {
	$rc = CRITICAL;
	$msg = "$url - ERROR - pattern not found";
      }
    }
  }
  else {
    ##-- unknown query mode
    $msg = "$url - ${time}s";
  }
}
else {
  $rc = CRITICAL;
  $msg = "$url - ERROR - ".$rsp->status_line;
}

##-- check threshholds
my $time_rc = $mp->check_threshold(check=>$time, warning=>$time_warn, critical=>$time_crit);
$rc         = $time_rc if ($time_rc > $rc);

##-- final exit
$mp->plugin_exit($rc, "$msg");

__END__

=pod

=head1 NAME

dta-cab-http-check.perl - DTA::CAB http-server monitoring plugin for nagios/icinga

=head1 SYNOPSIS

 dta-cab-http-check.perl [OPTIONS] SERVER_URL

 Options:
  -h, -help               # this help message
  -V, -version            # show version information and exit
  -t, -timeout SECS       # set probe query timeout (default=60)
  -w, -time-warn SECS     # set response time threshold for 'warning' state (default=10)
  -c, -time-crit SECS     # set response time threshold for 'critical' state (default=60)
  -s, -status             # perform a 'status' query SERVER_URL/status?f=json (default)
  -q, -query QSTR         # perform a default query on SERVER_URL/query?qd=QSTR
  -v, -verbose            # increase verbosity level

=cut

##------------------------------------------------------------------------------
## Description
##------------------------------------------------------------------------------
=pod

=head1 DESCRIPTION

...

=cut

##------------------------------------------------------------------------------
## See Also
##------------------------------------------------------------------------------
=pod

=head1 SEE ALSO

...

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 COPYRIGHT

Copyright (c) 2016-2019, Bryan Jurish.  All rights reserved.

This package is free software.  You may redistribute it
and/or modify it under the same terms as Perl itself,
either Perl 5.20.2 or at your option any newer version
of Perl 5 you have available.

=cut

##------------------------------------------------------------------------------
## Footer
##------------------------------------------------------------------------------
=pod

=head1 AUTHOR

Bryan Jurish E<lt>jurish@bbaw.de<gt>

=cut
