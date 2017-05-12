#!/usr/bin/perl5
#
# db2_check_lock - Check for blocked applications, optionally kill
#
# $Id: db2_check_lock.pl,v 145.1 2007/11/20 21:51:24 biersma Exp $
#

use strict;
use Carp;
use DB2::Admin;
use Getopt::Std;
use Pod::Usage;
use Socket;
use Text::FormatTable;


$| = 1;
my %args = ('t' => 120);
my @orig_argv = @ARGV;
getopts("D:t:k:d", \%args) || pod2usage();

#
# Collect a database snapshot.  We need the following information:
# - Applications
# - Application info
#
DB2::Admin::->SetOptions('RaiseError' => 1);
DB2::Admin::->Attach();
DB2::Admin::->SetMonitorSwitches('Switches' => { Lock      => 1,
						 Statement => 1,
					       });
my $snap = DB2::Admin::->
  GetSnapshot('Subject' => [ qw(SQLMA_DBASE_ALL
				SQLMA_APPL_ALL
			       )
			   ],
	      'Node' => 'SQLM_ALL_NODES', # V8 or higher
	     );
unless (defined $snap) {
    print "No active databases. Nothing to do.\n";
    exit(0);
}

my %agent_ids;			# Agent Id -> Appl node
my %blocked_apps;		# Agent Id -> Agent Id (blocked -> lock owner)
my $no_long_blocked = 0;	# No of jobs blocked for > block time
my $now = time();
foreach my $node ($snap->findNodes('APPL')) {
    #print $node->Format(); exit(0);

    #
    # Implement filtering on -D
    #
    my $db_name = $node->findValue('APPL_INFO/DB_NAME');
    $db_name =~ s/\s+$//;
    next if (defined $args{D} && lc $args{D} ne lc $db_name);

    my $agent_id = $node->findValue('APPL_INFO/AGENT_ID');
    $agent_ids{$agent_id} = $node;

    my $is_blocked = $node->findValue('LOCKS_WAITING');
    next unless ($is_blocked);
    my $blocker = $node->findValue('LOCK_WAIT/AGENT_ID_HOLDING_LK');
    $blocked_apps{$agent_id} = $blocker;

    my $start = $node->findValue('LOCK_WAIT/LOCK_WAIT_START_TIME/SECONDS');
    if (($now - $start) > $args{t}) {
	$no_long_blocked++;
    }
}

if ($args{k}) {
    my $agent_id = $args{k};
    unless (defined $agent_id) {
	warn "Invalid '-kill $agent_id' - application is not (no longer) active\n";
	exit(1);
    }
    my $appl_node = $agent_ids{$agent_id};
    my $locks_held = $appl_node->findValue('LOCKS_HELD');
    unless ($locks_held) {
	warn "Invalid '-kill $agent_id' - application does not hold any locks\n";
	exit(1);
    }

    print "Killing application with agent id $agent_id\n";
    my $db_name = $appl_node->findValue('APPL_INFO/DB_NAME');
    DB2::Admin::->ForceApplications($agent_id);
    exit(0);
}

unless ($no_long_blocked) {
    print "No applications are blocked for over $args{t} seconds\n";
    exit(0);
}

if (0) {
    #
    # Fake a tree
    #
    $blocked_apps{4} = 5;
    $blocked_apps{5} = 6;
    $blocked_apps{6} = 8;
    $blocked_apps{7} = 8;
    #  $blocked_apps{8} = 5; # Deadlock
}

#
# See if we can compute a blocking tree
#
my %lock_owner;			# Blocked -> Final lock owner
my %lock_children;		# Lock owner -> Child -> 1
BLOCKED:
foreach my $agent_id (keys %blocked_apps) {
    my $blocker = $blocked_apps{$agent_id};
    my $parent = $blocked_apps{$blocker};
    if (defined $parent) {
	#print "Have lock hierarchy: $agent_id -> $blocker -> $parent\n";
	while (defined $blocked_apps{$parent}) {
	    if ($parent == $blocker) {
		print "Deadlock detected ($agent_id -> $blocker ... $blocker)\n";
		next BLOCKED;
	    }
	    $parent = $blocked_apps{$parent};
	}
	$lock_owner{$agent_id} = $parent;
	$lock_children{$parent}{$agent_id} = 1;
    } else {
	$lock_owner{$agent_id} = $blocker;
	$lock_children{$blocker}{$agent_id} = 1;
    }
}
print STDERR "Have lock owners [", join(',', sort keys %lock_children), "]\n"
  if ($args{d});
