package App::DNS::Adblock;
{
  $App::DNS::Adblock::VERSION = '0.015';
}

use strict;
use warnings;

use Net::DNS 0.74;
use Net::DNS::Nameserver;
use Sys::HostIP;
use Capture::Tiny qw(capture);
use LWP::Simple qw($ua getstore);
$ua->agent("");
use Mozilla::CA;

use POSIX qw( strftime );
use Carp;

use Data::Dumper;

use Storable qw(freeze thaw);

my $attributes;

sub new {
	my ( $class, %self ) = @_;
	my $self = { %self };
	bless $self, $class;

	$attributes = freeze($self);
	$self->read_config();

	my $host = Sys::HostIP->new;
	my %devices = reverse %{ $host->interfaces };
	my $hostip = $host->ip;

	$self->{interface} = $devices{ $hostip };
	$self->{host} = $hostip unless $self->{host};
	$self->{port} = 53 unless $self->{port};
	$self->{debug} = 0 unless $self->{debug};

	my $ns = Net::DNS::Nameserver->new(
		LocalAddr    => $self->{host},
		LocalPort    => $self->{port},
		ReplyHandler => sub { $self->reply_handler(@_); },
		Verbose	     => ($self->{debug} > 1 ? 1 : 0)
	) || die "couldn't create nameserver object:  $!";

	$self->{nameserver} = $ns;

	my $res = Net::DNS::Resolver->new(
		nameservers => [ @{ $self->{forwarders} } ],
		port	    => $self->{forwarders_port} || 53,
		recurse     => 1,
		debug       => ($self->{debug} > 2 ? 1 : 0),
	);

	$self->{resolver} = $res;

	return $self;
}

sub run {
	my ( $self ) = shift;

	$self->set_local_dns() if $self->{setdns};

	$SIG{KILL} = sub { $self->signal_handler(@_) };
	$SIG{QUIT} = sub { $self->signal_handler(@_) };
	$SIG{TERM} = sub { $self->signal_handler(@_) };
	$SIG{INT}  = sub { $self->signal_handler(@_) };
	$SIG{HUP}  = sub { $self->read_config() };

	$self->log("nameserver accessible locally @ $self->{host}", 1);

	$self->{nameserver}->main_loop;
};

sub set_local_dns {
	my ( $self ) = shift;

	my $stdout;
	my $stderr;
	my @result;

        if ($^O	=~ /darwin/i) {                                                          # is osx
	        eval {
	                ($self->{service}, $stderr, @result) = capture { system("networksetup -listallhardwareports | grep -B 1 $self->{interface} | cut -c 16-32") };
			if ($stderr || ($result[0] < 0)) {
			       die $stderr || $result[0];
			} else {
			       $self->{service} =~ s/\n//g;
			       system("networksetup -setdnsservers $self->{service} $self->{host}");
			       system("networksetup -setsearchdomains $self->{service} empty");
			}
		}
	}

	if (!grep { $^O eq $_ } qw(VMS MSWin32 os2 dos MacOS darwin NetWare beos vos)) { # is unix
	        eval {
	                ($stdout, $stderr, @result) = capture { system("cp /etc/resolv.conf /etc/resolv.bk") };
			if ($stderr || ($result[0] < 0)) {
			       die $stderr || $result[0];
			} else {
			       open(CONF, ">", "/etc/resolv.conf");
			       print CONF "nameserver $self->{host}\n";
			       close CONF;
			}
                }
	}

	if ($stderr||$result[0]) {
	       $self->log("switching of local dns settings failed: $@", 1);
	       undef $self->{setdns};
	} else {
	       $self->log("local dns settings ($self->{interface}) switched", 1);
	}
}

