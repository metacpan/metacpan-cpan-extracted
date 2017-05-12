# Cisco::Regex.pm
# $Id: Regex.pm,v 0.92 2014/05/21 17:56:28 jkister Exp $
# Copyright (c) 2014 Jeremy Kister.
# Released under Perl's Artistic License.

$Cisco::Regex::VERSION = "0.92";

=head1 NAME

Cisco::Regex - Utility to verify basic syntax of Cisco IOS standard
and extended IPv4 access-lists.

=head1 SYNOPSIS

  use Cisco::Regex;

  my $r = Cisco::Regex->new;
  my $std_regex = $r->regex('standard');
  my $ext_regex = $r->regex('extended');
    
  my $isok = $r->standard($line);
  my $isok = $r->extended($line);
  my $isok = $r->auto($line);

    
=head1 DESCRIPTION

C<Cisco::Regex> was made to lint access-lists before sending them to a
Cisco IOS device.  Only syntax checking is performed; no logical check
is even attempted.


=head1 CONSTRUCTOR

    my $r = Cisco::Regex->new( debug    => 0,
                               addr     => $addr_regex,
                               protocol => $protocol_regex,
                               network  => $network_regex,
                               port     => $port_regex,
                               ports    => $ports_regex,
                             )

=over 4

=item C<debug>

control ancillary/informational messages being printed.

ADVANCED OPTIONS

=item C<addr>

replace the built in 'addr' regex with the supplied regex.

=item C<protocol>

replace the built in 'protocol' regex with the supplied regex.

=item C<network>

replace the built in 'network' regex with the supplied regex.

=item C<port>

replace the built in 'port' regex with the supplied regex.

=item C<ports>

replace the built in 'ports' regex with the supplied regex.

=back

=head1 USAGE

=over 4

=item C<regex>

will return a regular expression for matching yourself.
Valid arguments are:

=over 4

=item C<addr>

returns what an ip address should look like

=item C<protocol>

returns what a protocol should look like

=item C<network>

returns what a network statement should look like

=item C<ports>

returns what port properties should look like

=item C<standard>

for access-list 1-99 & 1300-1999 syntax matching

=item C<extended>

for access-list 100-199 & 2000-2699 syntax matching

=back

=item C<standard>

check the provided line against the 'standard' regex.

=item C<extended>

check the provided line against the 'extended' regex.

=item C<auto>

checks if the line matches either a standard or an extended access-list

=back

=head1 EXAMPLES

  use strict;
  use Cisco::Regex;

  my @std_lines = ('access-list 15 permit 10.0.0.0 0.255.255.255',
                   'access-list 15 permit 10.0.0.0 0.255.255.255 any',
                  );
  for my $line (@std_lines){
    my $isok = $r->standard($line);
    if( $isok ){
        print "OK: $line\n";
    }else{
        print "BAD: $line\n";
    }
  }

  my @ext_lines = ('access-list 115 permit udp 10.0.0.0 0.255.255.255 eq 5060 any log',
                   'access-list 115 permit 10.0.0.0 0.255.255.255 any',
                  );

  for my $line (@ext_lines){
    my $isok = $r->extended($line);
    if( $isok ){
        print "OK: $line\n";
    }else{
        print "BAD: $line\n";
    }
  }

  my $acl = 'access-list 2100 permit tcp any 10.0.0.0 0.0.0.255 eq 22';
  my $ext_regex = $r->regex('extended');
  if( $acl =~ m/$ext_regex/ ){
       print "acl looks okay\n";
  }
    

=head1 CAVEATS aka TODO

=over 4

=item IPv4 only

=item named access-lists not supported

=item hosts/netmasks not checked to be on valid network boundaries

=item not all syntax is understood, e.g.: options values, precedence, tos, and time-range

=item syntax checking is good but not strict.  e.g.:

access-list 115 permit ip  any any eq http   (ip vs tcp)

access-list 115 permit tcp any any eq syslog (tcp vs udp)

access-list 115 permit 10.0.0.0 255.255.255.0 any (vs 0.0.0.255)


=back

=head1 AUTHOR

Jeremy Kister : http://jeremy.kister.net./

=cut

package Cisco::Regex;

use strict;

sub Version { $Cisco::Regex::VERSION }

