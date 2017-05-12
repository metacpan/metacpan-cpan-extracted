package BlueCoat::SGOS;
use strict;
use warnings;
use Data::Dumper;
use Date::Parse;
use LWP::UserAgent;
require HTTP::Request;
use HTTP::Request::Common qw/POST/;

our %_URL = (
	'archconf_expanded'    => '/archconf_expanded.txt',
	'contentfilter_status' => '/ContentFilter/Status',
	'sysinfo'              => '/SYSINFO',
	'send_command' =>
	  '/Secure/Local/console/install_upload_action/cli_post_setup.txt'
);

our %defaults = (
	'appliancehost'        => 'proxy',
	'applianceport'        => 8082,
	'applianceusername'    => 'admin',
	'appliancepassword'    => 'password',
	'applianceconnectmode' => 'https',
	'debuglevel'           => 0,
);

=head1 NAME

BlueCoat::SGOS - A module to interact with Blue Coat SGOS-based devices.

=head1 VERSION

Version 1.05

=cut

our $VERSION = '1.05';

=head1 SYNOPSIS

This module interacts with Blue Coat SGOS-based devices.  Right
now, this is limited to parsing of the 'sysinfo' data from the
device.

	use strict; #always!
	use BlueCoat::SGOS;
	my $bc = BlueCoat::SGOS->new(
		'appliancehost'		=> 'swg.example.com',
		'applianceport'		=> 8082,
		'applianceuser'		=> 'admin',
		'appliancepassword'	=> 'password'
	);
	$bc->get_sysinfo();
	$bc->parse_sysinfo();

	# or from a file
	my $bc = BlueCoat::SGOS->new();
	$bc->get_sysinfo_from_file('/path/to/file.sysinfo');
	$bc->parse_sysinfo();

	# or from a data structure
	# in this case, $sysinfodata already contains sysinfo data
	my $bc = BlueCoat::SGOS->new();
	$bc->get_sysinfo_from_data($sysinfodata);
	$bc->parse_sysinfo();

	my $sysinfodata = $bc->{'sgos_sysinfo'};
	my $sgosversion = $bc->{'sgosversion'};
	my $sgosreleaseid = $bc->{'sgosreleaseid'};
	my $serialnumber = $bc->{'serialnumber'};
	my $modelnumber = $bc->{'modelnumber'};
	my $sysinfotime = $bc->{'sysinfotime'};

	# Hardware section of the sysinfo file
	my $hwinfo = $bc->{'sgos_sysinfo_sect'}{'Hardware Information'};

	# Software configuration (i.e. show configuration)
	my $swconfig = $bc->{'sgos_sysinfo_sect'}{'Software Configuration'};


=head1 SUBROUTINES/METHODS

Below are methods for BlueCoat::SGOS.
=cut

=head2 new

Creates a new BlueCoat::SGOS object.  Can be passed one of the following:

	appliancehost
	applianceport
	applianceusername
	appliancepassword
	applianceconnectmode (one of http or https)
	debuglevel

=cut

sub new {
	my $class = shift;
	my $self  = {};
	bless($self, $class);
	my %args = (%defaults, @_);

	$self->{'_appliancehost'}        = $args{'appliancehost'};
	$self->{'_applianceport'}        = $args{'applianceport'};
	$self->{'_applianceusername'}    = $args{'applianceusername'};
	$self->{'_appliancepassword'}    = $args{'appliancepassword'};
	$self->{'_applianceconnectmode'} = $args{'applianceconnectmode'};
	$self->{'_debuglevel'}           = $args{'debuglevel'};
	if (   $self->{'_appliancehost'}
		&& $self->{'_applianceport'}
		&& $self->{'_applianceconnectmode'}
		&& $self->{'_applianceusername'}
		&& $self->{'_appliancepassword'}) {

		if ($self->{'_applianceconnectmode'} eq 'https') {
			$self->{'_applianceurlbase'} =
			    q#https://#
			  . $self->{'_appliancehost'} . q#:#
			  . $self->{'_applianceport'};
		}
		elsif ($self->{'_applianceconnectmode'} eq 'http') {
			$self->{'_applianceurlbase'} =
			    q#http://#
			  . $self->{'_appliancehost'} . q#:#
			  . $self->{'_applianceport'};
		}
	}

	return $self;
}

sub _create_ua {
	my $self = shift;
	$self->{'_lwpua'} = LWP::UserAgent->new();
	$self->{'_lwpua'}->agent("BlueCoat-SGOS/$VERSION");
	$self->{'_lwpua'}->ssl_opts(
		'SSL_verify_mode' => 0,
		'verify_hostname' => 0,
	);

}