sub restore_local_dns {
	my ( $self ) = shift;

	my $stdout;
	my $stderr;
	my @result;

        if ($^O	=~ /darwin/i) {                                                         # is osx
	        eval {
		        ($stdout, $stderr, @result) = capture { system("networksetup -setdnsservers $self->{service} empty") };
			if ($stderr || ($result[0] < 0)) {
			       die $stderr || $result[0];
			} else {
                               system("networksetup -setsearchdomains $self->{service} empty");
			}
                }
	}

	if (!grep { $^O eq $_ } qw(VMS MSWin32 os2 dos MacOS darwin NetWare beos vos)) { # is unix
	        eval {
                        ($stdout, $stderr, @result) = capture { system("mv /etc/resolv.bk /etc/resolv.conf") };
			die $stderr || $result[0];
                }
        }

	($stderr||$result[0]) ? $self->log("local dns settings failed to restore: $@", 1)
	        : $self->log("local dns settings restored", 1);
}

sub signal_handler {
	my ( $self, $signal ) = @_;

	$self->log("shutting down: signal $signal");

    $self->restore_local_dns() if $self->{setdns};

	exit;
}

sub reply_handler {
	my ($self, $qname, $qclass, $qtype, $peerhost, $query,$conn) = @_;

	my ($rcode, @ans, @auth, @add);

 	if ($self->{adfilter} && ($qtype eq 'AAAA' || $qtype eq 'A' || $qtype eq 'PTR')) {
    
 		if (my $ip = $self->query_adfilter( $qname, $qtype )) {

                 	$self->log("received query from $peerhost: qtype '$qtype', qname '$qname'");
 			$self->log("[local] resolved $qname to $ip NOERROR");

 			my ($ttl, $rdata) = ( 300, $ip );
        
 			push @ans, Net::DNS::RR->new("$qname $ttl $qclass $qtype $rdata");

 			$rcode = "NOERROR";
      
 			return ($rcode, \@ans, \@auth, \@add, { aa => 1, ra => 1 });
 		}
 	}

	my $answer = $self->{resolver}->send($qname, $qtype, $qclass);

	if ($answer) {

       	        $rcode = $answer->header->rcode;
       	        @ans   = $answer->answer;
       	        @auth  = $answer->authority;
       	        @add   = $answer->additional;
    
	        $self->log("[proxy] response from remote resolver: $qname $rcode");

		return ($rcode, \@ans, \@auth, \@add);
	} else  {

		$self->log("[proxy] can not resolve $qtype $qname - no answer from remote resolver. Sending NXDOMAIN response.");

		$rcode = "NXDOMAIN";

		return ($rcode, \@ans, \@auth, \@add, { aa => 1, ra => 1 });
	}
}

sub log {
	my ( $self, $msg, $force_flag ) = @_;
	print "[" . strftime('%Y-%m-%d %H:%M:%S', localtime(time)) . "] " . $msg . "\n" if $self->{debug} || $force_flag;
}

sub read_config {
	my $self = shift;
	my $attributes = thaw($attributes);
	for ( keys %{$attributes} ) { $self->{$_} = $attributes->{$_} };                   # HUP restore

        my $cache = ();

	$self->{forwarders} = ([ $self->parse_resolv_conf() ]);                            # /etc/resolv.conf

        if ($self->{adblock_stack}) {
        	for ( @{ $self->{adblock_stack} } ) {
 	                $cache = { $self->load_adblock_filter($_) };                       # adblock plus hosts
                        %{ $self->{adfilter} } = $self->{adfilter} ? ( %{ $self->{adfilter} }, %{ $cache } ) 
                                         : %{ $cache };
	        }
	}
        if ($self->{blacklist}) {
 	        $cache = { $self->parse_single_col_hosts($self->{blacklist}) };    # local, custom hosts
                %{ $self->{adfilter} } = $self->{adfilter} ? ( %{ $self->{adfilter} }, %{ $cache } ) 
                                         : %{ $cache };
 	}
        if ($self->{whitelist}) {
 	        $cache = { $self->parse_single_col_hosts($self->{whitelist}) };    # remove entries
                for ( keys %{ $cache } ) { delete ( $self->{adfilter}->{$_} ) };
 	}

#	$self->dump_adfilter;

 	return;
}

sub query_adfilter {
	my ( $self, $qname, $qtype ) = @_;

	return $self->search_ip_in_adfilter( $qname ) if  ($qtype eq 'A' || $qtype eq 'AAAA');
	return $self->search_hostname_by_ip( $qname ) if $qtype eq 'PTR';
}

