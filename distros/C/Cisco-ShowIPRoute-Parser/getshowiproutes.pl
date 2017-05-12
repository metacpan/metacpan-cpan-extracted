#!/usr/bin/perl -w

use lib '.';

use Cisco::ShowIPRoute::Parser;
use ExecCmds;
use Socket;

# You need to define your devices here. See the perldoc for ExecCmds for
# fulldetails of what you can do here.
my @devices = qw/RN-48GE-03-MSFC-12 RN-48GE-03-MSFC-11/;
my $skiplogs = 0;

# Used to see if we will use configs this old
$age =  0.083 unless $age; # 0.083 => 2hrs, 0.0001157 => 10mins

# An re for valid IP addresses from Daimian Conway
my $digit =  q{(25[0-5]|2[0-4]\d|[0-1]??\d{1,2})};
my $ipre  = "$digit\.$digit\.$digit\.$digit";


# Setup the config hash
%config = (

  #debug => 1,
  verbose => 1,
  log => '/dev/null',
  number => 3,
  pretty => 0,
  care   => 0,  # Don't care about failures plough on
  timeout => 50,

  pass => [
        {'user' => 'snoopy_sugar', 'pass' => 'pCfKof6C',   'enable' => 'p0a29cuw'},
  ],

  # Our router commands to execute
  rcmds => [ 
		'terminal ip netmask-format decimal',
        'show ip route',
  ],
  
  # Our router Pre conditions - none
  r_pre_regex => [ ],
  
  # Our router Post conditions - none
  r_post_regex => [ ],
  
  # Our Switch commands - none
  scmds => [ ],
  
  # Our Switch Pre conditions - none
  s_pre_regex => [ ],
  
  # Our Switch Post conditions - none
  s_post_regex => [ ],
 );


# Remove devices we already have logs for that are young
my @logs = getlogs();
my %seen = ();
%seen = map {s/\.log$//; $_ => 1} @logs;
@devices = grep(!defined $seen{$_} || -M "$_.log" >= $age, @devices);

# Get all the info we need
my $cmds = ExecCmds->new();
$cmds->configure(%config);
$cmds->configure('log','%%name%%.log');
$cmds->run(@devices);


# OK we now have a directory of lots of log files. These files will not
# give us all the info. However, some of them will point to other hosts
# that we can use. So lets go through them.
unless($skiplogs)
{
	for my $log (getlogs())
	{
		process_parents($cmds,$log,'');
	}
}

exit;

# Pick up all the logs in the current directory
sub getlogs
{
	opendir(DIR,'.') || die;
	my @logs = sort grep { -f $_ && /\.log$/ } readdir(DIR);
	closedir DIR;

	return @logs;
}

# Process a log file picking up Parents as we go. This is a recursive
# function beware.
sub process_parents
{
	my ($cmd,$log,$space) = @_;

	# Get the parent ips for this log file and bail out if there are no
	# more to do.
	print $space,"Processing log $log\n";
	my @pips = getparentips($log,$space);
	unless( @pips )
	{
		print $space,"Finished log $log\n";
		return;
	}

	# Build an array of complex device details for ExecCmds to handle.
	# We need to use the complex version as CN may not resolve.
	my @dev_pip = ();
	@dev_pip = map { [ {'CN' => getname($_)}, {'IP' => $_} ] } @pips;
	$cmds->configure('log','');  # Logs go to CN.log
	print "Running commands against:\n", Data::Dumper->Dump([\@dev_pip], ['Devs']);
	$cmds->run(@dev_pip);

	# For each of these Parent IPs process them
	foreach(@pips)
	{
		my ($log) = getname($_); # Name or IP
		$log .= '.log';
		process_parents($cmd,$log,$space . '  ');
	}
	print $space,"Finished log $log\n";
	return;
}


# Here is where the real work gets done parsing the log file. 
# Done by Raj now :-) using iproute-parents
sub getparentips
{
	my $file = shift;
	my $space = shift;

	my $rtr = new Cisco::ShowIPRoute::Parser($file);
	my @lines = $rtr->getroutes('10.25.159.33');

	# Clean up the lines
	my @tmp = map {s/^\s+//;s/\n//; $_} @lines;

	my @rtn = ();
	# Only return IPs that we don't have names for and also if we
	# don't already have a recent log file for it
	foreach(@tmp)
	{
		next if /direct/;   # Skip directly connected ones
		my ($name) = getname($_);
		if( !$name ||                                 # No name found
		    !-f "$name.log" ||                        # No current log file
			( -f "$name.log" && -M "$name.log" >= $age)# Have log but old
		)
		{
			next if -f "$_.log" && -M "$_.log" < $age; # Have young IP.log
			push(@rtn,$_);
		}
	}

	print $space,"Parents for 10.25.159.33 in $file => @rtn\n";
	return @rtn;
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

		# Hmm a name just give it a check
        my $n = '';

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


