#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::Management;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'community=s'   => \$opt{community},
  'down!'         => \$opt{down},
  'interfaces=s'  => \$opt{interfaces},
  'metrics:s'     => \$opt{metrics},
  'repeat!'       => \$opt{repeat},
  'up!'           => \$opt{up},
  'Utilization:i' => \$opt{util},
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
if (defined($opt{up})) {
    $oper = 'UP'
} elsif (defined($opt{down})) {
    $oper = 'DOWN'
}

for (@ARGV) {
    print "\n-- $_ --\n";

    my $cm;
    if (!defined($cm = Cisco::Management->new(
                              hostname  => $_,
                              community => $opt{community}
                             ))) {
        printf "Error: %s\n", Cisco::Management->error;
        next
    }

    my %params;
    my $ERROR = 0;
    if (defined($opt{interfaces})) {

        if ($opt{interfaces} =~ /^[A-Za-z]/) {
            my @temp;
            my @ifs = split /\s+/, $opt{interfaces};
            for (@ifs) {
                if (defined(my $if = $cm->interface_getbyname(interface => $_, index => 1))) {
                    push @temp, $if
                } else {
                    printf "Error: %s\n", Cisco::Management->error;
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

    if (defined($oper)) {
        $params{operation}  = $oper;
        if (defined(my $ifs = $cm->interface_updown(%params))) {
            print "$_: Admin $oper interfaces = @{$ifs}\n"
        } else {
            printf "Error: %s\n", Cisco::Management->error
        }
    } elsif (defined($opt{metrics}) && !defined($opt{util})) {
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
                    defined($ifs->{$int}->{InMulticasts}) ? $ifs->{$int}->{InMulticasts} : '-',
                    defined($ifs->{$int}->{OutMulticasts}) ? $ifs->{$int}->{OutMulticasts} : '-',
                    defined($ifs->{$int}->{InBroadcasts}) ? $ifs->{$int}->{InBroadcasts} : '-',
                    defined($ifs->{$int}->{OutBroadcasts}) ? $ifs->{$int}->{OutBroadcasts} : '-',
                    defined($ifs->{$int}->{InOctets}) ? $ifs->{$int}->{InOctets} : '-',
                    defined($ifs->{$int}->{OutOctets}) ? $ifs->{$int}->{OutOctets} : '-'
            }
        } else {
            printf "Error: %s\n", Cisco::Management->error
        }
    } elsif (defined($opt{util})) {
        if ($opt{util} > 0) { $params{polling} = $opt{util} }
        if (defined($opt{metrics}) && $opt{metrics} ne '') {
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
        my $GO = 1;
        while ($GO) {
            my $ifs;
            $params{recursive} = $recur;
            ($ifs, $recur) = $cm->interface_utilization(%params);
            if (defined($ifs)) {
                print "-----------------------------------------\n";
                for my $int (sort {$a <=> $b} (keys(%{$ifs}))) {
                    printf "%5i %5s/%-5s %5s/%-5s %5s/%-5s\n", 
                        $int, 
                        defined($ifs->{$int}->{InMulticasts}) ? $ifs->{$int}->{InMulticasts} : '-',
                        defined($ifs->{$int}->{OutMulticasts}) ? $ifs->{$int}->{OutMulticasts} : '-',
                        defined($ifs->{$int}->{InBroadcasts}) ? $ifs->{$int}->{InBroadcasts} : '-',
                        defined($ifs->{$int}->{OutBroadcasts}) ? $ifs->{$int}->{OutBroadcasts} : '-',
                        defined($ifs->{$int}->{InOctets}) ? $ifs->{$int}->{InOctets} : '-',
                        defined($ifs->{$int}->{OutOctets}) ? $ifs->{$int}->{OutOctets} : '-'
                }
            } else {
                printf "Error: %s\n", Cisco::Management->error
            }
            if (!defined($opt{repeat}) || $stopRepeat) { last }
        }
    } else {
        if (defined(my $ifs = $cm->interface_info(%params))) {
            my $ips = $cm->interface_ip();
            print "Index Description               Speed/Duplex Admin/Oper IP(s)\n";
            print "--------------------------------------------------------------\n";
            for my $int (sort {$a <=> $b} (keys(%{$ifs}))) {
                printf "%5i %-25s %4i/%-7s %4s/%-4s ", 
                    $int, 
                    $ifs->{$int}->{Description},
                    ($ifs->{$int}->{Speed} > 1000000) ? $ifs->{$int}->{Speed}/1000000 : $ifs->{$int}->{Speed},
                    $ifs->{$int}->{Duplex},
                    $ifs->{$int}->{AdminStatus},
                    $ifs->{$int}->{OperStatus};
                    if (exists($ips->{$int})) {
                        for (0..$#{$ips->{$int}}) {
                            print " $ips->{$int}->[$_]->{IPAddress}"
                        }
                    }
                print "\n"
            }
        } else {
            printf "Error: %s\n", Cisco::Management->error
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

 -d               Admin down interface.
 --down           DEFAULT:  (or not specified) [show info].

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

 -r               Repeat utilization polling (if -U) indefinitely.
 --repeat         Use Ctrl-C to stop.
                  DEFAULT:  (or not specified) [Poll once].

 -u               Admin up interface.
 --up             DEFAULT:  (or not specified) [show info].

 -U [#]           Return interface utilization instead of raw 
 --Utilization    metrics.  Optional number denotes polling 
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
