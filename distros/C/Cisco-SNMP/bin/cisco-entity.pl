#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::SNMP::Entity;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'all!'        => \$opt{all},
  'community=s' => \$opt{community},
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
$opt{all}       = $opt{all}       || 0;

for (@ARGV) {
    print "\n-- $_ --\n";

    my $cm;
    if (!defined($cm = Cisco::SNMP::Entity->new(
            hostname  => $_,
            community => $opt{community}
        ))) {
        printf "Error: %s\n", Cisco::SNMP::Entity->error;
        next
    }

    if (defined(my $entity = $cm->entity_info())) {
        printf "%-25s%-30s%-12s%-12s\n", "MODELNAME", "NAME", "SN", "SOFTREV";
        print "-"x74 . "\n";
        for (0..$#{$entity}) {
            next if (($entity->entitySerialNum($_) eq '') && (!$opt{all}));
            printf "%-25s%-30s%-12s%-12s\n",
                $entity->entityModelName($_),
                $entity->entityName($_),
                $entity->entitySerialNum($_), 
                $entity->entitySoftwareRev($_)
        }
    } else {
        printf "Error: %s\n", Cisco::SNMP::Entity->error
    }

    $cm->close()
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-ENTITY - Cisco Entity Information

=head1 SYNOPSIS

 cisco-entity [options] host [...]

=head1 DESCRIPTION

Print entity information for provided Cisco device.

=head1 ARGUMENTS

 host             The Cisco device to manage.

=head1 OPTIONS

 -a               All items.
 --all            DEFAULT:  (or not specified) 'only items with 
                                                serial number'.

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
