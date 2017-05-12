#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::SNMP::ARP;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'community=s' => \$opt{community},
  'Clear=s'     => \$opt{clear},
  'help!'       => \$opt_help,
  'man!'        => \$opt_man
) or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# Make sure at least one arg was provided
if (!@ARGV) {
    pod2usage(-verbose => 0, -message => "$0: host required\n")
}

$opt{community} = $opt{community} || 'private';

for (@ARGV) {
    print "\n-- $_ --\n";

    my $cm;
    if (!defined($cm = Cisco::SNMP::ARP->new(
            hostname  => $_,
            community => $opt{community}
        ))) {
        printf "Error: %s\n", Cisco::SNMP::ARP->error;
        next
    }

    if (defined $opt{clear}) {
        my ($idx, $ip) = split /,/, $opt{clear};
        if (defined($cm->arp_clear($idx,$ip))) {
            print "Cleared $ip ARP from interface index $idx\n"
        } else {
            printf "Error: %s\n", Cisco::SNMP::ARP->error
        }
    } else {
        if (defined(my $arp = $cm->arp_info())) {
            print "If Index | MAC Address  |   Net Address   | Type\n";
            print "---------|--------------|-----------------|-----\n";
            for (0..$#{$arp}) {
                printf "%8s | %-12s | %-15s | %s\n", 
                    $arp->arpIfIndex($_),
                    $arp->arpPhysAddress($_),
                    $arp->arpNetAddress($_),
                    $arp->arpType($_)
            }
            print "\n"
        } else {
            printf "Error: %s\n", Cisco::SNMP::ARP->error
        }
    }

    $cm->close()
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-ARP - Cisco ARP Information

=head1 SYNOPSIS

 cisco-arp [options] host [...]

=head1 DESCRIPTION

Print ARP information for provided Cisco device.

=head1 ARGUMENTS

 host             The Cisco device to manage.

=head1 OPTIONS

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

 -C <id,ip>       Clear the ARP entry for IP address 'ip' at 
 --Clear          interface index 'id'.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
