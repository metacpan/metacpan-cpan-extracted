package Cisco::Accounting;

## ----------------------------------------------------------------------------------------------
## Cisco::Accounting
##
## Cisco and IPCAD ip accounting parser and aggregator
##
## $Id: Accounting.pm 125 2007-08-18 22:10:25Z mwallraf $
## $Author: mwallraf $
## $Date: 2007-08-19 00:10:25 +0200 (Sun, 19 Aug 2007) $
##
## This program is free software; you can redistribute it and/or
## modify it under the same terms as Perl itself.
## ----------------------------------------------------------------------------------------------


our $VERSION = '1.01';

use warnings;
use strict;
use Carp;
#use Data::Dumper; ## for debugging only

require 5.002;

use Net::Telnet::Wrapper;

use Cisco::Accounting::Interface;	## object that represents a single interface
use Cisco::Accounting::Data;		## object that represents the parsed accounting data



sub new()  {
	my ($this, %parms) = @_;
	my  $class = ref($this) || $this;
	my  $self = {};	
	
	$self->{'session'} = '';	# this will contain our session to Net::Telnet::Wrapper
	
	$self->{'host'} = $parms{'host'} || "";		# router to connect to
	$self->{'user'} = $parms{'user'} || "";		# login username
	$self->{'pwd'} = $parms{'pwd'} || "";		# login password
	$self->{'tacacs'} = $parms{'tacacs'} || "";		# tacacs password
	$self->{'enable_user'} = $parms{'enable_user'} || "";	# enable username
	$self->{'enable_pwd'} = $parms{'enable_pwd'} || "";	# enable password
	$self->{'persistent'} = (defined($parms{'persistent'}))?($parms{'persistent'}):(1);	# if enabled then we don't close any sessions unless close() is called
	$self->{'lastpoll_details'} = $parms{'lastpoll_details'} || 0;
	
	$self->{'interfaces'} = [];	# array of Cisco::Accounting::Interface objects	
	$self->{'data'} = '';		# this will contain the output (Cisco::Accounting::Data object)
	$self->{'lastpoll_data'} = '';
	
	$self->{'acct_type'} = $parms{'acct_type'} || "cisco";	# "cisco" ip accounting, "ipcad" is also -limited- supported
	$self->{'keep_history'} = (defined($parms{'keep_history'}))?($parms{'keep_history'}):(1);	# keep summarized historical data for each poll
	
	$self->{'telnet_options'} = $parms{'telnet_options'};
	
	bless($self, $class);
	&_init($class);
	return($self);
}


# initialization
sub _init  {
	my $class=shift;
}


##
## fetch all interfaces on a cisco device that support ip accounting
## returns array of Cisco::Accounting::Interface objects
## this procedured should be used with eval {}
##
sub get_interfaces()  {
	my ($self) = shift;
	
	my $disconnect;
	my @interfaces;	# resulting array of Cisco::Accounting::Interface objects
	
	eval {
		if (!$self->{'session'})  {
			$disconnect = 1;
			## make a connection to the device
			$self->_connect();
		}
	
		## get the interface information
		if ($self->{'acct_type'} =~ /cisco/i)  {
			my @result = $self->{'session'}->cmd("show ip int");
			@interfaces = &_parse_cisco_interfaces(\@result) if (scalar @result);
		}
		elsif ($self->{'acct_type'} =~ /ipcad/i)  {
			my @result = $self->{'session'}->cmd("rsh localhost stat");
			@interfaces = &_parse_ipcad_interfaces(\@result) if (scalar @result);
		}
	
		## close the connection again
		if ( ($disconnect > 0) && ($self->{'persistent'} <= 0) )  {
			$self->_disconnect();
		}
	};
	if ($@)  {
		croak $@;
	}
	
	@{$self->{'interfaces'}} = @interfaces;
	
	return @{$self->{'interfaces'}};
}


##
## Disable ip accounting on one or more interfaces
## parameters = array of interface id's as known in $self->{'interfaces'}
## ** this assumes you've run get_interfaces first ! **
## ** this assumes that you have enough rights to go to config mode **
##
sub enable_accounting()  {
	my ($self) = shift;
	my (@int_id) = @_;
	
	$self->_modify_accounting_settings(1, @int_id);
}


