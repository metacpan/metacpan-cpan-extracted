#!/usr/bin/perl5
#
# simple_mon - Collect snapshots at one-minute intervals and archive them
#              for off-line analysis.  This assumes ESE - for DPF,
#              you should fork and run one copy per node on each host.
#
#              This is a much simplified version of the real thing.
#              Contact the author for details on the real one, which
#              we cannot open source at this time.
#
#              See the db2_piglist script as an example for off-line
#              analysis.
#
# $Id: simple_mon.pl,v 145.1 2007/08/07 13:28:04 biersma Exp $
#

use strict;
use DB2::Admin;
use Getopt::Long;

our %args = ('scanrate' => 60,
	     'debug'    => 1,
	     'dirname'  => '/var/tmp/db2_monitor',
	    );
GetOptions(\%args, qw(scanrate=i debug!)) ||
  die "Cannot parse \@ARGV\n";


#
# Attach to DB2 and make sure we die on errors and collect the right
# data
#
DB2::Admin::->SetOptions('RaiseError' => 1);
DB2::Admin::->Attach();
print STDERR "Attached to DB2 instance $ENV{DB2INSTANCE}\n" if ($args{debug});
my %switches = ('BufferPool' => 1,
		'Lock'       => 1,
		'Sort'       => 0,
		'Statement'  => 1,
		'Table'      => 0,
		'UnitOfWork' => 0,
		'Timestamp'  => 1, # V8.1+
	       );
DB2::Admin::->SetMonitorSwitches('Switches' => \%switches);


#
# Main loop
#
my $start_time;
while (1) {
    $start_time = time();

    #
    # Collect snapshot of database manager, all databasaes, and all
    # applications and write binary data to disk
    #
    my ($info, $binary) = eval { DB2::Admin::->
	GetSnapshot('Subject' => [ qw(SQLMA_DB2
				      SQLMA_DBASE_ALL
				      SQLMA_APPL_ALL
				     )
				 ]);
			     };
    if ($@) {
	#
	# Following a 'force applications all', we see:
	#
	#   SQL1224N A database agent could not be started to service
	#   a request, or was terminated as a result of a database
	#   system shutdown or a force command.
	#
	if (DB2::Admin::sqlcode() == -1224) {
	    warn "db2mon: Have SQLcode -1224 after instance snapshot, retry\n";
	    next;
	} else {
	    die "Instance snapshot failed [SQLcode: " . DB2::Admin::sqlcode() .
	      "] $@";
	}
    }

    print STDERR "Collected snapshot of size [", length($binary), "]\n"
      if ($args{debug});

    unless (-d $args{dirname}) {
	mkdir($args{dirname}, 0755) ||
	  die "Cannot mkdir $args{dirname}: $!";
    }

    open (ARCHIVE, '>', "$args{dirname}/$start_time.dmp") ||
      die "Cannot open output file $args{dirname}/$start_time.dmp: $!";
    print ARCHIVE $binary;
    close(ARCHIVE);

    #
    # Collect per-database snapshots
    #
    foreach my $node ($info->findNodes('DBASE/DB_NAME')) {
	my $db_name = $node->getValue();
	$db_name =~ s/\s+$//;
	my ($db_info, $db_binary) = eval { DB2::Admin::->
	    GetSnapshot('Subject'  => [ { 'Type'   => 'SQLMA_DBASE',
					  'Object' => $db_name,
					},
					{ 'Type'   => 'SQLMA_DBASE_TABLESPACES',
					  'Object' => $db_name,
					},
					{ 'Type'   => 'SQLMA_DBASE_BUFFERPOOLS',
					  'Object' => $db_name,
					},
				      ]);
				       };
	if ($@) {
	    if (DB2::Admin::sqlcode() == -1224) {
		warn "db2mon: Have SQLcode -1224 after database snapshot for [$db_name], retry\n";
		next;
	    } else {
		die "Database snapshot for [$db_name] failed [SQLcode: " .
		  DB2::Admin::sqlcode() . "] $@";
	    }
	}

	print STDERR "Collected database snapshot for [$db_name] of size [",
	  length($db_binary), "]\n" if ($args{debug});
	if (length $db_binary == 0) {
	    warn "WARNING: database snapshot for [$db_name] is size 0, even though instance snapshot indicates database is active";
	    next;
	}
	my $dirname = "$args{dirname}/$db_name";
	unless (-d $dirname) {
	    mkdir($dirname, 0755) ||
	      die "Cannot mkdir $dirname: $!";
	}

	open (ARCHIVE, '>', "$dirname/$start_time.dmp") ||
	  die "Cannot open output file $dirname/$start_time.dmp: $!";
	print ARCHIVE $db_binary;
	close(ARCHIVE);
    }				# End foreach: database node in snapshot

    #
    # At this point, analyze the snapshots (which you should retain in
    # memory, not as local variables in a loop) and analyze them
    # for critical conditions (tablespace full, blocking, ...)
    #

    #
    # In addition, either this script, or the off-line analyzer,
    # should clean up files older than a certain time - say, two to
    # eight hours.
    #
} continue {
    #
    # Sleep until next run
    #
    my $now  = time();
    my $cost = $now - $start_time;
    my $next = $start_time + $args{'scanrate'};
    if ($now > $next) {
	warn "Run took longer than scanrate - '$cost' seconds for pollrate '$args{scanrate}'\n";
    } else {
	my $sleeptime = $next - $now;
	print STDERR "Will sleep $sleeptime seconds\n" if ($args{debug});
	sleep($sleeptime);
    }
}
exit(0);			# NOTREACHED
