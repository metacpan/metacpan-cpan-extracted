#
# $Id: ProxyConf.pm,v 1.2 2005/03/16 10:29:58 pschoo Exp $
# $Source: /cvs-mis/local/web/proxyconf/ProxyConf.pm,v $
#

package Apache::ProxyConf;

$^W=1;
use strict;
use vars qw($VERSION);
$VERSION = '1.0';

use Apache::Constants qw(:common);
use Apache::Log ();
use Config::IniFiles;
use Net::IPv4Addr qw(/^ipv4/);

my %cfname;	# Hash of configuration filenames per Location.
my %conf;	# Hash of parsed configuration files.
my %lastmod;	# Modification times of configuration files.

#
# Send header with proper content type. Add some HTML codes when the
# debugging option is enabled.
#

sub send_header {
        my($r, $debug) = @_;

	if ($debug) {
		$r->content_type('text/html');
		$r->send_http_header;
		print <<END;
<html>
<head>
<title>Output of ProxyConf.pm with debug option</title>

<style type="text/css">
code {
  font-family: LucidaTypewriter, Courier, "Courier New", monospace;
  color: #990000;
}
</style>
</head>
<body bgcolor="#FFFFFF">
<h1>Output of ProxyConf.pm with debug option</h1>
<pre>
END

	} else {
		$r->content_type('application/x-ns-proxy-autoconfig');
		$r->send_http_header;
	}
}

#
# Send trailer to close HTML statements properly.
#

sub send_trailer {
        my($debug) = @_;

	if ($debug) {
		print <<END;
</pre>
</body>
</html>
END

	}
}

#
# Return a default proxy autoconfig script when the configuration file is not
# defined, or cannot be opened.
#

sub default_config {
        my($r, $debug) = @_;
	
	send_header($r, $debug);
	print "<code>\n" if $debug;
	print <<END;
// Default configuration.
// The configuration file is not defined or cannot be opened.
function FindProxyForURL(url, host)
{
	return "DIRECT";
}
END

	print "</code>\n" if $debug;
	send_trailer($debug);
}

#
# Calculate the used subnet masklengths for all networks in a specified
# section.
#

sub calcsubnets {
	my($conf, $section) = @_;
	my %subnets = ();

	my @networks = $conf->Parameters($section);
	foreach my $network (@networks) {
		my($ip,$masklength) = ipv4_parse($network);
		$subnets{$masklength} = 1;
	}
	$conf->newval($section, "subnets", join ",",
		reverse sort keys %subnets);
}

#
# Turn the IP address into a unique number.
#

sub binaryip {
	my ($ip) = @_;

	my @flds = split(/\./, $ip, 4);
	if (scalar @flds != 4) {
		warn "Illegal IP address: $ip";
		return(0);
	}
	my $binip = $flds[0] << 24 | $flds[1] << 16 | $flds[2] << 8 | $flds[3];
	return($binip);
}

#
# Process a single value from the .ini file, and calculate the order
# in which the proxies are used.
#

sub processvalue {
        my($value, $ip, $rotate) = @_;
	my(@list);

	@list = ();
	while ($value ne "") {
		# Process a single proxy on the list.
		if ($value =~ /^\d+\.\d+\.\d+\.\d+:\d+$/) {
			push(@list, $value);
			$value = "";
		# Process first proxy before the comma separator.
		} elsif ($value =~ /^(\d+\.\d+\.\d+\.\d+:\d+),(.*)$/) {
			push(@list, $1);
			$value = $2;
		# Process proxies between brackets.
		} elsif ($value =~ /^\(([\d.:,]+)\)$/) {
			push(@list, processvalue($1, $ip, 1));
			$value = "";
		# Process proxies between brackets, before the comma separator.
		} elsif ($value =~ /^\((.*?)\),(.*)$/) {
			push(@list, processvalue($1, $ip, 1));
			$value = $2;
		} else {
			warn "Syntax error: $value";
			$value = "";
		}
	}
	if ($rotate && (scalar @list > 0)) {
		# For proxies that were specified between brackets, distribute
		# the load. Rotate the proxy list a number of times based on
		# the IP address of the client.
		for (1..(binaryip($ip) % scalar @list)) {
			push(@list, shift(@list));
		}
	}
	return @list;
}

