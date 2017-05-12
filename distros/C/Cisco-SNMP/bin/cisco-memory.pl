#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::SNMP::Memory;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'community=s'  => \$opt{community},
  'Kilobytes!'   => \$opt{k},
  'Megabytes!'   => \$opt{m},
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
    if (!defined($cm = Cisco::SNMP::Memory->new(
            hostname  => $_,
            community => $opt{community}
        ))) {
        printf "Error: %s\n", Cisco::SNMP::Memory->error;
        next
    }

    if (defined(my $mem = $cm->memory_info())) {
        my $params = 'B';
        if (defined($opt{k})) { $params = 'K' }
        if (defined($opt{m})) { $params = 'M' }

        printf "Memory Pool Name    |   Total(%s)    |    Used(%s)    |Percent(%%)\n", $params, $params;
        print  "--------------------|---------------|---------------|----------\n";
        for (0..$#{$mem}) {
            my ($Used, $Total);
            if       ($params eq 'K') { $Used  = $mem->memUsed($_) /1000;
                                        $Total = $mem->memTotal($_)/1000
            } elsif  ($params eq 'M') { $Used  = $mem->memUsed($_) /1000000;
                                        $Total = $mem->memTotal($_)/1000000
            } else                    { $Used  = $mem->memUsed($_);
                                        $Total = $mem->memTotal($_)
            }
            printf "%-20s|%15.2f|%15.2f|%7.2f\n", 
                $mem->memName($_), 
                $Total,
                $Used, 
                $mem->memUsed($_)/$mem->memTotal($_)*100
        }
        print "\n"
    } else {
        printf "Error: %s\n", Cisco::SNMP::Memory->error
    }

    $cm->close()
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-MEMORY - Cisco Memory Information

=head1 SYNOPSIS

 cisco-memory [options] host [...]

=head1 DESCRIPTION

Print memory information for provided Cisco device.

=head1 ARGUMENTS

 host             The Cisco device to manage.

=head1 OPTIONS

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

 -K               Provide memory utilization in Kilobytes
 --Kilobytes      DEFAULT:  (or not specified) [Bytes]

 -M               Provide memory utilization in Megabytes
 --Megabytes      DEFAULT:  (or not specified) [Bytes]

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
