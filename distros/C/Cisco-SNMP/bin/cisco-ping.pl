#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::SNMP::ProxyPing;
use Sys::Hostname;
use IO::Socket;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'community=s'   => \$opt{community},
  'Count=i'       => \$opt{count},
  'destination=s' => \$opt{destination},
  'size=i'        => \$opt{size},
  'vrf=s'         => \$opt{vrf},
  'wait=i'        => \$opt{wait},
  'help!'         => \$opt_help,
  'man!'          => \$opt_man
) or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# Make sure at least one arg was provided
if (!@ARGV) {
    pod2usage(-verbose => 0, -message => "$0: host required\n")
}

$opt{community}   = $opt{community}   || 'private';
$opt{destination} = $opt{destination} || inet_ntoa((gethostbyname(hostname))[4]);
$opt{count}       = $opt{count}       || 4;
$opt{size}        = $opt{size}        || 64;
$opt{wait}        = $opt{wait}        || 1;

for (@ARGV) {
    print "\n-- $_ --\n";

    my $cm;
    if (!defined($cm = Cisco::SNMP::ProxyPing->new(
            hostname  => $_,
            community => $opt{community}
        ))) {
        printf "Error: %s\n", Cisco::SNMP::ProxyPing->error;
        next
    }

    $|++;
    my $dest = inet_ntoa((gethostbyname($opt{destination}))[4]);
    print "Pinging $opt{destination} [$dest] with $opt{size} bytes of data from:\n\n$_ ";
    my %params;
    if (defined($opt{count}))       { $params{count} = $opt{count}       }
    if (defined($opt{destination})) { $params{host}  = $opt{destination} }
    if (defined($opt{size}))        { $params{size}  = $opt{size}        }
    if (defined($opt{wait}))        { $params{wait}  = $opt{wait}        }
    if (defined($opt{vrf}))         { $params{vrf}   = $opt{vrf}         }
    if (defined(my $pings = $cm->proxy_ping(%params))) {        
        printf "%s $opt{destination} [$dest]\n\nPing statistics for $dest:\n", ($pings->ppReceived() >= 1) ? '!'x$pings->ppReceived() . ' Reply from' : '... No response from';
        printf "    Packets: Sent = %i, Received = %i, Lost = %i (%i%% loss),\n", $pings->ppSent(), $pings->ppReceived(), $pings->ppSent()-$pings->ppReceived(), (100-($pings->ppReceived()/$pings->ppSent()*100));
        print  "Approximate round trip times in milli-seconds:\n";
        printf "    Minimum = %sms, Maximum = %sms, Average = %sms\n", $pings->ppMinimum(), $pings->ppMaximum(), $pings->ppAverage();
    } else {
        printf "Error: %s\n", Cisco::SNMP::ProxyPing->error
    }

    $cm->close()
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-PING - Cisco Proxy Ping

=head1 SYNOPSIS

 cisco-ping [options] host [...]

=head1 DESCRIPTION

Execute proxy ping from host to provided destination.

=head1 ARGUMENTS

 host             The Cisco device to ping from.

=head1 OPTIONS

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

 -C #             The number of pings to send.
 --Count          DEFAULT:  (or not specified) 4.

 -d <IP>          The destination to ping to.
 --destination    DEFAULT:  (or not specified) localhost.

 -s #             The size of the ping packets.
 --size           DEFAULT:  (or not specified) 64.

 -v <name>        The VRF instance name to source pings from.
 --vrf            DEFAULT:  (or not specified) [none].

 -w #             The ping timeout in seconds.
 --wait           DEFAULT:  (or not specified) 1.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
