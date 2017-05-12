#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case); #bundling
use Pod::Usage;

use Cisco::Management;

my %opt;
my ($opt_help, $opt_man);

GetOptions(
  'community=s' => \$opt{community},
  'dest=s'      => \$opt{dest},
  'source=s'    => \$opt{source},
  'tftp=s'      => \$opt{tftp},
  'write!'      => \$opt{write},
  'help!'       => \$opt_help,
  'man!'        => \$opt_man
) or pod2usage(-verbose => 0);

pod2usage(-verbose => 1) if defined $opt_help;
pod2usage(-verbose => 2) if defined $opt_man;

# Make sure at least one host was provided
if (!@ARGV) {
    pod2usage(-verbose => 0, -message => "$0: host required\n")
}

$opt{community} = $opt{community} || 'private';
$opt{dest}      = $opt{dest}      || 'start';
$opt{source}    = $opt{source}    || 'run';

if (($opt{dest}   !~ /^run(?:ning)?(?:-config)?$/i) &&
    ($opt{dest}   !~ /^start(?:up)?(?:-config)?$/i) &&
    ($opt{source} !~ /^run(?:ning)?(?:-config)?$/i) &&
    ($opt{source} !~ /^start(?:up)?(?:-config)?$/i)) {
    print "$0: source or dest must be run or start\n";
    exit 1
}

if (((($opt{dest}   !~ /^run(?:ning)?(?:-config)?$/i) &&
      ($opt{dest}   !~ /^start(?:up)?(?:-config)?$/i)) ||
     (($opt{source} !~ /^run(?:ning)?(?:-config)?$/i) &&
      ($opt{source} !~ /^start(?:up)?(?:-config)?$/i))) && (!defined($opt{tftp}))) {
    print "$0: TFTP required for source or dest not run or start\n";
    exit 1
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

    if (!defined($opt{tftp})) {
        if (defined(my $conf = $cm->config_copy(
                                                -source => $opt{source},
                                                -dest   => $opt{dest}
                                               ))) {
            print "$_: copy $opt{source} $opt{dest}\n"
        } else {
            printf "Error: %s\n", Cisco::Management->error
        }
        next
    }

    if (defined(my $conf = $cm->config_copy(
                                            -tftp   => $opt{tftp},
                                            -source => $opt{source},
                                            -dest   => $opt{dest}
                                           ))) {
        my $src  = $opt{source};
        my $dest = $opt{dest};
        if (($opt{dest} !~ /^run(?:ning)?(?:-config)?$/i) &&
            ($opt{dest} !~ /^start(?:up)?(?:-config)?$/i)) {
            $dest = $opt{tftp} . ":/" . $opt{dest}
        } else {
            $src = $opt{tftp} . ":/" . $opt{source}
        }
        printf "$_: copy $src $dest\n";
        if ($opt{write}) {
            if (defined($conf = $cm->config_copy())) {
                print "$_:  copy run start\n"
            } else {
                printf "Error: %s\n", Cisco::Management->error
            }
        }
    } else {
        printf "Error: %s\n", Cisco::Management->error
    }
    $cm->close()
}

__END__

########################################################
# Start POD
########################################################

=head1 NAME

CISCO-CONF - Cisco Configuration File Manager

=head1 SYNOPSIS

 cisco-conf [options] host [...]

=head1 DESCRIPTION

Perform configuration file management tasks on provided hosts.
Configuration file upload and download through TFTP (via SMMP) and 
C<copy run start> on host are options.

=head1 ARGUMENTS

 host             The Cisco device to manage.

=head1 OPTIONS

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

 -d <file>        File name for destination.  Can be 'start' or 'run' 
 --dest           for local device files.  Can be any filename for 
                  TFTP destination.
                  DEFAULT:  (or not specified) 'start'.

 -s <file>        File name for source.  Can be 'start' or 'run' 
 --source         for local device files.  Can be any filename for 
                  TFTP source.
                  DEFAULT:  (or not specified) 'run'.

 -t <IP>          TFTP server address or hostname.
 --tftp           DEFAULT:  (or not specified) [none].

 -w               Perform a 'copy run start' if TFTP is successful.
 --write

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
