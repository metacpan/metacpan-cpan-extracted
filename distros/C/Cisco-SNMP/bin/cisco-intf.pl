#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::SNMP::Interface;
use Cisco::SNMP::IP;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'community=s'   => \$opt{community},
  'Down!'         => \$opt{down},
  'interfaces=s'  => \$opt{interfaces},
  'm|metrics:s'   => \$opt{metrics},
  'repeat!'       => \$opt{repeat},
  'Up!'           => \$opt{up},
  'utilization:i' => \$opt{util},
  'help!'         => \$opt_help,
  'man!'          => \$opt_man
) or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# Make sure at least one arg was provided
if (!@ARGV) {
    pod2usage(-verbose => 0, -message => "$0: host required\n")
}

$opt{community} = $opt{community} || 'private';

my $oper;
if (defined $opt{up}) {
    $oper = 'UP'
} elsif (defined $opt{down}) {
    $oper = 'DOWN'
}

for (@ARGV) {
    print "\n-- $_ --\n";

    my $cm;
    if (!defined($cm = Cisco::SNMP::Interface->new(
            hostname  => $_,
            community => $opt{community}
        ))) {
        printf "Error: %s\n", Cisco::SNMP::Interface->error;
        next
    }

    my %params;
    my $ERROR = 0;
    # get interfaces
    if (defined $opt{interfaces}) {

        # by name
        if ($opt{interfaces} =~ /^[A-Za-z]/) {
            my @temp;
            my @ifs = split /\s+/, $opt{interfaces};
            for (@ifs) {
                if (defined(my $if = $cm->interface_getbyname(interface => $_, index => 1))) {
                    push @temp, $if
                } else {
                    printf "Error: %s\n", Cisco::SNMP::Interface->error;
                    $ERROR = 1;
                    last
                }
            }
            $params{interfaces} = join ',', @temp
        } else {
            $params{interfaces} = $opt{interfaces}
        }
    }

    next if ($ERROR);

    # UP/DOWN
    if (defined $oper) {
        $params{operation}  = $oper;
        if (defined(my $ifs = $cm->interface_updown(%params))) {
            print "$_: Admin $oper interfaces = @{$ifs}\n"
        } else {
            printf "Error: %s\n", Cisco::SNMP::Interface->error
        }
    # metrics
    } elsif (defined $opt{metrics} && !defined $opt{util}) {
        if ($opt{metrics} ne '') {
            my @temp;
            push @temp, split /\s+/, $opt{metrics};
            $params{metrics} = \@temp
        }
        if (defined(my $ifs = $cm->interface_metrics(%params))) {
            print "Index Multi(I/O)  Broad(I/O)  Octets(I/O)\n";
            print "-----------------------------------------\n";
            for my $int (sort {$a <=> $b} (keys(%{$ifs}))) {
                printf "%5i %5s/%-5s %5s/%-5s %5s/%-5s\n", 
                    $int, 
                    defined($ifs->ifInMulticasts($int)) ? $ifs->ifInMulticasts($int) : '-',
                    defined($ifs->ifOutMulticasts($int)) ? $ifs->ifOutMulticasts($int) : '-',
                    defined($ifs->ifInBroadcasts($int)) ? $ifs->ifInBroadcasts($int) : '-',
                    defined($ifs->ifOutBroadcasts($int)) ? $ifs->ifOutBroadcasts($int) : '-',
                    defined($ifs->ifInOctets($int)) ? $ifs->ifInOctets($int) : '-',
                    defined($ifs->ifOutOctets($int)) ? $ifs->ifOutOctets($int) : '-'
            }
        } else {
            printf "Error: %s\n", Cisco::SNMP::Interface->error
        }
    #utilization
    } elsif (defined $opt{util}) {
        if ($opt{util} > 0) { $params{polling} = $opt{util} }
        if (defined $opt{metrics} && $opt{metrics} ne '') {
            my @temp;
            push @temp, split /\s+/, $opt{metrics};
            $params{metrics} = \@temp
        }

        print "Index Multi(I/O)  Broad(I/O)  Octets(I/O)\n";
        print "      packets/s   packets/s     bits/s\n";

        my $stopRepeat = 0;
        $SIG{INT} = sub {
            print "SIGINT! - Stop\n";
            $stopRepeat = 1
        };

        my $recur;
        while (1) {
            if ($stopRepeat) { last }
            my $ifs;
            $params{recursive} = $recur;
            ($ifs, $recur) = $cm->interface_utilization(%params);
            if (defined $ifs) {
                print "-----------------------------------------\n";
                for my $int (sort {$a <=> $b} (keys(%{$ifs}))) {
                    printf "%5i %5s/%-5s %5s/%-5s %5s/%-5s\n", 
                        $int, 
                        defined($ifs->ifInMulticasts($int)) ? $ifs->ifInMulticasts($int) : '-',
                        defined($ifs->ifOutMulticasts($int)) ? $ifs->ifOutMulticasts($int) : '-',
                        defined($ifs->ifInBroadcasts($int)) ? $ifs->ifInBroadcasts($int) : '-',
                        defined($ifs->ifOutBroadcasts($int)) ? $ifs->ifOutBroadcasts($int) : '-',
                        defined($ifs->ifInOctets($int)) ? $ifs->ifInOctets($int) : '-',
                        defined($ifs->ifOutOctets($int)) ? $ifs->ifOutOctets($int) : '-'
                }
            } else {
                printf "Error: %s\n", Cisco::SNMP::Interface->error
            }
            if (!defined $opt{repeat}) { last }
        }
    # interface info
    } else {
        if (defined(my $ifs = $cm->interface_info(%params))) {
            my ($cmip, $ips);
            if (defined($cmip = Cisco::SNMP::IP->new(
                    hostname  => $_,
                    community => $opt{community}
                ))) {
                $ips = $cmip->addr_info();
            } else {
                printf "Error: %s\n", Cisco::SNMP::IP->error;
            }
            print "Index Description                 Speed/Duplex Admin/Oper IP(s)\n";
            print "---------------------------------------------------------------\n";
            for my $int (sort {$a <=> $b} (keys(%{$ifs}))) {
                printf "%5i %-25s %7i/%-7s %4s/%-4s ", 
                    $int, 
                    $ifs->ifDescription($int),
                    ($ifs->ifSpeed($int) > 1000000) ? $ifs->ifSpeed($int)/1000000 : $ifs->ifSpeed($int),
                    $ifs->ifDuplex($int),
                    $ifs->ifAdminStatus($int),
                    $ifs->ifOperStatus($int);
                    if (exists($ips->{$int})) {
                        for (0..$#{$ips->{$int}}) {
                            printf " %s", $ips->addrAddr($int,$_)
                        }
                    }
                print "\n"
            }
        } else {
            printf "Error: %s\n", Cisco::SNMP::Interface->error
        }
    }

    $cm->close()
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-INTF - Cisco Interface Manager

=head1 SYNOPSIS

 cisco-intf [options] host [...]

=head1 DESCRIPTION

Retrieve interface information or admin up/down interfaces on Cisco 
devices.

=head1 ARGUMENTS

 host             The Cisco device to manage.

=head1 OPTIONS

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

 -D               Admin down interface.
 --Down           DEFAULT:  (or not specified) [show info].

 -i IF            Interfaces to operate on.
 --interfaces     
                  IF can be number meaning ifIndex.  Range can be 
                  provided.  Range uses , and - for individual and 
                  all inclusive.  Example:
                    2-4,11
                  
                  IF can be interface name(s).  If multiple, use 
                  quotes to surround the list and spaces to separate.
                  Example:
                    "gig0/0/1 serial1/0 f0/1"

                  DEFAULT:  (or not specified) [all].

 -m [m1 [m2]...]  Metrics to return.  Use double quotes to delimit 
 --metrics        multiple.  Valid metrics are:
                    Multicasts
                    Broadcasts
                    Octets

                  DEFAULT:  (or not specified) [show info].

 -r               Repeat utilization polling (if -u) indefinitely.
 --repeat         Use Ctrl-C to stop.
                  DEFAULT:  (or not specified) [Poll once].

 -U               Admin up interface.
 --Up             DEFAULT:  (or not specified) [show info].

 -u [#]           Return interface utilization instead of raw 
 --utilization    metrics.  Optional number denotes polling 
                  interval.
                  DEFAULT:  (or not specified) 10.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