#
# Determine the settings for a given section.
#

sub getproxyconf {
	my ($ipaddr, $conf, $section, $debug) = @_;

	my $subnet;
	my $value;
	my @proxylist;
	my @proxypriolist;
	my @uniqproxy;
	my @subnets = split /,/, $conf->val($section, "subnets");

	if ($debug) {
		printf "Processing section: $section\n";
		print "  subnets: ";
		print $conf->val($section, "subnets");
		print "\n";
	}

	# Check all relevant subnets starting with the largest masklength,
	# and store all found entries in a list.

	foreach $subnet (@subnets) {
		my $try = ipv4_network($ipaddr . "/" . $subnet);
		printf "  Trying $try\n" if $debug;
		if (defined $conf->val($section, $try)) {
			$value = join ',', $conf->val($section, $try);
			printf "    Found $value\n" if $debug;
			push(@proxypriolist, $value);
		}
	}

	# Parse the proxy lines in the 'proxy' and 'https' section and create
	# a list of single proxies.

	if (($section eq "proxy") || ($section eq "https")) {
		foreach (@proxypriolist) {
			push(@proxylist, processvalue($_, $ipaddr, 0));
		}
	} else {
		foreach (@proxypriolist) {
			push(@proxylist, @proxypriolist);
		}
	}

	# Remove duplicate proxies.
	my %seen = ();
	my $proxy;
	foreach $proxy (@proxylist) {
		push(@uniqproxy, $proxy) unless $seen{$proxy}++;
	}
	if ($debug) {
		print "  $section: ";
		print join ',', @uniqproxy;
		print "\n";
	}
	return join ',', @uniqproxy;
}

#
# Generate the javascript that is returned to the browser.
#

sub buildpacfunc {
	my ($proxy, $noproxy, $https, $debug) = @_;

	my $rv;
	my $np;
	my @noproxy = split(',', $noproxy);

	$rv .= "function FindProxyForURL(url, host) {\n";
	foreach $np (@noproxy) {
		$rv .= "\tif ";
		my $text = "(shExpMatch(host, %)) return \"DIRECT\";\n";
		$text =~ s/%/"$np"/;
		$rv .= $text;
	}
	if ($https ne "") {
		$rv .= "\tif (shExpMatch(url, \"https://*\")) ";
		$https =~ s/,/; PROXY /g;
		$rv .= "return \"PROXY $https\";\n";
	}
	if ($proxy ne "") {
		$proxy =~ s/,/; PROXY /g;
		$rv .= "\treturn \"PROXY $proxy\";\n";
		$rv .= "}\n";
	} else {
		warn "No rule defined for $ENV{\"REMOTE_ADDR\"}" if (!$debug);
		$rv .= "\treturn \"DIRECT\";\n";
		$rv .= "}\n";
	}
	return $rv;
}

#
# The main routine.
#