=head2 get_sysinfo

Takes no parameters, but instead fetches the sysinfo from the
appliance specified in the constructor.

	$bc->get_sysinfo();

=cut

sub get_sysinfo {
	my $self = shift;

	if ($self->{'_debuglevel'} > 0) {
		print 'URLBASE=' . $self->{'_applianceurlbase'} . "\n";
		print 'Getting '
		  . $self->{'_applianceurlbase'}
		  . $_URL{'sysinfo'} . "\n";
	}
	if (!defined($self->{'_lwpua'})) {
		$self->_create_ua();
	}
	my $request =
	  HTTP::Request->new('GET',
		$self->{'_applianceurlbase'} . $_URL{'sysinfo'});
	$request->authorization_basic($self->{'_applianceusername'},
		$self->{'_appliancepassword'});
	my $response = $self->{'_lwpua'}->request($request);

	if ($response->is_error) {
		return 0;
	}
	else {
		$self->{'sgos_sysinfo'} = $response->content;
		$self->{'sgos_sysinfo'} =~ s/\r\n/\n/gi;
		if ($self->{'_debuglevel'} > 0) {
			print 'status=' . $response->status_line . "\n";
		}
	}
	if ($self->{'sgos_sysinfo'}) {
		return 1;
	}
	else {
		return 0;
	}
}

=head2 get_sysinfo_from_file

Takes one parameter: the filename of a sysinfo file on the disk.  Use this
instead of logging in over the network.

	$bc->get_sysinfo_from_file('sysinfo.filename.here');

=cut

sub get_sysinfo_from_file {
	my $self     = shift;
	my $filename = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "sub:get_sysinfo_from_file, filename=$filename\n";
	}
	if (-f $filename) {
		open my $FSDFLKFJ, q{<} , $filename;

		# slurp
		{
			local $/ = undef;
			$self->{'sgos_sysinfo'} = <$FSDFLKFJ>;
			$self->{'sgos_sysinfo'} =~ s/\r\n/\n/gi;
		}
		close $FSDFLKFJ;

		if ($self->{'sgos_sysinfo'}) {
			return 1;
		}
		else {
			return 0;
		}
	}
	else {

		# no filename specified
		return 0;
	}
}

=head2 get_sysinfo_from_data

Takes one parameter: a scalar that contains sysinfo data.
Use this instead of logging in over the network.

	$bc->get_sysinfo_from_data($sysinfodata);

=cut

sub get_sysinfo_from_data {
	my $self = shift;
	my $data = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "sub:get_sysinfo_from_data\n";
	}
	$self->{'sgos_sysinfo'} = $data;
	$self->{'sgos_sysinfo'} =~ s/\r\n/\n/gi;
	if ($self->{'sgos_sysinfo'}) {
		return 1;
	}
	else {
		return 0;
	}
}

=head2 parse_sysinfo

Takes no parameters.  Tells the object to parse the sysinfo
data and populate the object variables.

=cut

sub parse_sysinfo {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "parse_sysinfo\n";
	}
	my @split_sysinfo =
	  split(
/__________________________________________________________________________/,
		$self->{'sgos_sysinfo'}
	  );
	$self->{'_sgos_sysinfo_split_count'} = $#split_sysinfo;

	# init the % var
	$self->{'sgos_sysinfo_sect'}{'_ReportInfo'} = $split_sysinfo[0];

	# Populate the sysinfo version
	# As of 6.2.2011, these are the known versions:
	# Version 4.6
	# Version 5.0
	# Version 6.0
	# Version 6.1
	# Version 7.0
	($self->{'_sysinfoversion'}) =
	  $self->{'sgos_sysinfo_sect'}{'_ReportInfo'} =~ m/Version (\d+\.\d+)/;

	# Loop through each section of the split sysinfo
	foreach (1 .. $#split_sysinfo) {
		my $chunk = $split_sysinfo[$_];
		my @section = split(/\n/, $chunk);
		chomp @section;

		# the first 2 lines are junk
		shift @section;
		shift @section;
		my $sectionname = shift @section;

		if ($sectionname eq 'Software Configuration') {

			# get rid of 3 lines from top and 1 from bottom
			shift @section;
			shift @section;
			shift @section;
			pop @section;
		}
		if ($sectionname eq 'TCP/IP Routing Table') {
			shift @section;
			shift @section;
			shift @section;
			shift @section;
			shift @section;
		}

		# throw away the next line, it contains the URL for the source data
		shift @section;
		my $data = join("\n", @section);
		$self->{'sgos_sysinfo_sect'}{$sectionname} = $data;
	}

	# parse version
	$self->_parse_sgos_version();

	# parse releaseid
	$self->_parse_sgos_releaseid();

	# parse serial number
	$self->_parse_serial_number();

	# parse sysinfo time
	$self->_parse_sysinfo_time();

	# parse last reboot time
	$self->_parse_reboot_time();

	# parse model
	$self->_parse_model_number();

	# parse the configuration
	if ($self->{'sgos_sysinfo_sect'}{'Software Configuration'}) {
		$self->_parse_swconfig;
		$self->{'sysinfo_type'} = 'sysinfo';
	}
	else {
		$self->{'sysinfo_type'} = 'sysinfo_snapshot';
	}

	# parse VPM-CPL and VPM-XML
	$self->_parse_vpm();

	# parse the static bypass list
	$self->_parse_static_bypass();

	# parse the appliance name
	$self->_parse_appliance_name();

	# parse the network information
	$self->_parse_network();

	# parse the ssl accelerator info
	$self->_parse_ssl_accelerator();

	# parse the default gateway
	$self->_parse_default_gateway();

	# parse the route table
	$self->_parse_route_table();

	return 1;
}