foreach my $agent_id (sort { $a <=> $b } keys %lock_children) {
    print STDERR "Lock owner [$agent_id] is blocking [",
      scalar(keys %{ $lock_children{$agent_id} }), "] apps\n"
	if ($args{d});
}

#
# Get a detailed snapshot (locks held) for each of the applications
# that is blocking others.
#
my %lock_ids = map { ($_, 1) } keys %lock_children;
my @subject;
foreach my $id (keys %lock_ids) {
    push @subject, { 'Type'    => 'SQLMA_APPL_LOCKS_AGENT_ID',
		     'AgentId' => $id,
		   };
}
my $lock_snap = DB2::Admin::->
  GetSnapshot('Subject' => \@subject,
	      'Node' => 'SQLM_ALL_NODES', # V8 or higher
	     );
unless (defined $lock_snap) {
    die "Cannot get application-level lock snapshot for agent ids " .
      join(', ', keys %lock_ids), "\n";
}
my $snap_time = $lock_snap->findValue('TIME_STAMP/SECONDS');

my %appl_locks;			# Agent id -> Lock info
foreach my $node ($lock_snap->findNodes('APPL_LOCK_LIST')) {
    my $agent_id = $node->findValue('AGENT_ID');
    $appl_locks{$agent_id} = $node;
}
print STDERR "Have lock info for [" . join(',', keys %appl_locks) . "]\n"
  if ($args{d});
foreach my $lock_owner (keys %appl_locks) {
    generate_lock_alert($lock_owner);
}
exit(0);

# ------------------------------------------------------------------------

#
# Generate the lock alert text for a single lock holder.
# We send this by mail - YMMV
#
sub generate_lock_alert {
    my ($lock_owner) = @_;
    print STDERR "Generate alert for [$lock_owner]\n"
      if ($args{d});

    my $owner_node = $agent_ids{$lock_owner};
    my $no_blocked = keys %{ $lock_children{$lock_owner} };

    #
    # Alert should look like: Error: Server NYPIBA4 agent id 71 has been
    # blocking X applications since Aug 17 2004 2:00AM
    #
    my $since;
    foreach my $blocked (keys %{ $lock_children{$lock_owner} }) {
	my $appl_node = $agent_ids{$blocked};
	my $start = $appl_node->findValue('LOCK_WAIT/LOCK_WAIT_START_TIME/SECONDS');
	#print "Have [$blocked] lock wait start time [$start] [" . localtime($start) . "]\n";
	if (! defined $since || $start < $since) {
	    $since = $start;
	}
    }
    my @time_elems = localtime($since);
    my $display_time = sprintf("%4d/%02d/%02d %02d:%02d",
			       $time_elems[5] + 1900,
			       $time_elems[4] + 1,
			       $time_elems[3],
			       $time_elems[2],
			       $time_elems[1]);
    my $alert = "Server $ENV{DB2INSTANCE} agent id $lock_owner has been blocking $no_blocked applications since $display_time";

    my $now = localtime(time);
    my $dbname = $owner_node->findValue('APPL_INFO/DB_NAME');
    $dbname =~ s/\s+$//;

    my @descendants = keys %{ $lock_children{$lock_owner} };
    my @direct_children;
    foreach my $id (@descendants) {
	next unless ($blocked_apps{$id} == $lock_owner);
	push @direct_children, $id;
    }
    my %blocked_tables;
    my %schema_names;
    foreach my $id (@direct_children) {
	my $node = $agent_ids{$id};
	foreach my $wl ($node->findNodes('LOCK_WAIT')) {
	    my $schema = $wl->findValue('TABLE_SCHEMA');
	    $schema =~ s/\s+$//;
	    $schema_names{$schema} = 1;
	    my $table = $wl->findValue('TABLE_NAME');
	    $table =~ s/\s+$//;
	    $blocked_tables{"$schema.$table"} = 1;
	}
    }
    my $table_list = join(', ', sort keys %blocked_tables);

    my $desc = "$ENV{DB2INSTANCE}.$dbname";

    my $email = <<_END_HEADER_;
Please be advised that there is blocking in $desc.
The blocking is caused by agent id $lock_owner in the table(s) $table_list.
Please deal with the blocking process so that other processing
may continue.

Thank You.

_END_HEADER_
  ;

    $email .= "The blocking process:\n";
    $email .= '#' x 20 . "\n";
    $email .= display_agents($lock_owner);
    $email .= "\n";

    $email .= "Locks held by the blocking process:\n";
    $email .= '#' x 20 . "\n";
    $email .= display_agent_locks($lock_owner);
    $email .= "\n";

    #
    # Get SQL and display if any found
    #
    my $sql_text = $owner_node->findValue('STMT/STMT_TEXT');
    if (defined $sql_text && $sql_text =~ /\S/) {
	$email .= "Offending SQL of the blocking process:\n";
	$email .= '#' x 20 . "\n";
	$email .= "SQL Text: $sql_text\n";
	$email .= "\n";
    }

    $email .= "Host name and pid of the blocking process:\n";
    $email .= '#' x 20 . "\n";
    $email .= display_client_info($lock_owner);
    $email .= "\n";

    $email .= "For an explanation of the status column, go to:\n";
    $email .= "http://publib.boulder.ibm.com/infocenter/db2help/topic/com.ibm.db2.udb.doc/admin/r0001162.htm\n";
    $email .= "\n";

    #
    # Show at most 10 blocked processes
    #
    if (@descendants > 10) {
	$email .= "There are " . scalar(@descendants) . " processes being blocked\n";
	$email .= "The first 10 blocked processes are listed below\n";
	$email .= '#' x 20 . "\n";
	$email .= display_agents(@descendants[0..9]);
	$email .= "\n";
    } else {
	$email .= "The following processes are being blocked:\n";
	$email .= '#' x 20 . "\n";
	$email .= display_agents(@descendants);
	$email .= "\n";
    }

    #
    # Fire off mail - you'll have to adjust this
    #
    print "Generated the following output:\n\n$email\n";

    return;
}