##
## Disable ip accounting on one or more interfaces
## parameters = array of interface id's as known in $self->{'interfaces'}
## ** this assumes you've run get_interfaces first ! **
## ** this assumes that you have enough rights to go to config mode **
##
sub disable_accounting()  {
	my ($self) = shift;
	my (@int_id) = @_;
	
	$self->_modify_accounting_settings(0, @int_id);
}



##
## parse output of 1 poll (show ip accounting) and update $self->{'data'}
## returns the reference to the output
## this procedure should be used with eval{}
##
sub do_accounting()  {
	my ($self) = shift;

	my (@output);
	my $disconnect = 0;

	# if the connection is not yet active then we assume that it has to be closed again 
	if (!$self->{'session'})  {
		$disconnect = 1;
		eval {
			$self->_connect();
		};
		if ($@)  {
			croak $@;
		}
	}

	eval {
		if ($self->{'acct_type'} =~ /cisco/i)  {
			@output = $self->{'session'}->cmd("show ip accounting");
		}
		elsif ($self->{'acct_type'} =~ /ipcad/i)  {
			@output = $self->{'session'}->cmd("rsh localhost show ip accounting");
		}
	};
	if ($@) {
		## if this failed we assume that our connection was lost
		$self->{'session'} = '';
		croak $@;
	}
	

	## create a new Cisco::Accounting::Data object if needed
	if (!$self->{'data'})  {
		$self->{'data'} = Cisco::Accounting::Data->new('keep_history' => $self->{'keep_history'});
	}
	$self->{'data'}->parse(\@output);

	## check if we need to store lastpoll_data details
	if ($self->{'lastpoll_details'} > 0)  {
		$self->{'lastpoll_data'} = Cisco::Accounting::Data->new('keep_history' => 0);
		$self->{'lastpoll_data'}->parse(\@output);
	}

	if ( ($disconnect > 0) && ($self->{'persistent'} <= 0) )  {
		$self->_disconnect();
	}
	
	return $self->{'data'}->get_data();
}


##
## returns a reference to the output
##
sub get_output()  {
	my ($self) = shift;
	
	if ($self->{'data'})  {
		return $self->{'data'}->get_data();
	}
	else  {
		return 0;
	}
}


##
## returns a reference to the output
##
sub get_lastpoll_output()  {
	my ($self) = shift;
	
	if ($self->{'lastpoll_data'})  {
		return $self->{'lastpoll_data'}->get_data();
	}
	else  {
		return 0;
	}
}

##
## return reference to hash with polling statistics
##
sub get_statistics()  {
	my ($self) = shift;
	
	if ($self->{'data'})  {
		return	$self->{'data'}->get_stats();
	}
	else  {
		return 0;
	}
}


##
## return reference to hash with polling statistics
##
sub get_history()  {
	my ($self) = shift;
	
	if ($self->{'data'})  {
		return	$self->{'data'}->get_history();
	}
	else  {
		return 0;
	}
}

##
## clears the output buffer
##
sub clear_output()  {
	my ($self) = shift;
	
	$self->{'data'} = '';
}


##
## clears ip accounting information on the remote device
## this procedure should be used with eval {}
##
sub clear_accounting()  {
	my ($self) = shift;
	
	my $disconnect = 0;
	
	# if the connection is not yet active then we assume that it has to be closed again 
	if (!$self->{'session'})  {
		$disconnect = 1;
		eval {
			$self->_connect();
		};
		if ($@)  {
			croak $@;
		}
	}
	
	eval {
		if ($self->{'acct_type'} =~ /cisco/i)  {
			$self->{'session'}->cmd('clear ip accounting');
		}
		elsif ($self->{'acct_type'} =~ /ipcad/i)  {
			my @output = $self->{'session'}->cmd("rsh localhost clear ip accounting");
			if (  grep { $_ =~ /permission denied/i } @output)  {
				croak "cannot clear ip accounting : permission denied";
			}
		}
	};
	if ($@) {
		croak $@;
	}
	
	if ( ($disconnect > 0) && ($self->{'persistent'} <= 0) )  {
		$self->_disconnect();
	}
}


##
## Send a keepalive (new line character), do not do any error checking here
## Useful if 'persistent' is enabled, but still it's up to you to call the keepalive in time before session times out
##
sub keepalive()  {
	my ($self) = shift;
	
	if ($self->{'session'})  {
		eval  {
			$self->{'session'}->cmd(" ");
		};
	}
}




### TODO: do not go to config mode unless really needed