# Find appliance-name
# located in the Software Configuration
# looks like:
# appliance-name "ProxySG 210 4609077777"
# limited to 127 characters
# e.g.: % String exceeds allowed length (127)
#
sub _parse_appliance_name {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_swconfig\n";
	}
	if (defined($self->{'sgos_sysinfo_sect'}{'Software Configuration'})) {
		(undef, $self->{'appliance-name'}) =
		  $self->{'sgos_sysinfo_sect'}{'Software Configuration'} =~
		  m/(appliance-name|hostname) (.+)$/im;
		$self->{'appliance-name'} =~ s/^\"//;
		$self->{'appliance-name'} =~ s/\"$//;

		if ($self->{'_debuglevel'} > 0) {
			print "appliancename=$self->{'appliance-name'}\n";
		}
	}
}

# model
# Model: 200-B
sub _parse_model_number {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_model_number\n";
	}

	#210-5 (unsupported configuration)
	#
	if (defined($self->{'sgos_sysinfo_sect'}{'Hardware Information'})) {
		($self->{'modelnumber'}) =
		  $self->{'sgos_sysinfo_sect'}{'Hardware Information'} =~
		  m/Model:\s(.+)/im;
		if ($self->{'modelnumber'} =~ m/unsupported configuration/i) {
			$self->{'modelnumber'} =~ s/\s*\(unsupported configuration\)\s*//ig;
			$self->{'supported_configuration'} = 0;
		}
		else {
			$self->{'supported_configuration'} = 1;
		}
	}
}