sub handler {
	my $r = shift;

	# $debug;  Output is displayed in html when this variable is set.
	my %args = $r->args;
	my $debug = $args{"debug"};
	my $ipaddr = $args{"ipaddr"};
	my $extra_no_proxy = $args{"noproxy"};

	if (!defined($debug)) {
		$debug = 0;
	}
	# See if we have found the configuration filename for this
	# <Location>.
	if (!$cfname{$r->location}) {
		$r->log->warn("Reading config for " . $r->location);
		$cfname{$r->location} = $r->dir_config('ProxyConfConfig');
		if (!$cfname{$r->location}) {
			$r->log->error("Variable ProxyConfConfig not defined "
				. "for Location " . $r->location);
			$cfname{$r->location} = "undefined";
		} else {
			if (! -e $cfname{$r->location}) {
				$r->log->error("Configfile " .
					$cfname{$r->location} .
					" does not exist");
			}
		}
	}
	my $configfile = $cfname{$r->location};
	# Return a default configuration in case we cannot read the
	# configuration file or if it is not specified.
	if (($configfile eq "undefined") or ! -e $configfile) {
		default_config($r, $debug);
		return OK;
	}
	my $modtime = (stat _)[9];
	# Reading the configuration is expensive. Read it once, and reread
	# it when the modification time has changed.
	if (!$lastmod{$configfile} or ($lastmod{$configfile} != $modtime)) {
		if ($conf{$configfile}) {
			$conf{$configfile}->ReadConfig();
			$r->log->warn("Config file $configfile reloaded");
		} else {
			$conf{$configfile} = new Config::IniFiles(
				-file => "$configfile");
			$r->log->warn("Config file $configfile loaded");
		}
		calcsubnets($conf{$configfile}, "proxy");
		calcsubnets($conf{$configfile}, "noproxy");
		calcsubnets($conf{$configfile}, "https");
		$lastmod{$configfile} = $modtime;
	}
	send_header($r, $debug);
	if (defined($ipaddr) and $ipaddr =~ /(\d*\.\d*\.\d*\.\d*)/) {
		$ENV{"REMOTE_ADDR"} = $1;
	}

	my $remote_addr;
	if ($ENV{"REMOTE_ADDR"}) {
		$remote_addr = $ENV{"REMOTE_ADDR"};
	} else {
		print STDERR "Unknown remote address: using 0.0.0.0\n";
		$remote_addr = "0.0.0.0";
	}
	my $pc = getproxyconf($remote_addr, $conf{$configfile}, "proxy",
		$debug);
	my $np = getproxyconf($remote_addr, $conf{$configfile}, "noproxy",
		$debug);
	my $https = getproxyconf($remote_addr, $conf{$configfile}, "https",
		$debug);
	if (defined($extra_no_proxy)) {
		$np .= "," . $extra_no_proxy;
	}

	print "<code>\n" if $debug;
	printf "// Client IP address: %s \n\n", $remote_addr;
	my $pacscript = buildpacfunc($pc, $np, $https, $debug);
	print $pacscript;
	print "</code>\n" if $debug;
	send_trailer($debug);
	return OK;
}

1;

__END__

=head1 NAME

Apache::ProxyConf - Generate Proxy Configuration for browsers.

=head1 SYNOPSIS

  # In httpd.conf:

  <Location />
    SetHandler perl-script
    PerlHandler Apache::ProxyConf
    PerlSetVar ProxyConfConfig "/some/location/proxyconf.ini"
  </Location>

=head1 DESCRIPTION

The Apache::ProxyConf is used to configure the proxy settings in browsers
automatically. The modules returns a script that conforms to the Navigator
Proxy Auto-Config File Format. The module is suitable for large scale
installations that have multiple (cascading) proxies. It can be used
to return 'the closest proxy' based on the network topology. Failover and
load distribution is also provided.

=head2 Browser configuration

The (virtual) webserver must be entered in the 'Autoconfigure URL' of the
browser to make use of the ProxyConf script.

http://proxyconf.some.domain/

In IE the URL must be specified in the 'Address' field, just below the
'Use automatic configuration script' tickbox.

=head1 THE CONFIGURATION FILE

The ProxyConf module first reads a .ini-style configuration file to determine
the proxy settings of the network. The configuration file contains three
sections: proxy, noproxy and https.

=head2 The proxy section

The sections proxy and https have an identical format. They contain lines of
the form C<subnet=proxyip:port>.

=over 4

=item Single proxy

 [proxy]
 172.16.32.0/20=172.16.32.10:3128

The subnet 172.16.32.0/20 has a single proxy defined. The proxy server is
172.16.32.10 and it listens on port 3128.

=item Multiple proxies

 [proxy]
 172.16.0.0/20=172.16.0.10:3128,172.16.0.20:3128

Multiple proxy servers are defined in a comma separated list. In this
example clients in the 172.16.0.0/20 subnet use 172.16.0.10 as their primary
proxy server. When this server becomes unavailable, the clients will move over
to 172.16.0.20 for their proxy requests.

=item Multiple proxies with load distribution

 [proxy]
 172.16.0.0/20=(172.16.0.10:3128,172.16.0.20:3128)

When proxy servers are placed between brackets, the load is distribution
amongst the proxies. Some clients will have the first proxy as primary and some
clients will have the second proxy as primary. The other proxy is used as a
backup. The order in which the proxies are tried depends on the IP address of
the client. The script is deterministic, so for a given IP address the
priority list is always the same. 

=back

To determine the proxy list for a given IP address multiple rules may be
applied. Subnets are tried from the highest to the lowest mask. The module
puts all proxies that are found in a list.

=head2 The noproxy section

The noproxy section contains hosts that should be contacted by the clients
directly. Noticeably, web servers that use NTLM authentication will not work
when clients connect to them via a proxy server. The syntax for specifying
noproxy hosts is C<subnet=fqhn1,fqhn2,..>. Alternatively, the multiline
syntax can be used, as shown in this example.

 [noproxy]
 0.0.0.0/0=<<EOT
 webserver1.some.domain
 webserver2.some.domain
 EOT

This section defines webservers that are non-proxyable for all networks.

=head2 The https section

The https section works like the proxy section. It is used to define
other proxies for secure HTTP traffic than for the normal HTTP traffic.
If this section is missing, or for a specific IP address
there are no https rules, then the normal proxy rules apply.

=head1 EXAMPLE

Consider the network in figure 1. 

          Network A: 172.16.0.0/20

             _.-"""""""""""""""""-._
           .'                       `.
          /                           \
        |    Proxy A1: 172.16.0.10    |
        |                             |
        |    Proxy A2: 172.16.0.20    |
         \                           /
          `._                     _.'\
             `-.................-'    \
                                       \
                                        \  Network B: 172.16.16.0/20
                                         \
                                          \ _.-"""""""""""""""""-._
                                          .'                       `.
                                         /                           \
                                        |                             |
                                        |    Proxy B: 172.16.16.10    |
                                        |                             |
                                         \                           /
                                          `._                     _.'
                                          /  `-.................-'
                                         /
                                        /
          Network C: 172.16.32.0/20    /
                                      /
            _.-"""""""""""""""""-._  /
          .'                       `.
         /                           \
        |                             |
        |    Proxy C: 172.16.32.10    |
        |                             |
         \                           /
          `._                     _.'
             `-.................-'

                                    Figure 1.

The proxies have the following connectivity:

 Proxy A1	Internet connectivity
 Proxy A2	Internet connectivity
 Proxy B	parents with proxy A1 and A2
 Proxy C	parents with proxy B and A1

Clients in the three networks need to get the following proxy configuration:

 172.16.0.0/20	Half of the clients connect to proxy A1 and use proxy A2
		as fallback, the other half use proxy A2 with A1 as
		fallback.
 172.16.16.0/20	Clients use proxy B with proxy A2 as fallback.
 172.16.32.0/20	Clients use proxy C with proxy B as fallback.

For secure HTTP traffic special rules apply. Because this traffic is not
cached all clients connect to proxy A1 and A2 directly spreading the load
equally.

This is how the proxyconf.ini looks:

 [proxy]
 172.16.0.0/20=(172.16.0.10:3128,172.16.0.20:3128)
 172.16.16.0/20=172.16.16.10:3128,172.16.0.20:3128
 172.16.32.0/20=172.16.32.10:3128,172.16.16.10:3128

 [https]
 172.16.0.0/16=(172.16.0.10:3128,172.16.0.20:3128)

=head1 EXTRA OPTIONS

It is possible to add additional noproxy hosts in the 'Autoconfigure URL' in
the browser. This way a local webserver can be tested without losing the
benefits of the proxy config. The following string must be entered in the
'Autoconfigure URL'.

http://proxyconf.some.domain/?noproxy=hostname.some.domain

Multiple hostnames are specified using a comma as separator.

http://proxyconf.some.domain/?noproxy=fqhn1,fqhn2 

=head1 DEBUGGING

The proxy config service can be called with a debug option. Type the following
URL in a browser:

http://proxyconf.some.domain/?debug=1&ipaddr=172.16.0.100

The script will generate a html page which contains the settings of all
variables and displays the script it sends to the browser for the specified
IP address. 

=head1 AUTHOR

Patrick Schoo <pschoo@playbeing.com>

Originally written by Bert Driehuis <driehuis@playbeing.org>