##
## Enable (1) or Disable (0) ip accounting depending on $status
##
sub _modify_accounting_settings()  {
	my ($self) = shift;
	my ($status) = shift;
	my (@int_id) = @_;
	
	## IPCAD interfaces are always enabled
	if ($self->{'acct_type'} =~ /ipcad/i)  {
		## nothing to do
		return;
	}
	
	## first check if we need to do something
	next unless ((scalar @int_id) > 0);
	next unless ((scalar @{$self->{'interfaces'}}) > 0);

	my $disconnect = 0;
	my ($id, $int);
	
	# if the connection is not yet active then we assume that it has to be closed again 
	if (!$self->{'session'})  {
		$disconnect = 1;
		eval {
			$self->_connect();
		};
		if ($@)  {
			croak $@;
		}
	}
	
	eval {
		if ($self->{'acct_type'} =~ /cisco/i)  {
			## go to config mode
			$self->{'session'}->config();	
			foreach $int (@{$self->{'interfaces'}})  {
				## only enable/disable ip accounting if needed
				if ((grep { $int->get_id() =~ /^$_$/}  @int_id) && ($int->get_accounting_status() != $status))  {
					$self->{'session'}->cmd('interface '.$int->get_interface());
					my $set_no = "";
					$set_no = "no" unless ($status > 0);
					$self->{'session'}->cmd("$set_no ip accounting output-packets");
					$self->{'session'}->cmd('exit');
					# change the interface status
					$int->set_accounting_status($status);
				}
			}
			## quit config mode
			$self->{'session'}->cmd('exit');
		}
	};
	if ($@) {
		croak $@;
	}
	
	if ( ($disconnect > 0) && ($self->{'persistent'} <= 0) )  {
		$self->_disconnect();
	}	
}


##
## open a new telnet connection, login and save session in $self->{'session'}
##
sub _connect()  {
	my ($self) = shift;
	
	my $device_class;
	my $enable = 1;
	
	if ($self->{'acct_type'} =~ /cisco/i)  {
		$device_class = "Cisco::IOS";
		$enable = 1;
	}
	elsif ($self->{'acct_type'} =~ /ipcad/i)  {
		$device_class = "Unix::General";
		$enable = 0;
	}
	
	## open a new connection
	eval {
		$self->{'session'} = Net::Telnet::Wrapper->new('device_class' => $device_class, -host => $self->{'host'}, %{$self->{'telnet_options'}});
	};
	if ($@)  {
		$self->{'session'} = '';
		croak "Unable to connect to device ".$self->{'host'};
	}
	
	## login to enable mode
	eval {
		$self->{'session'}->login( 'name' => $self->{'user'}, 'passwd' => $self->{'pwd'}, 'Passcode' => $self->{'passcode'});
		if ($enable)  {
			$self->{'session'}->enable( 'name' => $self->{'enable_user'}, 'passwd' => $self->{'enable_pwd'}, 'Passcode' => $self->{'passcode'});
		}
	};
	if ($@)  {
		croak "Unable to login to device ".$self->{'host'};
	}
}


##
## close telnet connection, remove session from $self->{'session'}
##
sub _disconnect()  {
	my ($self) = shift;
	
	return unless ($self->{'session'});
	
	eval {
		$self->Quit();
	};
	
	$self->{'session'} = '';
}



##
## fetch all interfaces on a cisco device that support ip accounting
## returns array of Cisco::Accounting::Interface objects
##
sub _parse_cisco_interfaces()  {
	my ($interfaces) = shift;
	
	my ($int);
	my (@result);
	my ($current_int);
	my ($current_enabled);
	my ($id) = 0;
	
	foreach $int (@{$interfaces})  {
		$int =~ s/\n//;
		
		# new interface found, only fetch interfaces that support ip accounting
		if ($int =~ /^(\S+)/)  {
			$current_int = $1;
		}
		elsif ($int =~ /IP output packet accounting is/i)  {
			if ($int =~ /enabled/i)  {
				$current_enabled = 1;
			}
			else  {
				$current_enabled = 0;
			}
			
			my $interface = Cisco::Accounting::Interface->new($id, $current_int, $current_enabled);
			push(@result, $interface);
			$id++;
			$current_int = "";
			$current_enabled = "";
		}
	}
	
	return @result;
}



