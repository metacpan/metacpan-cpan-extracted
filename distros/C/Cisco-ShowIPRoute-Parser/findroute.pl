#!/usr/bin/perl -w
# Find the rout from one devcie to another. We assume that two IPs are
# passed in thus: findroute.pl IP1 IP2
#

# We do this by taking the source IP (IP1) and lokk at it first 3 octets.
# Search through our know devices for ips that match. Should return a few
# routers.
#
# Then, run iproutes.pl over each router using IP1 looking for "directly
# connected". Once found we know the default initial router to use =>
# hence the log file to satrt with.
#
# Then we just run iproutes recursivley over each log file using IP2 as
# the destination until we find "directly connected". Easy... ;-)

# Set this to where your 'show ip route' logs live. Make sure the loags
# are named by the router names as returned from DNS in uppercase.
my $home  = './testlogs';
chdir($home);

use Data::Dumper;
use Socket;
use Cisco::ShowIPRoute::Parser;

use vars qw/%name %r $count/;

$| = 1;
$count = 0; # used to bail out if we recurse too far

# An re for valid IP addresses from Daimian Conway
my $digit =  q{(25[0-5]|2[0-4]\d|[0-1]??\d{1,2})};
my $ipre  = "$digit\.$digit\.$digit\.$digit";

# Pick up IP/Names and make sure they are valid
my $source = shift;
my $dest   = shift;
($source)  = ipaddress($source);
($dest)    = ipaddress($dest);

unless( $source =~ /^$ipre$/ )
{
	warn "IP address ($source) is invalid\n";
	exit 1;
}
unless( $dest =~ /^$ipre$/ )
{
	warn "IP address ($dest) is invalid\n";
	exit 2;
}

# Collect all our log files
opendir(DIR,'.') || die;
my @devices = grep { -f $_ && /\.log$/ } readdir(DIR);
closedir DIR;

# Work out our name if we can
my ($n) = getname($source);

# If there is a log file by that name then use it as the initial starting
# point. Otherwise go looking through ALL log files for a starting point
my @initials = ();
my $retryall = 0;  # flags failure on a single log file
if( -f "$n.log" )
{
	# Need to do some tests to make sure this is a valid starting point
	my $log = "$n.log";
	$r{$log} = new Cisco::ShowIPRoute::Parser($log) unless defined $r{$log};
	if( grep(/directly/, $r{$log}->getroutes($source)) )
	{
		@initials = ($log);
	}
	else
	{
		warn "$source not directly connected to $n. Naming issue?\n";
		warn "scanning all logs for a starting point\n";
		$retryall = 1;
	}
}
elsif(!-f "$n.log" || $retryall)
{
	# Now see if we can find any log files that contain directly connected
	# nest that look like our source IP
	my($a,$b,$c,$d) = $source =~ m/^$ipre$/;

	# try full IP first as we may be starting from a router. If that fails
	# try first 3 octets
	@initials = `/bin/grep -l '$a\.$b\.$c\.$d.*directly' *.log`;
	chomp(@initials); # clean filenames
	unless(@initials)
	{
		@initials = `/bin/grep -l '$a\.$b\.$c\..*directly' *.log`;
		unless(@initials)
		{
			die "Can't find an initial default router for $source\n";
		}
		chomp(@initials); # clean filenames

		# If getroutes()
		# doesn't say directly connected then not a valid starting point
		my @keep = ();
		for my $log (@initials)
		{
			next if $log eq "$source.log";  # Not ourselves thanks
			$r{$log} = new Cisco::ShowIPRoute::Parser($log) unless defined $r{$log};
			my @test = $r{$log}->getroutes($source);
			if( grep(/directly/, @test) )
			{
				# Good we know the source is directly connected.  but we don't
				# want to go way from the destination. So check to see if we
				# find the source ip when asking for the destination. If so
				# then we don't want that path. Remeber names have many IPs
				$r{$log} = new Cisco::ShowIPRoute::Parser($log) unless defined $r{$log};
				@test = $r{$log}->getroutes($dest);
				unless(grep(/^$a\.$b\.$c\.$d$/,@test))
				{
					push(@keep,$log) unless grep(getname($_) eq $n, @test);
				}
			}
		}
		@initials = @keep;
		die "Can't find an initial default router for $source\n" unless @initials;
	}
}

