#!/usr/bin/perl
#
# Meltdown.pl - Used to collect stats on running AFS process with rxdebug.
#
# Original Implementation:
#	Unknown - Meltdown.csh, Meltdown.awk
#
# Change History:
#	Jul 02, 2002 - Rex Basham - Added check for wproc, left out during the
#				    original conversion from awk/csh scripts.
#	Mar 21, 2002 - Rex Basham - Merged original csh and awk scripts
#	                            and converted to perl
#	Mar 23, 2002 - Rex Basham - Fixed the display format and added
#                                   field format expansion
#       August 2004  - SLAC       - modified to use the Perl rxdebu function
#
#   Aug 30, 2006 - Jeff Blaine - Added CSV stats output mode
#
# Parameters are -s <server> -p <port> -t <sleeptime in seconds>
# and -C to enable CSV-output mode
#
# Example:
#	Meltdown.pl -s point -p 7000 -t 300
#
#	Check the server 'point' on port '7000' with 5 minutes between
#	rxdebug commands.
#

use blib;
use AFS::Monitor;

sub Usage {
	print STDERR "\n\n$progName: collect rxdebug stats on AFS process.\n";
	print STDERR "usage: $progName [options]\n";
	print STDERR "options:\n";
	print STDERR " -s <server>    (required parameter, no default).\n";
	print STDERR " -p <port>      (default: 7000).\n";
	print STDERR " -t <interval>  (default: 1200 seconds).\n";
	print STDERR " -C             \n";
	print STDERR " -h             (help: show this help message).\n\n";
	print STDERR "Example: $progName -s point -p 7000\n";
	print STDERR "Collect statistics on server point for port 7000\n";
	print STDERR "Refresh interval will default to 20 minutes (1200 seconds)\n\n";
	exit 0;
} # Usage

sub Check_data {
	#
	# If a value is going to overflow the field length,
	# then bump the field length to match the value.
	# It won't be pretty but we'll have valid data.
	#
	(length $wproc	> $Ln[0]) ? ($Ln[0] = length $wproc)	: "";
	(length $nobuf	> $Ln[1]) ? ($Ln[1] = length $nobuf)	: "";
	(length $wpack	> $Ln[2]) ? ($Ln[2] = length $wpack)	: "";
	(length $fpack	> $Ln[3]) ? ($Ln[3] = length $fpack)	: "";
	(length $calls	> $Ln[4]) ? ($Ln[4] = length $calls)	: "";
	(length $delta	> $Ln[5]) ? ($Ln[5] = length $delta)	: "";
	(length $data	> $Ln[6]) ? ($Ln[6] = length $data)	: "";
	(length $resend	> $Ln[7]) ? ($Ln[7] = length $resend)	: "";
	(length $idle	> $Ln[8]) ? ($Ln[8] = length $idle)	: "";
} # Check_data

sub Header {
    if ($csvmode != 1) {
    	print "\nhh:mm:ss wproc nobufs   wpack  fpack    calls     delta  data      resends  idle\n";
    } else { # assume CSV mode...
    	print "\nhh:mm:ss,wproc,nobufs,wpack,fpack,calls,delta,data,resends,idle\n";
    }
} # Header

#
# don't buffer the output
#
$| = 1;

#
# snag program name (drop the full pathname) :
#
$progName = $0;
$tmpName= "";
GETPROG: while ($letr = chop($progName)) {
	$_ = $letr;
	/\// && last GETPROG;
	$tmpName .= $letr;
}
$progName = reverse($tmpName);

#
# set the defaults for server, port, and delay interval
#
$server	= "";
$port	= 7000;
$delay	= 1200;
$csvmove = 0;

#
# any parms?
#
while ($_ = shift(@ARGV)) {
	GETPARMS: {
		/^-[pP]/ && do {
			$port = shift(@ARGV);
			last GETPARMS;
		};
		/^-[sS]/ && do {
			$server = shift(@ARGV);
			last GETPARMS;
		};
		/^-[tT]/ && do {
			$delay = shift(@ARGV);
			last GETPARMS;
		};
		/^-C/ && do {
			$csvmode = 1;
			last GETPARMS;
		};
		/^-[hH\?]/ && do {
			&Usage();
		};
		/^-/ && do {
			&Usage();
		}
	}
}

#
# if they didn't give us a server name, we can't run
#
if ($server eq "") {
	&Usage();
}
else {
	print "\nServer: $server, Port: $port, Interval $delay seconds\n";
	system date;
}

#
# clear the counters for the first run
#
$wproc	= 0;
$wpack	= 0;
$fpack	= 0;
$calls	= 0;
$data	= 0;
$resend	= 0;
$nobuf	= 0;
$idle	= 0;
$oldcall = 0;

#
# set the default field format lengths for
# wproc,nobuf,wpack,fpack,calls,delta,data,resend,idle
#
@Ln = (5,8,6,8,9,6,9,8,4);

#
# force header display on first call
#
$firstrun = 1;

#
# run until we get cancelled
#
while (1) {
	#
	# show the column headers for every 20 lines of data
	#
    if ($firstrun == 1) {
        Header;
        $firstrun = 0;
    }
	if ($linecnt >= 20) {
        if ($csvmode != 1) {
    		Header;
        }
		$linecnt = 1;
	}
	else {
		$linecnt++;
	}

	#
	# snag the current time
	#
	($sec,$min,$hour,$mday,$month,$year,$wday,$yday,$isDST) = localtime();


	#
	# fire the command and collect the stats
	#

	$rx = rxdebug(servers => $server,
		port => $port,
		rxstats => 1,
		noconns => 1
		);

	# $wpack doesn't seem to have a corresponding value.
        # It is always zero.

	$tstats = $rx->{tstats};

	$wproc = $tstats->{nWaiting};
	$fpack = $tstats->{nFreePackets};
	$calls = $tstats->{callsExecuted};
	if ($oldcall > 0) {
		$delta = $calls - $oldcall;
	}
	else {
		$delta = 0;
	}
	$oldcall = $calls;
	$rxstats = $rx->{rxstats};
	$data = $rxstats->{dataPacketsSent};
	$resend = $rxstats->{dataPacketsReSent};
	$nobuf = $rxstats->{noPacketBuffersOnRead};
	$idle = $tstats->{idleThreads};

	#
	# verify and fix field format lengths
	#
	Check_data;

    if ($csvmode != 1) {
    	#
    	# output the timestamp and current results
    	#
    	printf "%2.2d:%2.2d:%2.2d ", $hour,$min,$sec;
    	printf "%-$Ln[0].0f %-$Ln[1].0f %-$Ln[2].0f %-$Ln[3].0f ",
    		$wproc,$nobuf,$wpack,$fpack;
    	printf "%-$Ln[4].0f %-$Ln[5].0f %-$Ln[6].0f %-$Ln[7].0f %-$Ln[8].0f\n",
    		$calls,$delta,$data,$resend,$idle;
    } else { # must be csv mode then...
    	printf "%2.2d:%2.2d:%2.2d,", $hour,$min,$sec;
    	printf "$wproc,$nobuf,$wpack,$fpack";
    	printf "$calls,$delta,$data,$resend,$idle\n";
    }

  	#
	# delay for the required interval
	#
	sleep($delay);
}

exit();