##
## fetch all interfaces from a host running IPCAD
## returns array of Cisco::Accounting::Interface objects
##
sub _parse_ipcad_interfaces()  {
	my ($interfaces) = shift;

	my ($int);
	my (@result);
	my ($current_int);
	my ($current_enabled);
	my ($id) = 0;

	foreach $int (@{$interfaces})  {
		$int =~ s/\n//;

		# new interface found, these interfaces ALWAYS have ip accounting enabled ??  TODO: need to verify this
		if ($int =~ /Interface (.*):/i)  {
			$current_int = $1;
			$current_enabled = 1;
			
			my $interface = Cisco::Accounting::Interface->new($id, $current_int, $current_enabled);
			push (@result, $interface);
			$id++;
			$current_int = "";
			$current_enabled = "";
		}
	}
	
	return @result;
}

1;  # End of Cisco::Accounting


__END__

=head1 NAME

Cisco::Accounting - Cisco and IPCAD ip accounting parser and aggregator

=head1 VERSION

version 1.01

=head1 SYNOPSIS

	use Cisco::Accounting;
	use Data::Dumper;

	## make a new Cisco::Accounting object
	eval {  
		$acct = Cisco::Accounting->new(%data);	
	};

	## get list of interfaces on remote host
	## enable ip accounting on interfaces 1 and 2 (indexes are found with get_interfaces())
	## disable ip accounting on interface 2
	eval {  
		@interfaces = $acct->get_interfaces();
		print &Dumper(\@interfaces);
		$acct->enable_accounting(2,1);  
		#$acct->disable_accounting(2);
	};

	## fetch ip accounting from a remote device and clear ip accounting afterwards
	eval {
		$acct->do_accounting();
		$acct->clear_accounting();
	};

	## get the aggregated output, the overall statistics and the historical summarized data
	$output = $acct->get_output();
	$stats = $acct->get_statistics();
	$historical = $acct->get_history();

	print &Dumper($stats);
	print &Dumper($output);
	print &Dumper($historical);	

=head1 DESCRIPTION

The B<Cisco::Accounting> module parses and aggregates the output of 'show ip accounting' data on B<Cisco routers> and also on hosts running B<IPCAD>.

Every time the 'show ip accounting' output is parsed for a specific host the information is being aggregated and stored in a hash. 
General statistics and historical summarized data is also being stored.

The module connects to a remote device and retrieves a complete list of interfaces on that device. It is possible to automatically
enable or disable IP Accounting on one or more interfaces at once using Cisco::Accounting.

Use this module if you quickly want to fetch IP accounting information for a short period or if you want to report IP Accounting data 
for a long period.

B<CIPAT> is a front-end application for Cisco::Accounting that also has reporting features. CIPAT is available on L<http:E<sol>E<sol>www.sourceforge.netE<sol>projectsE<sol>cipat>

More information about IPCAD can be found at L<http:E<sol>E<sol>lionet.infoE<sol>ipcad>

=head1 PROCEDURES

=over 4

=item new() - constructor

This is the constructor.

	my $acct = new Cisco::Accounting(	
										'host'			=>	$host,			[required]
										'user'			=>	$user,			[optional]
										'pwd'			=>	$password,		[optional]
										'tacacs'		=>	$tacacs,		[optional]
										'enable_user'	=>	$enable_user,	[optional]
										'enable_pwd'	=>	$enable_pwd,	[optional]
										'persistent'	=>	0 | 1,			[default = 1]
										'acct_type'		=>	cisco | ipcad,	[default = cisco]
										'keep_history'	=>	Ø | 1,			[default = 1]
										'lastpoll_details'	=>	0 | 1,			[default = 0]
										'telnet_options'	=>	{ Net::Telnet options }
									);

This creates a new Cisco::Accounting object.

Parameters :

	host			router or host that we need to connect to (via telnet only)
	user			default username (if required)
	pwd				default password (if required)
	tacacs			tacacs password (if required)
	enable_user		enable username (if required - for routers only)
	enable_pwd		enable password (if required - for routers only)
	persistent		if enabled then try to keep the telnet session open until close() is called
					if disabled then connection is closed after each 'transaction'
	acct_type		either 'cisco' or 'ipcad' depending if host is a Cisco router or host with IPCAD
	keep_history	if enabled then we keep a summarized history of each time 'show ip accounting' was parsed
					if disabled no history info is kept, to save memory if we're polling for a long period
	lastpoll_details	if enabled then we also keep the detailed, non-summarized, data of the last poll.
						can be useful if you're polling many times and want to have the summarized data in the end
						but also the details for each separate poll
	telnet_options	add additional default Net::Telnet options to this hash