my @parents = @initials;
@parents = map { s/\.log//; $_ } @parents;
#print "Parents are: ",join(", ",@parents),"\n";
addparent('',$n,@parents) if $n =~ /^$ipre$/;
findparents(' ',$dest,@initials);
exit;

sub findparents
{
	my $space = shift;
	my $dest = shift;
	my @logs = @_;

	my (@ips) = ();

	# Safety net
	$count++;
	if($count > 80)
	{
		print "Too man parents found! Probably looping\n";
		return;
	}

	for my $log (@logs)
	{
		my $nodename = $log;
		$nodename =~ s/\.log$//;

		$r{$log} = new Cisco::ShowIPRoute::Parser($log) unless defined $r{$log};
		@ips = $r{$log}->getroutes($dest);
		chomp(@ips);
		next unless @ips;
		
		# handle directly connected end points
		if(grep(/^is directly connected/,@ips))
		{
			my @tmp = ();
			my ($dname) = getname($dest);

			# Loop through ips looking for directly connected
			for my $ip ( @ips )
			{
				if( $ip =~ /^is directly connected/)
				{
					addparent($space,$nodename,$dname) unless $nodename eq $dname;
				}
				else
				{
					push(@tmp,$ip); # Nup save it away
				}
			}
			next unless @tmp; # Done if all directly connected
			@ips = @tmp;        # Restore new list of ips not connected
		}

		# OK now lets do a reverse look up to see if these IPs are pointing
		# to the same physical device
		my @names = ();
		my @parents = ();
		for my $ip (@ips)
		{
			my ($n) = getname($ip);
			push(@names,$n) unless grep($n eq $_,@names);
			push(@parents,[$n,$ip]);
		}
		addparent($space,$nodename,@parents);

		@names = map { "$_.log" } @names;
		#print $space,"findparents($dest,@names)\n";
		findparents($space . ' ',$dest,@names);
	}
}


sub addparent
{
	my ($space,$host,@parent) = @_;

	# We want IP if none passed
	my($hip) = ipaddress($host);

	# OK enter the data
	for (my $i=0; $i <= $#parent; $i++)
	{
		my $p    = $parent[$i]->[0] || $parent[$i];
		my ($ip) = ($parent[$i]->[1]) || ipaddress($p);

		print $space,"$host,$hip => $p,$ip\n";
	}
}


sub ipaddress
{
	my @host = @_;
	my @ip = ();

	foreach (@host)
	{
		$_ = uc($_);

		# Is it already an IP looking thing?
		if(/^$ipre$/)
		{
			push(@ip,$_);
			next;
		}

		# Else do a look up
		#print "Device $_ unknown or has no IP address in Devices DB.\n";
		# Try DNS
		my ($name,$aliases,$addrtype,$length,@addrs) = gethostbyname($_);
		if( @addrs )
		{
			push(@ip,inet_ntoa($addrs[0]));
		}
		else
		{
			push(@ip,'unknown');
		}
	}
	return @ip;
}


sub getname
{
	my @ips = @_;
	chomp(@ips);
	my @name = ();

	for my $ip (@ips)
	{
		unless($ip =~ /^\d+\.\d+\.\d+\.\d+$/)
		{
			push(@name,$ip);  # Already a name
			next;
		}

		# Try our cache
		my $n = '';
		if(defined $name{$ip})
		{
			push(@name, $name{$ip});
			next;
		}

		# Try DNS
		($n) = gethostbyaddr(inet_aton($ip),AF_INET) unless $n;
		if( $n )
		{
			$n =~ s/^.*:\s*//;
			$n =~ s/^([^.]+).*$/$1/;
			chomp($n);
			$n = uc($n);
			$name{$ip} = $n;
			push(@name,$n);
			next;
		}

		# No Name..
		$name{$ip} = $ip;
		push(@name,$ip);
	}
	return @name;
}