sub new {
    my $class = shift;
    my %args = @_;

    my $addr = $args{addr} || 
     qr{
        (?:
         (?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})
         [.]
         (?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})
         [.]
         (?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})
         [.]
         (?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})
        )
      }x;
    
    my $protocol = $args{protocol} ||
     qr{
        (?:
         ahp|eigrp|esp|gre|icmp|igmp|ip|ipinip|nos|ospf|pcp|pim|tcp|udp
         |
         (?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})
        )
       }x;
    
    my $network = $args{network} || 
     qr{
        (?:host\s+\S+)
        |
        (?:$addr\s+$addr)
        |
        any
       }x;

    my $port = $args{port} ||
     qr{
        (?:
           6553[0-5]
           |
           655[0-2]\d
           |
           65[0-4]\d{2}
           |
           6[0-4]\d{3}
           |
           [1-5]\d{4}
           |
           [1-9]\d{1,3}
           |
           \d
        )
       }x;

    my $pnames = $args{pnames} ||
     qr{ 
        (?:bgp|chargen|cmd|daytime|discard|domain|drip|echo|exec|
           finger|ftp|ftp-data|gopher|hostname|ident|irc|klogin|
           kshell|login|lpd|nntp|pim-auto-rp|pop2|pop3|smtp|sunrpc|
           tacacs|talk|telnet|time|uucp|whois|www
           |
           biff|bootpc|bootps|dnsix|isakmp|mobile-ip|nameserver|
           netbios-dgm|netbios-ns|netbios-ss|non500-isakmp|ntp|rip|
           snmp|snmptrap|syslog|tftp|who|xdmcp
        )
       }x;

    my $ports = $args{ports} ||
     qr{
        (?:n?eq\s+(?:$port|$pnames))
        |
        (?:range\s+$port\s+$port)
        |
        (?:lt\s+(?:$port|$pnames))
        |
        (?:gt\s+(?:$port|$pnames))
        |
        (?:ack|dscp|established|fin|fragments|psh|rst|syn|urg)
      }x;
    
    my $standard = qr{
        ^access-list
        \s+
        (?<name>\S+) 
        \s+
        (?<action>(?:permit|deny))
        \s+
        (?<source>$network)
        (?:\s+(?<log>log(?:\s+\S+)?))? # optional log with optional tag
        $
    }x;
    
    my $extended = qr{
        ^access-list
        \s+
        (?<name>\S+)
        \s+
        (?<action>(?:permit|deny))
        \s+
        (?<proto>$protocol)
        \s+
        (?<source>$network)
        (?:\s+(?<src_ports>$ports))?
        \s+
        (?<destination>$network)
        (?:\s+(?<dst_ports>$ports))? 
        (?:\s+(?<log>log(?:\s+\S+)?))? # maybe log with optional tag
        $
    }x;

    my $self = bless(\%args, $class);
    
    $self->{class} = $class;
    $self->{regex} = { addr     => $addr,
                       protocol => $protocol,
                       network  => $network,
                       ports    => $ports,
                       standard => $standard,
                       extended => $extended,
                     };
                       
    return($self);
}

sub regex {
    my $self = shift;
    my $obj = shift || die "regex(): must specify regex object you're looking for\n";

    return $self->{regex}{$obj};
}

sub extended {
    my $self = shift;
    my $raw = join('', @_);

    my $clean = $self->_clean($raw);

    return 1 if( $clean =~ /^no\s+access-list\s+(?:1[0-9][0-9]|2[0-6][0-9]{2})$/ || $clean =~ /^$/ || $clean =~ /^end$/ );
    return 1 if( $clean =~ /^access-list\s+(?:1[0-9][0-9]|2[0-6][0-9]{2})\s+remark\s+/ );

    if( $clean =~ m/$self->{regex}{extended}/ ){
        $self->_debug( "Name:   $+{name}" );
        $self->_debug( "Action: $+{action}" );
        $self->_debug( "Proto:  $+{proto}" );
        $self->_debug( "Source: $+{source}" );
        $self->_debug( "Ports:  $+{src_ports}" ) if defined $+{src_ports};
        $self->_debug( "Dest:   $+{destination}" );
        $self->_debug( "Ports:  $+{dst_ports}" ) if defined $+{dst_ports};
        $self->_debug( "Log:    $+{log}" ) if defined $+{log};
        $self->_debug( "" );

        return 1;
    }
    
    return 0;
}

sub standard {
    my $self = shift;
    my $raw = join('', @_);

    my $clean = $self->_clean($raw);

    return 1 if( $clean =~ /^no\s+access-list\s+(?:[1-9]?[0-9]|1[3-9][0-9]{2})$/ || $clean =~ /^$/ || $clean =~ /^end$/ );
    return 1 if( $clean =~ /^access-list\s+(?:[1-9]?[0-9]|1[3-9][0-9]{2})\s+remark\s+/ );

    if( $clean =~ m/$self->{regex}{standard}/ ){
        $self->_debug( "Name:   $+{name}" );
        $self->_debug( "Action: $+{action}" );
        $self->_debug( "Source: $+{source}" );
        $self->_debug( "Log:    $+{log}" ) if defined $+{log};
        $self->_debug( "" );

        return 1;
    }

    
    return 0;
}

sub auto {
    my $self = shift;
    my $line = join('', @_);

    return 1 if( $self->standard($line) );
    return 1 if( $self->extended($line) );

    return 0;
}

sub _clean {
    my $self = shift;
    my $line = join('', @_);

    $line =~ s/!.*//g;
    $line =~ s/^\s*//g;
    $line =~ s/\s*$//g;

    return $line;
}

sub _warn {
    my $self = shift;
    my $msg = join('', @_);

    warn "$self->{class}: $msg\n";
}

sub _debug {
    my $self = shift;

    $self->_warn(@_) if $self->{debug};
}


1;