=item clear_accounting()

Clears the IP accounting table on a Cisco router or IPCAD host. This sends 'clear ip accounting' to the host.
For IPCAD hosts : make sure that you have sufficient rights to do this, by default this is not enabled for normal user
accounts.

	$acct->clear_accounting()

=item clear_output()

This clears the statistcs that were gathered so far. This has the same effect as closing the object and creating a new one
except that we don't have to close the telnet session.

	$acct->clear_output();

=item disable_accounting(@interfaces)

Disable IP accounting on one or more interfaces. This can only be done on Cisco routers, not on IPCAD hosts.
It has the same effect as configuring 'no ip accounting output-packets' on a router interface.

You need to be able to go to config mode on the router !

	$acct->disable_accounting(1,3,6);

Parameters :

	@interfaces		An array of interface indices, the index can be retrieved with get_interfaces()

=item do_accounting()

This actually retrieves the IP accounting data from a Cisco router or IPCAD host. The data is being parsed and aggregated in the output
buffer. This procedure can be called as many times as you want during the lifetime of the Cisco::Accounting object, each time it's called
the new data will be aggregated with the old data.

	$rc = $acct->do_accounting();

Return value :

	$rc		this is a reference to the output buffer, same result as get_output()

=item enable_accounting(@interfaces)

Enable IP accounting on one or more interfaces. This can only be done on Cisco routers, not on IPCAD hosts.
It has the same effect as configuring 'ip accounting output-packets' on a router interface.

You need to be able to go to config mode on the router !

	$acct->enable_accounting(1,3,6)

Parameters :

	@interfaces		An array of interface indices, the index can be retrieved with get_interfaces()

=item get_history()

Returns a reference to a hash of summarized historical information. For each time that we've polled the IP accounting data using
do_accounting() an entry is stored with the timestamp of that poll and the total bytes, packets, host pairs during that poll.
If for example you would call do_accounting() every 5 minutes for one hour then the hash would contain 12 elements.

	$history = $acct->get_history();

Return value :

$history		Reference to hash that contains 	'timestamp' =>	{
																		'totalBytes'	=>	'',
																		'totalPackets'	=>	'',
																		'hostPairs'		=>	'',
																	}

=item get_interfaces()

Get a list of all interfaces of the Cisco router or IPCAD device and the status if IP accounting is already enabled or not.
The list contains references to Cisco::Accounting::Interface objects.

	@interfaces = $acct->get_interfaces()

Return value = 

@interfaces		array of Cisco::Accounting::Interface objects, one object for each interface found
				The Interface object contains the unique id, used in enable_accounting() and disable_accounting() as well as
				the name (ex. FastEthernet0/0) and if IP accounting is already enabled or not.
				See perldoc of Cisco::Accounting::Interface for more information

=item get_lastpoll_output()

Returns a hash containing the detailed, not aggregated, data of the very last poll.
This contains only data if the Cisco::Accounting was created with the 'lastpoll_data => 1' option.

This output can be useful if you're polling many times and you are interested in the summarized data of all polls but you also
want to know the details of each separate poll.

	$output = $acct->get_lastpoll_output();

Return value :

$output		Reference to hash with all the aggregated information. The hash contains for each unique source-destination 
			host pair the following values :

	'source'			=> source ip address
	'destination'		=> destination ip address
	'lastPollBytes'		=> number of bytes for this pair seen during last do_accounting()
	'lastPollPackets'	=> number of packets for this pair seen during last do_accounting()
	'totalBytes'		=> total number of bytes seen for this pair every time do_accounting() was called
	'totalPakcets'		=> total number of packets seen for this pair every time do_accounting() was called
	'polls'				=> number of times this pair was seen every time do_accounting() was called
						   ex. if we've 'polled' twice and only once this pair was seen then the value = 1

=item get_output()

Returns a reference to the hash containing all aggregated information. 

	$output = $acct->get_output();

Return value :