# get network
# Network:
#   Interface 0:0: Bypass 10/100     with no link  (MAC 00:d0:83:04:ae:fc)
#   Interface 0:1: Bypass 10/100     running at 100 Mbps full duplex (MAC 00:d0:83:04:ae:fd)
sub _parse_network {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_network\n";
	}
	if (defined($self->{'sgos_sysinfo_sect'}{'Hardware Information'})) {
		my ($netinfo) =
		  $self->{'sgos_sysinfo_sect'}{'Hardware Information'} =~
		  m/Network:(.+)Accelerators/ism;
		my @s = split(/\n/, $netinfo);
		chomp @s;
		foreach (@s) {
			my $line = $_;
			my ($interface) = $line =~ m/Interface\s+(.+)\:\s/im;
			my ($mac)       = $line =~ m/\(MAC\s(.+)\)/im;
			my ($running)   = $line =~ m/running\sat\s(.+)\s\(MAC/im;
			my $capabilities;

#Interface 0:0: Intel Gigabit     running at 1 Gbps full duplex (MAC 00:e0:81:79:a5:1a)
#Interface 2:0: Bypass 10/100/1000 with no link  (MAC 00:e0:ed:0b:67:e6)
			if ($line =~ m/running at/) {
				($capabilities) =
				  $line =~ m/Interface\s$interface\:\s\w+(.+)\s+running at/;
			}
			if ($line =~ m/with no link/) {
				($capabilities) =
				  $line =~ m/Interface\s$interface\:\s\w+(.+)\s+with no link/;
			}
			if ($capabilities) {
				$capabilities =~ s/\s+//ig;
			}
			if ($interface && $capabilities) {
				$self->{'interface'}{$interface}{'capabilities'} =
				  $capabilities;
			}

			#print "Running=$running\n";
			if ($interface && $mac) {
				$self->{'interface'}{$interface}{'mac'} = $mac;
			}
			if ($interface && $running) {
				$self->{'interface'}{$interface}{'linkstatus'} = $running;
			}
			if ($interface && !$running) {
				$self->{'interface'}{$interface}{'linkstatus'} = 'no link';
			}

			#print "interface=$interface, mac=$mac\n";
		}
	}

	# supplement from swconfig/networking
	#print "getting supplemental networking info\n";
	my @t;

	#if (defined($self->{'sgos_swconfig_section'}{'networking'} ) ) {
	if (defined($self->{'sgos_swconfig_section'}{'networking'})) {
		@t = split(/\n/, $self->{'sgos_swconfig_section'}{'networking'});
		chomp @t;
	}

	if (defined($self->{'sgos_sysinfo_sect'}{'Software Configuration'})) {
		if ($#t < 2) {
			@t =
			  split(/\n/,
				$self->{'sgos_sysinfo_sect'}{'Software Configuration'});
		}
	}

	#}

	my $interface;
	my ($ip, $netmask);
	foreach (@t) {
		my $line = $_;

		if ($line =~ m/interface (.+)\;/i) {
			($interface) = $line =~ m/^interface (\d+\:?\d*\.*\d*)/i;
		}

		# sgos5, ip address and subnet mask are on SAME line
		if ($line =~ m/ip-address/) {

			($ip, $netmask) =
			  $line =~
m/^ip-address\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}) *(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})*/i;
			if (defined($ip)) {
				$ip =~ s/\s+//gi;
			}
			if (defined($netmask)) {
				$netmask =~ s/\s+//gi;
			}
		}
		if ($line =~ m/subnet-mask/) {
			($netmask) =
			  $line =~ m/^subnet-mask *(.{1,3}\..{1,3}\..{1,3}\..{1,3})/i;
			$netmask =~ s/\s+//gi;
		}

		if (defined($interface)) {
			if (length($interface) > 1 && $ip && $netmask) {
				$self->{'interface'}{$interface}{'ip'}      = $ip;
				$self->{'interface'}{$interface}{'netmask'} = $netmask;
				$interface                                  = undef;
				$ip                                         = undef;
			}
		}

	}
}

sub _parse_swconfig {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_swconfig\n";
	}
	my @split_swconfig =
	  split(/\n/, $self->{'sgos_sysinfo_sect'}{'Software Configuration'});

	# only applies to SGOS >5
	my $sectionname = '';
	foreach (1 .. $#split_swconfig) {
		my $line = $split_swconfig[$_];
		chomp $line;
		if ($line =~ m/!- BEGIN/) {
			($sectionname) = $line =~ m/!- BEGIN (.+)/;
		}
		elsif ($line =~ m/!- END/) {
			next;
		}
		else {
			if (defined($self->{'sgos_swconfig_section'}{$sectionname})) {
				$self->{'sgos_swconfig_section'}{$sectionname} =
				  $self->{'sgos_swconfig_section'}{$sectionname} . $line . "\n";
			}
			else {
				$self->{'sgos_swconfig_section'}{$sectionname} = $line . "\n";
			}
		}

	}

}

sub _parse_static_bypass {
	my $self = shift;
	if (defined($self->{'sgos_sysinfo_sect'}{'Software Configuration'})) {
		my @lines =
		  split(/\n/, $self->{'sgos_sysinfo_sect'}{'Software Configuration'});
		my $have_static_bypass;
		foreach my $line (@lines) {
			if ($line =~ m/static-bypass/) {
				$have_static_bypass = 1;
			}
			elsif ($have_static_bypass) {
				if ($line =~ m/exit/) {
					last;
				}
				else {
					$line =~ s/^add //i;
					if (defined($self->{'static-bypass'})) {
						$self->{'static-bypass'} =
						  $self->{'static-bypass'} . $line . "\n";
					}
					else {
						$self->{'static-bypass'} = $line . "\n";
					}
				}
			}
		}
	}
}