#
# Display application information for a list of agent ids.
#
sub display_agents {
    my (@ids) = @_;

    my $table = Text::FormatTable->new('r l l l l r l r');
    $table->head('id', 'login', 'cmd', "program_name", 'hostname',
		 "host_pid", "status", "blocktime");
    $table->rule('-');

    foreach my $id (@ids) {
	my $appl_node = $agent_ids{$id};
	my $appl_info = $appl_node->findNode('APPL_INFO');
	my $values = $appl_info->getValues();
	my $userid = lc ($values->{'PRIMARY_AUTH_ID'} || # V8
			 $values->{'AUTH_ID'}); # V7
	#my $login = $values->{'EXECUTION_ID'};
	my $cmd = $appl_node->findValue('STMT/STMT_TEXT');
	if (defined $cmd) {
	    $cmd =~ s/^\s*(\S+).*/$1/;
	} else {
	    $cmd = 'n/a';
	}
	my $program = $values->{'APPL_NAME'};
	my $hostname = $values->{'CLIENT_NNAME'};
	unless (defined $hostname && $hostname =~ /\S/) {
	    my ($ip_addr) = ($values->{'APPL_ID'} =~ /^(\S+) port /);
	    my $host = gethostbyaddr(inet_aton($ip_addr), AF_INET);
	    $hostname = $host || $ip_addr;
	}
	my $hostproc = $values->{'CLIENT_PID'};
	my $status = $values->{'APPL_STATUS'};
	my $block_start = $appl_node->
          findValue('LOCK_WAIT/LOCK_WAIT_START_TIME/SECONDS');
	my $time_blocked = (defined $block_start ?
			    $snap_time - $block_start : 'n/a');

	#
	# For multi-tier apps, add the TP Monitor information if
	# available.
	#
	if ($values->{TPMON_CLIENT_USERID} =~ /\S/) {
	    $userid .= " (for $values->{TPMON_CLIENT_USERID})";
	}
	if ($values->{TPMON_CLIENT_WKSTN} =~ /\S/) {
	    $hostname .= " (for $values->{TPMON_CLIENT_WKSTN})";
	}
	if ($values->{TPMON_CLIENT_APP} =~ /\S/) {
	    $program .= " (for $values->{TPMON_CLIENT_APP})";
	}

	$table->row($id, $userid, $cmd, $program, $hostname,
		    $hostproc, $status, $time_blocked);
    }

    return $table->render(120);
}