$output		Reference to hash with all the aggregated information. The hash contains for each unique source-destination 
			host pair the following values :

	'source'			=> source ip address
	'destination'		=> destination ip address
	'lastPollBytes'		=> number of bytes for this pair seen during last do_accounting()
	'lastPollPackets'	=> number of packets for this pair seen during last do_accounting()
	'totalBytes'		=> total number of bytes seen for this pair every time do_accounting() was called
	'totalPakcets'		=> total number of packets seen for this pair every time do_accounting() was called
	'polls'				=> number of times this pair was seen every time do_accounting() was called
						   ex. if we've 'polled' twice and only once this pair was seen then the value = 1

=item get_statistics()

Returns a reference to a hash of some general statistics.

	$stats = $acct->get_statistics()

Return value :

$stats		Reference to hash containing some general statistics :

	starttime			timestamp of the first time do_accounting() was called
	lastpolltime		timestamp of the last time do_accounting() was called
	totalpolls			number of times do_accounting() was called
	totalbytes			total number of bytes seen for every time do_accounting() was called
	totalpackets		total number of packets seen for every time do_accounting() was called
	totalpolledlines	total number of lines that was parsed and aggregated
	totalskippedlines	total number of lines that were skipped (headers etc.)
	uniquehostpairs		total number of unique host pairs that were seen

=item keepalive()

If you have a persistent connection but you're only calling do_accounting() every 5 minutes for example then you might receive
a connection timeout.
This can be solved by sending a keepalive every 30 seconds for example.
The keepalive just sends a newline character to the remote host avoiding a connection timeout.

	$acct->keepalive()

=back

=head1 SUPPORTED DEVICES

At the moment only telnet connections are supported, not SSH.

All Cisco routers and switches that support 'IP Accounting'. Make sure that you have enable permissions and in configure permissions in
case you're enabling or disabling IP Accounting on interfaces.

All hosts (usually Unix hosts) that are running the IPCAD daemon with default settings. Make sure that the username has sufficient permissions on the host.

=head1 EXAMPLES

Some working examples can be found in the test folder of the source code.

Also you can check out 'CIPAT' on SourceForge. This is a front-end to Cisco::Accounting and allows you to easily enter the required
parameters using a small wizard and to generate reports in different formats.


CONNECT TO CISCO ROUTER AND PARSE IP ACCOUNTING 5 TIMES

	use Cisco::Accounting;
	use Data::Dumper;

	my %data = (
			'host'		=>	"foo",
			'user'		=>	"user",
			'pwd'		=>	"pass",
			'enable_user'	=>	"user",
			'enable_pwd'	=>	"enable_pass",		
		);

	my $acct;	
	my @interfaces;
	my $output;
	my $stats;
	my $historical;
	my $count = 5;
	my $i = 0;
	my $interval = 10;

	## initialize : make a new object, get the interfaces and enable ip accounting on 2 interfaces
	eval {  
		$acct = Cisco::Accounting->new(%data);	
		@interfaces = $acct->get_interfaces();
		$acct->enable_accounting(2,1);  
	};
	die ($@) if ($@);

	## start polling, 5 times with interval of 60 seconds
	while ($i < $count)  {

		## parse IP accounnting info and clear the accounting after each 'poll'
		eval {
			print "getting accounting information";
			$acct->do_accounting();
			print " ... OK\n";
			$acct->clear_accounting();
		};
		if ($@)  {
			warn $@;
		}

		$i++;
		sleep $interval if ($i < $count);
	}

	$output = $acct->get_output();
	$stats = $acct->get_statistics();
	$historical = $acct->get_history();

	# print output
	print &Dumper(\@interfaces);
	print &Dumper($output);
	print &Dumper($stats);
	print &Dumper($historical);

=head1 CAVEATS

Only telnet connections are supported, not SSH.  Slow telnet connections may timeout, possibly this needs to be finetuned.

IPCAD is supported but has been tested ONLY with default configuration. It's possible to configure IPCAD to do its own aggregation etc. but
Cisco::Accounting is not configured for this.

We assume that ALL interfaces have accounting enabled on IPCAD hosts, although it's possible to configure this otherwise in the IPCAD config files.

Also make sure that your user has permissions for IPCAD to clear the statistics!  If this doesn't work then check your IPCAD configuration.

This package makes configuration changes on Cisco routers (enabling and removing 'ip accounting' + clearing ip accounting statistics). Use at
your own risk !

The Cisco::Accounting package was in the first place intended for Cisco devices, although IPCAD seems to be working fine as well this
has not been fully tested.

=head1 AUTHOR

Maarten Wallraf, C<< <perl at 2nms.com> >>

=cut