sub _parse_vpm {
	my $self = shift;
	if (defined($self->{'sgos_sysinfo_sect'}{'Software Configuration'})) {
		my @lines =
		  split(/\n/, $self->{'sgos_sysinfo_sect'}{'Software Configuration'});
		my $have_vpm_cpl;
		my $have_vpm_xml;

		foreach my $line (@lines) {
			if ($line =~ m/^inline policy vpm-cpl \"*end-(\d+)-inline\"*/) {
				($have_vpm_cpl) =
				  $line =~ m/^inline policy vpm-cpl \"*end-(\d+)-inline\"*/;
			}
			elsif ($have_vpm_cpl) {
				if ($line =~ m/end-$have_vpm_cpl-inline/i) {
					last;
				}
				else {
					if (defined($self->{'vpm-cpl'})) {
						$self->{'vpm-cpl'} = $self->{'vpm-cpl'} . $line . "\n";
					}
					else {
						$self->{'vpm-cpl'} = $line . "\n";
					}
				}
			}

		}

		foreach my $line (@lines) {
			if ($line =~ m/^inline policy vpm-xml \"*end-(\d+)-inline\"*/) {
				($have_vpm_xml) =
				  $line =~ m/^inline policy vpm-xml \"*end-(\d+)-inline\"*/;
			}
			elsif ($have_vpm_xml) {
				if ($line =~ m/end-$have_vpm_xml-inline/i) {
					last;
				}
				else {
					if (defined($self->{'vpm-xml'})) {
						$self->{'vpm-xml'} = $self->{'vpm-xml'} . $line . "\n";
					}
					else {
						$self->{'vpm-xml'} = $line . "\n";
					}
				}
			}

		}
	}

	return 1 if ($self->{'vpm-cpl'} && $self->{'vpm-xml'});
}

=head2 vpmcpl

Displays the VPM-CPL data.  Note that this does not currently return the
local, central, or forwarding policies.

=cut

sub vpmcpl {
	my $self = shift;
	return $self->{'vpm-cpl'};
}

=head2 vpmxml

Displays the VPM-XML data.

=cut

sub vpmxml {
	my $self = shift;
	return $self->{'vpm-xml'};
}

sub _parse_default_gateway {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
	}

	my @s;
	if (defined($self->{'sgos_swconfig_section'}{'networking'})) {
		my @s = split(/\n/, $self->{'sgos_swconfig_section'}{'networking'});
		chomp @s;
	}
	if (defined($self->{'sgos_sysinfo_sect'}{'Software Configuration'})) {
		if ($#s < 2) {
			@s =
			  split(/\n/,
				$self->{'sgos_sysinfo_sect'}{'Software Configuration'});
		}
	}
	if ($#s > 0) {
		foreach my $line (@s) {
			if ($line =~ m/ip-default-gateway/) {
				($self->{'ip-default-gateway'}) = $line =~
				  m/^ip-default-gateway +(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/;
			}
		}
	}

}

sub _parse_route_table {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_route_table: begin\n";
	}

	#inline static-route-table "end-398382495-inline"
	#; IP-Address Subnet Mask Gateway
	#172.16.0.0 255.240.0.0 172.20.144.1
	#end-398382495-inline
	if (defined($self->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'})) {
		my @r;
		if ($self->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'}) {
			$self->{'routetable'} =
			  $self->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'};
		}
		else {
			@r =
			  split(/\n/,
				$self->{'sgos_sysinfo_sect'}{'Software Configuration'});
		}
		my $marker;
		foreach my $line (@r) {
			if ($line =~ m/inline static-route-table \"end-\d+-inline\"/i) {
				($marker) =
				  $line =~ m/inline static-route-table \"end-(\d+)-inline\"/i;
			}
			if ($self->{'_debuglevel'} > 0) {
				print "_parse_route_table: marker=$marker\n";
			}
			if (defined($marker)) {
				if ($line =~ m/end-$marker-inline/o) {
					$marker = undef;
				}
			}
			if ($marker && $line !~ /$marker/i) {
				if ($line =~ m/^\s*?\;/) {
					next;
				}
				if ($line =~
m/\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s*(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/
				  ) {
					if (defined($self->{'static-route-table'})) {
						$self->{'static-route-table'} =
						  $self->{'static-route-table'} . $line . "\n";
					}
					else {
						$self->{'static-route-table'} = $line . "\n";
					}

				}
			}
		}
	}

}

sub _parse_serial_number {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_sgos_serial_number\n";
	}
	if (defined($self->{'sgos_sysinfo_sect'}{'Version Information'})) {
		($self->{'serialnumber'}) =
		  $self->{'sgos_sysinfo_sect'}{'Version Information'} =~
		  m/Serial\snumber\sis\s(\d+)/isx;
	}
}