sub search_ip_in_adfilter {
        my ( $self, $hostname ) = @_;

	my $trim = $hostname;
	my $sld = $hostname;
	my $loopback = $self->{loopback} || '127.0.0.1';

	$trim =~ s/^www\.//i;
	$sld =~ s/^.*\.(.+\..+)$/$1/;

	return $loopback if ( exists $self->{adfilter}->{$hostname} ||
			  exists $self->{adfilter}->{$trim} ||
			  exists $self->{adfilter}->{$sld} );
        return;
}

sub search_hostname_by_ip {
	my ( $self, $ip ) = @_;

	$ip = $self->get_in_addr_arpa( $ip ) || return;
}

sub get_in_addr_arpa {
	my ( $self, $ptr ) = @_;

	my ($reverse_ip) = ($ptr =~ m!^([\d\.]+)\.in-addr\.arpa$!);
	return unless $reverse_ip;
	my @octets = reverse split(/\./, $reverse_ip);
	return join('.', @octets);
}

sub parse_resolv_conf {
	my ( $self ) = shift;

	return @{$self->{forwarders}} if $self->{forwarders};

	$self->log('reading /etc/resolv.conf file');

	my @dns_servers;

	open (RESOLV, "/etc/resolv.conf") || croak "cant open /etc/resolv.conf file: $!";

	while (<RESOLV>) {
		if (/^nameserver\s+([\d\.]+)/) {
			push @dns_servers, $1;
		}
	}

	close (RESOLV);
	croak "no nameservers listed in /etc/resolv.conf!" unless @dns_servers;
	return @dns_servers;
}

sub load_adblock_filter {
	my ( $self ) = shift;
	my %cache;

	my $hostsfile = $_->{path} or die "adblock {path} is undefined";
	my $refresh = $_->{refresh} || 7;
	my $age = -M $hostsfile || $refresh;

	if ($age >= $refresh) {
        	my $url = $_->{url} or die "attempting to refresh $hostsfile failed as {url} is undefined";
	        $url =~ s/^\s*abp:subscribe\?location=//;
                $url =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
                $url =~ s/&.*$//;
	        $self->log("refreshing hosts: $hostsfile", 1);
	        getstore($url, $hostsfile);
	}

	%cache = $self->parse_adblock_hosts($hostsfile);

	return %cache;
}

sub parse_adblock_hosts {
	my ( $self, $hostsfile ) = @_;
	my %hosts;

	open(HOSTS, $hostsfile) or die "cant open $hostsfile file: $!";

	while (<HOSTS>) {
	        chomp;
                next unless s/^\|\|(.*)\^(\$third-party)?$/$1/;  #extract adblock host
		$hosts{$_}++;
	}

	close(HOSTS);

	return %hosts;
}

sub parse_single_col_hosts {
	my ( $self, $hostsfile ) = @_;
	my %hosts;

	open(HOSTS, $hostsfile) or die "cant open $hostsfile file: $!";

	while (<HOSTS>) {
	        chomp;
		next if /^\s*#/; # skip comments
		next if /^$/;    # skip empty lines
		s/\s*#.*$//;     # delete in-line comments and preceding whitespace
		$hosts{$_}++;
	}

	close(HOSTS);

	return %hosts;
}

sub dump_adfilter {
	my $self = shift;

	my $str = Dumper(\%{ $self->{adfilter} });
	open(OUT, ">/var/named/adfilter_dumpfile") or die "cant open dump file: $!";
	print OUT $str;
	close OUT;
}

1;

=head1 NAME

App::DNS::Adblock - A lightweight DNS ad filter

=head1 VERSION

version 0.015

=head1 DESCRIPTION

This is an ad filter for use in a local area network. Its function is to load 
lists of ad domains and answer DNS queries for those domains with a loopback 
address. Any other DNS queries are forwarded upstream, either to a specified 
list of nameservers or to those listed in /etc/resolv.conf. 