#
# Display locks for a single agent id
#
sub display_agent_locks  {
    my ($id) = @_;


    my $lock_list = $appl_locks{$id};
    my %tbs_locks;		# Tablespace -> Count
    my %obj_locks;		# Type -> Schema -> Table -> Count
    foreach my $lock_node ($lock_list->findNodes('LOCK')) {
	my $table_name = $lock_node->findValue('TABLE_NAME');
	my $schema_name = $lock_node->findValue('TABLE_SCHEMA');
	my $lock_type = $lock_node->findValue('LOCK_OBJECT_TYPE');
	if (defined $table_name && defined $schema_name) {
	    $obj_locks{$lock_type}{$schema_name}{$table_name}++;
	} elsif ($lock_type eq 'SQLM_TABLESPACE_LOCK') {
	    my $tbs_name = $lock_node->findValue('TABLESPACE_NAME');
	    $tbs_locks{$tbs_name}++;
	}
    }

    my $retval = '';

    #
    # Tablespace level locks
    #
    if (keys %tbs_locks) {
	my $table = Text::FormatTable->new('l  l  l  r');
	$table->head('lock_type', 'tablespace', '#locks');
	$table->rule('-');
	foreach my $type (sort keys %tbs_locks) { # Just tbspace for now
	    my @rows;
	    while (my ($tbs, $count) = each %{ $tbs_locks{$type} }) {
		push @rows, [ $count, $tbs ];
	    }
	    @rows = sort { $b->[0] <=> $a->[0] ||
			   $a->[1] cmp $b->[1]
			 } @rows;
	    foreach my $row (@rows) {
		$table->row($type, $row->[1], $row->[0]);
	    }
	}
	$retval .= $table->render();
    }

    #
    # Object level locks (table, row)
    #
    if (keys %obj_locks) {
	my $table = Text::FormatTable->new('l  l  l  r');
	$table->head('lock_type', 'table_name', 'schema_name', '#locks');
	$table->rule('-');
	foreach my $type (reverse sort keys %obj_locks) { # Table before row
	    my @rows;
	    while (my ($schema, $l2) = each %{ $obj_locks{$type} }) {
		while (my ($table, $count) = each %$l2) {
		    push @rows, [ $count, $schema, $table ];
		}
	    }
	    @rows = sort { $b->[0] <=> $a->[0] ||
			   $a->[2] cmp $b->[2] ||
			   $a->[1] cmp $b->[1]
			 } @rows;
	    foreach my $row (@rows) {
		$table->row($type, $row->[2], $row->[1], $row->[0]);
	    }
	}
	if ($retval) {
	    $retval .= "\n\n";
	}
	$retval .= $table->render();
    }

    return $retval;
}


#
# Display information on remote client
#
sub display_client_info {
    my ($id) = @_;

    my $appl_node = $agent_ids{$id};
    my $node_name = $appl_node->findValue('APPL_INFO/CLIENT_NNAME');
    my $appl_id = $appl_node->findValue('APPL_INFO/APPL_ID');
    my ($ip_addr, $port) = ($appl_id =~ /^(\S+) port (\d+)/);
    $port ||= '<unknown>';
    unless ($node_name) {
	my $hostname = gethostbyaddr(inet_aton($ip_addr), AF_INET);
	$node_name = $hostname || $ip_addr;
    }
    my $host_pid = $appl_node->findValue('APPL_INFO/CLIENT_PID');

    my $table = Text::FormatTable->new('r  l  l');
    $table->head('agent_id', 'hostname:socket', "hostprocess");
    $table->rule('-');
    $table->row($id, "$node_name:$port", $host_pid);
    return $table->render();
}


__END__

=head1 NAME

db2_check_lock -- Check database blocking and generate alert email

=head1 SYNOPSIS

  db2_check_lock [ -D<database> ]
                 [ -k<agent id> ]
                 [ -t<block time> ]
                 [ -d ]

=head1 DESCRIPTION

This script performs a database instance snapshot to determine
blocking.  If any agent process is blocked for over a specified time,
an email is generated with information on the blocking process and its
victims. Optionally, the blocking agent process can be killed.  This
script must be run on the database server.

This script first gets an application snapshot with basic locking
information.  If the C<-k> parameter is specified, the script verifies
whather the specified agent id still exists and still is holding a
lock. If so, the application is forced.

In the absence of a C<-k> parameter, the script verifies whether any
applications is blocked for over the specified time (taken from the
JobParams table, defaulting to 120 seconds). If not, the script takes
no action.

If there is long blocking, the script find the responsible agent
process by following the lock chain.  For each responsible agent, an
email is generated that lists the agent, the locks it holds, the
responsible SQL statement, client process information, plus a list of
the victim processes.

=head1 OPTIONS

This script takes the following command-line options:

=head2 -D'database'

The physical database name.  This optional parameter is used to
restrict the check to just that one database.

=head2 -k'agent id'

The agent id to kill (actually, force).  In order to prevent
accidents, the script verifies this agent id is actually holding a
lock.

=head2 -t'block time in seconds'

In the absence of C<-k>, this script only generates email if blocking
exceeds a specified time.  The default is 120 seconds.

=head2 -d

Enable debugging (verbose output).

=cut