sub _parse_ssl_accelerator {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_ssl_accelerator\n";
	}

	# SSL Accelerators
	# looks like:
	# Accelerators: none
	# or
	# Accelerators:
	#  Internal: Cavium CN1010 Security Processor
	#  Internal: Cavium CN501 Security Processor
	#  Internal: Broadcom 5825 Security Processor
	#
	if (defined($self->{'sgos_sysinfo_sect'}{'Hardware Information'})) {
		my ($acceleratorinfo) =
		  $self->{'sgos_sysinfo_sect'}{'Hardware Information'} =~
		  m/(Accelerators\:.+)/ism;
		my @a = split(/\n/, $acceleratorinfo);

		#print "There are $#a lines\n";
		# if 1 line, then no SSL accelerator
		if ($#a == 0) {
			$self->{'ssl-accelerator'} = 'none';
		}
		if ($#a > 0) {
			($self->{'ssl-accelerator'}) = $a[1] =~ m/\s+(.+)/;
		}
	}

	#	print "DEBUG: acceleratorinfo=$acceleratorinfo\n";
	#print "DEBUG: ssl-accelerator=$self->{'ssl-accelerator'}\n";
}

# sysinfo time
# time on this file
# The current time is Mon Nov 23, 2009 18:48:38 GMT (SystemTime 438547718)
# The current time is Sat Mar 7, 2009 16:57:30 GMT (SystemTime 415990650)
sub _parse_sysinfo_time {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_sysinfo_time\n";
	}
	if (defined($self->{'sgos_sysinfo_sect'}{'Version Information'})) {
		($self->{'sysinfotime'}) =
		  $self->{'sgos_sysinfo_sect'}{'Version Information'} =~
		  m/^The current time is (.+) \(/im;
		$self->{'sysinfotime_epoch'} = str2time($self->{'sysinfotime'});
	}
}

sub _parse_reboot_time {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_reboot_time\n";
	}

# Calculate hardware reboot time
# The ProxySG Appliance was last hardware rebooted 1 days, 5 hours, 55 minutes, and 0 seconds ago.
	if (defined($self->{'sgos_sysinfo_sect'}{'Version Information'})) {
		($self->{'hardware_reboot'}) =
		  $self->{'sgos_sysinfo_sect'}{'Version Information'} =~
		  m/The ProxySG Appliance was last hardware rebooted (.*)$/m;
		($self->{'hardware_reboot_day'}) =
		  $self->{'hardware_reboot'} =~ m/(\d+) day/;
		if (!defined($self->{'hardware_reboot_day'})) {
			$self->{'hardware_reboot_day'} = 0;
		}
		($self->{'hardware_reboot_hour'}) =
		  $self->{'hardware_reboot'} =~ m/(\d+) hour/;
		if (!defined($self->{'hardware_reboot_hour'})) {
			$self->{'hardware_reboot_hour'} = 0;
		}
		($self->{'hardware_reboot_minute'}) =
		  $self->{'hardware_reboot'} =~ m/(\d+) minute/;
		if (!defined($self->{'hardware_reboot_minute'})) {
			$self->{'hardware_reboot_minute'} = 0;
		}
		($self->{'hardware_reboot_second'}) =
		  $self->{'hardware_reboot'} =~ m/(\d+) second/;
		if (!defined($self->{'hardware_reboot_second'})) {
			$self->{'hardware_reboot_second'} = 0;
		}
		$self->{'hardware_reboot_seconds_total'} =
		  ($self->{'hardware_reboot_day'} * 24 * 3600) +
		  ($self->{'hardware_reboot_hour'} * 3600) +
		  ($self->{'hardware_reboot_minute'} * 60) +
		  $self->{'hardware_reboot_second'};

# The ProxySG Appliance was last software rebooted 1 days, 5 hours, 55 minutes, and 1 seconds ago.

		($self->{'software_reboot'}) =
		  $self->{'sgos_sysinfo_sect'}{'Version Information'} =~
		  m/The ProxySG Appliance was last software rebooted (.*)$/m;
		($self->{'software_reboot_day'}) =
		  $self->{'software_reboot'} =~ m/(\d+) day/;
		if (!defined($self->{'software_reboot_day'})) {
			$self->{'software_reboot_day'} = 0;
		}
		($self->{'software_reboot_hour'}) =
		  $self->{'software_reboot'} =~ m/(\d+) hour/;
		if (!defined($self->{'software_reboot_hour'})) {
			$self->{'software_reboot_hour'} = 0;
		}
		($self->{'software_reboot_minute'}) =
		  $self->{'software_reboot'} =~ m/(\d+) minute/;
		if (!defined($self->{'software_reboot_minute'})) {
			$self->{'software_reboot_minute'} = 0;
		}
		($self->{'software_reboot_second'}) =
		  $self->{'software_reboot'} =~ m/(\d+) second/;
		if (!defined($self->{'software_reboot_second'})) {
			$self->{'software_reboot_second'} = 0;
		}
		$self->{'software_reboot_seconds_total'} =
		  ($self->{'software_reboot_day'} * 24 * 3600) +
		  ($self->{'software_reboot_hour'} * 3600) +
		  ($self->{'software_reboot_minute'} * 60) +
		  $self->{'software_reboot_second'};
	}
}