The module loads externally maintained lists of ad hosts intended for use 
by the I<adblock plus> Firefox extension. Use of the lists focuses only on 
third-party listings that define dedicated advertising and tracking hosts.

A custom blacklist and/or whitelist can also be loaded. In this case, host 
listings must conform to a one host per line format.

Once running, local network dns queries can be addressed to the host's ip.

=head1 SYNOPSIS

    my $adfilter = App::DNS::Adblock->new();

    $adfilter->run();

Without any parameters, the module will function simply as a proxy, forwarding all 
requests upstream to predefined nameservers.

=head1 ATTRIBUTES

=head2 adblock_stack

    my $adfilter = App::DNS::Adblock->new(

        adblock_stack => [
            {
            url => 'http://pgl.yoyo.org/adservers/serverlist.php?hostformat=adblockplus&showintro=0&startdate[day]=&startdate[month]=&startdate[year]=&mimetype=plaintext',
	    path => '/var/named/pgl-adblock.txt',     #path to ad hosts
            refresh => 7,                             #refresh value in days (default = 7)
            },

            {
            url => 'abp:subscribe?location=https%3A%2F%2Feasylist-downloads.adblockplus.org%2Feasyprivacy.txt&title=EasyPrivacy&requiresLocation=https%3A%2F%2Feasylist-downloads.adblockplus.org%2Feasylist.txt&requiresTitle=EasyList';
            path => '/var/named/easyprivacy.txt',
            refresh => 5,
            },
        ],
    );

The adblock_stack arrayref encloses one or more hashrefs composed of three 
parameters: a url that returns a list of ad hosts in adblock plus format; 
a path string that defines where the module will write a local copy of 
the list; a refresh value that determines what age (in days) the local copy 
may be before it is refreshed.

A collection of lists is available at http://adblockplus.org/en/subscriptions. 
The module will accept standard or abp:subscribe? urls. You can cut and paste 
encoded links directly.

=head2 blacklist

    my $adfilter = App::DNS::Adblock->new(
        blacklist => '/var/named/blacklist',  #path to secondary hosts
    );

A path string that defines where the module will access a local list of ad hosts. 
A single column is the only acceptable format:

    # ad nauseam
    googlesyndication.com
    facebook.com
    twitter.com
    ...

=head2 whitelist

    my $adfilter = App::DNS::Adblock->new(

        whitelist => '/var/named/whitelist',  #path to exclusions
    );

A path string to a single column list of hosts. These hosts will be removed from the filter.

=head2 host, port

    my $adfilter = App::DNS::Adblock->new( host => $host, port => $port );

The IP address to bind to. If not defined, the server attempts binding to the local ip.
The default port is 53.

=head2 forwarders, forwarders_port

    my $adfilter = App::DNS::Adblock->new( forwarders => [ nameserver, ], forwarders_port => $port );

An arrayref of one or more nameservers to forward any DNS queries to. Defaults to nameservers 
listed in /etc/resolv.conf. The default port is 53. Windows machines should define a forwarder to avoid 
the default behavior.

=head2 setdns

    my $adfilter = App::DNS::Adblock->new( setdns  => '1' ); #defaults to '0'

If set, the module attempts to set local dns settings to the host's ip. This may or may not work
if there are multiple active interfaces. You may need to manually adjust your local dns settings.

=head2 loopback

    my $adfilter = App::DNS::Adblock->new( loopback  => '127.255.255.254' ); #defaults to '127.0.0.1'

If set, the nameserver will return this address rather than the standard loopback address.

=head2 debug

    my $adfilter = App::DNS::Adblock->new( debug => '1' ); #defaults to '0'

The debug option logs actions to stdout and can be set from 1-3 with increasing output: the module will 
feedback (1) adfilter.pm logging, (2) nameserver logging, and (3) resolver logging. 

=head1 CAVEATS

Tested under darwin only.

=head1 AUTHOR

David Watson <dwatson@cpan.org>

=head1 SEE ALSO

scripts/ in the distribution

This module is essentially a lightweight, non-Moose version of Net::DNS::Dynamic::Adfilter

=head1 COPYRIGHT AND LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut
