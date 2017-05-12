#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::SNMP::Image;
use Cisco::SNMP::System;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'community=s'  => \$opt{community},
  'image!'       => \$opt{image},
  'help!'        => \$opt_help,
  'man!'         => \$opt_man
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
    if (!defined($cm = Cisco::SNMP::System->new(
            hostname  => $_,
            community => $opt{community}
        ))) {
        printf "Error: %s\n", Cisco::SNMP::System->error;
        next
    }

    if (defined(my $sysinfo = $cm->system_info())) {
        printf "Description  = %s\n", $sysinfo->sysDescr;
        printf "ObjectID     = %s\n", $sysinfo->sysObjectID;
        printf "Uptime       = %s\n", $sysinfo->sysUpTime;
        printf "Conctact     = %s\n", $sysinfo->sysContact;
        printf "Name         = %s\n", $sysinfo->sysName;
        printf "Location     = %s\n", $sysinfo->sysLocation;
        printf "OrLastChange = %s\n", $sysinfo->sysORLastChange;
        printf "OS Version   = %s\n", $sysinfo->sysOSVersion;
        print  "Services     = ";
        print "$_ " for (@{$sysinfo->sysServices});
        print "\n"
    } else {
        printf "Error: %s\n", Cisco::SNMP::System->error
    }

    if (defined $opt{image}) {
        my $cmi;
        if (!defined($cmi = Cisco::SNMP::Image->new(
                hostname  => $_,
                community => $opt{community}
            ))) {
            printf "Error: %s\n", Cisco::SNMP::Image->error;
            next
        }

        if (defined(my $image = $cmi->image_info())) {
            for my $i (0..$#{$image}) {
                printf "Image String $i = %s\n", $image->imageString($i)
            }
        } else {
            printf "Error: %s\n", Cisco::SNMP::Image->error
        }

        $cmi->close()
    }

    $cm->close()
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-SYSTEM - Cisco System Information

=head1 SYNOPSIS

 cisco-system [options] host [...]

=head1 DESCRIPTION

Print system MIB information for provided Cisco device.

=head1 ARGUMENTS

 host             The Cisco device to manage.

=head1 OPTIONS

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

 -i               System image information.
 --image

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