sub _parse_sgos_releaseid {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_sgos_releaseid\n";
	}

	# parse  SGOS version, SGOS releaseid, and serial number
	# SGOS release ID
	if (defined($self->{'sgos_sysinfo_sect'}{'Version Information'})) {
		($self->{'sgosreleaseid'}) =
		  $self->{'sgos_sysinfo_sect'}{'Version Information'} =~
		  m/Release\sid:\s(\d+)/isx;
	}
}

sub _parse_sgos_version {
	my $self = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "_parse_sgos_version\n";
	}

	# parse  SGOS version, SGOS releaseid, and serial number
	if ($self->{'_debuglevel'} > 0) {
		print "VERSION INFO SECTION:\n";
		print $self->{'sgos_sysinfo_sect'}{'Version Information'} . "\n";
	}

	# SGOS version
	# #Version Information
	# URL_Path /SYSINFO/Version
	# Blue Coat Systems, Inc., ProxySG Appliance Version Information
	# Version: SGOS 4.2.10.1
	#
	if (defined($self->{'sgos_sysinfo_sect'}{'Version Information'})) {
		($self->{'sgosversion'}) =
		  $self->{'sgos_sysinfo_sect'}{'Version Information'} =~
		  m/Version:\sSGOS\s(\d+\.\d+\.\d+\.\d+)/im;
		if ($self->{'_debuglevel'} > 0) {
			print "SGOS version = $self->{'sgosversion'}\n";
		}
	}
}

=head2 send_command

Takes one parameter: a scalar that contains configuration commands to send to the appliance.
This command is executed in configuration mode.

	my $output = $bc->send_command('show version');
	# or
	my $commands =qq{
		int 0:0
		speed 100
	};
	my $output = $bc->send_command($commands);

=cut

sub send_command {
	my $self    = shift;
	my $command = shift;
	if ($self->{'_debuglevel'} > 0) {
		print "begin sub:send_command\n";
		print "command=$command\n";
	}
	if (!defined($self->{'_lwpua'})) {
		$self->_create_ua();
	}
	my $request = POST $self->{'_applianceurlbase'} . $_URL{'send_command'},
	  Content_Type => 'form-data',
	  'Content'    => ['file' => $command];
	$request->authorization_basic($self->{'_applianceusername'},
		$self->{'_appliancepassword'});
	my $response = $self->{'_lwpua'}->request($request);
	my $content;
	if ($response->is_success) {
		$content = $response->content;
	}
	else {
		die 'error';
	}
	$content =~ s/\r//ig;
	return $content;
}

=head2 Other Data

Other data that is directly accessible in the object:

	Appliance Name:   $bc->{'appliance-name'}
	Model Number:     $bc->{'modelnumber'}
	Serial Number:    $bc->{'serialnumber'}
	SGOS Version:     $bc->{'sgosversion'}
	Release ID:       $bc->{'sgosreleaseid'}
	Default Gateway:  $bc->{'ip-default-gateway'}
	Sysinfo Time:     $bc->{'sysinfotime'}
	Accelerator Info: $bc->{'ssl-accelerator'}

	The software configuration can be retrieved as follows:
		$bc->{'sgos_sysinfo_sect'}{'Software Configuration'}

	Other sections that can be retrieved:
		$bc->{'sgos_sysinfo_sect'}{'Software Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'ADN Compression Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'ADN Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'ADN Node Info'}
		$bc->{'sgos_sysinfo_sect'}{'ADN Sizing Peers'}
		$bc->{'sgos_sysinfo_sect'}{'ADN Sizing Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'ADN Tunnel Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'AOL IM Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Access Log Objects'}
		$bc->{'sgos_sysinfo_sect'}{'Access Log Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Authenticator Memory Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Authenticator Realm Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Authenticator Total Realm Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'CCM Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'CCM Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'CIFS Memory Usage'}
		$bc->{'sgos_sysinfo_sect'}{'CIFS Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'CPU Monitor'}
		$bc->{'sgos_sysinfo_sect'}{'CacheEngine Main'}
		$bc->{'sgos_sysinfo_sect'}{'Configuration Change Events'}
		$bc->{'sgos_sysinfo_sect'}{'Content Filter Status'}
		$bc->{'sgos_sysinfo_sect'}{'Core Image'}
		$bc->{'sgos_sysinfo_sect'}{'Crypto Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'DNS Cache Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'DNS Query Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Disk 1'}
		... and up to Disk 10, in some cases
		$bc->{'sgos_sysinfo_sect'}{'Endpoint Mapper Internal Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Endpoint Mapper Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Endpoint Mapper database contents'}
		$bc->{'sgos_sysinfo_sect'}{'FTP Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Forwarding Settings'}
		$bc->{'sgos_sysinfo_sect'}{'Forwarding Statistics Per IP'}
		$bc->{'sgos_sysinfo_sect'}{'Forwarding Summary Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Forwarding health check settings'}
		$bc->{'sgos_sysinfo_sect'}{'Forwarding health check statistics'}
		$bc->{'sgos_sysinfo_sect'}{'HTTP Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'HTTP Main'}
		$bc->{'sgos_sysinfo_sect'}{'HTTP Requests'}
		$bc->{'sgos_sysinfo_sect'}{'HTTP Responses'}
		$bc->{'sgos_sysinfo_sect'}{'Hardware Information'}
		$bc->{'sgos_sysinfo_sect'}{'Hardware sensors'}
		$bc->{'sgos_sysinfo_sect'}{'Health Monitor'}
		$bc->{'sgos_sysinfo_sect'}{'Health check entries'}
		$bc->{'sgos_sysinfo_sect'}{'Health check statistics'}
		$bc->{'sgos_sysinfo_sect'}{'ICP Hosts'}
		$bc->{'sgos_sysinfo_sect'}{'ICP Settings'}
		$bc->{'sgos_sysinfo_sect'}{'ICP Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'IM Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'Kernel Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Licensing Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Client Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Conversation Client Errors'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Conversation Other Errors'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Conversation Server Errors'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Errors'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Internal Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Server Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'MAPI Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'MMS Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'MMS General'}
		$bc->{'sgos_sysinfo_sect'}{'MMS Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'MMS Streaming Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'MSN IM Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'OPP Services'}
		$bc->{'sgos_sysinfo_sect'}{'OPP Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'P2P Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Persistent Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Policy Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Policy'}
		$bc->{'sgos_sysinfo_sect'}{'Priority 1 Events'}
		$bc->{'sgos_sysinfo_sect'}{'Quicktime Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'Quicktime Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'RIP Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Real Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'Real Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Refresh Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'SCSI Disk Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'SOCKS Gateways Settings'}
		$bc->{'sgos_sysinfo_sect'}{'SOCKS Gateways Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'SOCKS Proxy Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'SSL Proxy Certificate Cache'}
		$bc->{'sgos_sysinfo_sect'}{'SSL Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Security processor Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Server Side persistent connections'}
		$bc->{'sgos_sysinfo_sect'}{'Services Management Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Services Per-service Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Services Proxy Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Software Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'System Memory Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'TCP/IP ARP Information'}
		$bc->{'sgos_sysinfo_sect'}{'TCP/IP Listening list'}
		$bc->{'sgos_sysinfo_sect'}{'TCP/IP Malloc Information'}
		$bc->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'}
		$bc->{'sgos_sysinfo_sect'}{'TCP/IP Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Threshold Monitor Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Version Information'}
		$bc->{'sgos_sysinfo_sect'}{'WCCP Configuration'}
		$bc->{'sgos_sysinfo_sect'}{'WCCP Statistics'}
		$bc->{'sgos_sysinfo_sect'}{'Yahoo IM Statistics'}
		

	The details for interface 0:0 are stored here:
		IP address:   $bc->{'interface'}{'0:0'}{'ip'} 
		Netmask:      $bc->{'interface'}{'0:0'}{'netmask'} 
		MAC address:  $bc->{'interface'}{'0:0'}{'mac'} 
		Link status:  $bc->{'interface'}{'0:0'}{'linkstatus'} 
		Capabilities: $bc->{'interface'}{'0:0'}{'capabilities'} 

	You can retrieve the interface names like this:
		my @interfaces = keys %{$bc->{'interface'}};

	The route table can	be retrieved as follows:
		$bc->{'sgos_sysinfo_sect'}{'TCP/IP Routing Table'}

	The static route table can be retrieved as follows:
		$bc->{'static-route-table'}

	The WCCP configuration can be retrieved as follows:
		$bc->{'sgos_sysinfo_sect'}{'WCCP Configuration'}


=cut

=head1 AUTHOR

Matthew Lange <mmlange@cpan.org>

=head1 BUGS

Please report any bugs or feature requests through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BlueCoat-SGOS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BlueCoat::SGOS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BlueCoat-SGOS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BlueCoat-SGOS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BlueCoat-SGOS>

=item * Search CPAN

L<http://search.cpan.org/dist/BlueCoat-SGOS/>

=back


=head1 LICENSE

Copyright (C) 2008-2012 Matthew Lange

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License version 2 as 
published by the Free Software Foundation.

=cut

1;    # End of BlueCoat::SGOS

__DATA__
