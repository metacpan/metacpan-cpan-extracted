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
  'Clear!'      => \$opt{clear},
  'lines=s'     => \$opt{lines},
  'message=s'   => \$opt{message},
  'quantity!'   => \$opt{quantity},
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

    if (defined($opt{quantity})) {
        if (defined(my $lines = $cm->line_numberof())) {
            print "$_: Lines = $lines\n"
        } else {
            printf "Error: %s\n", Cisco::Management->error
        }
    }

    if (defined($opt{message})) {
        my %params;
        if (defined($opt{lines}))   { $params{lines}   = $opt{lines}   }
        if (defined($opt{message})) { $params{message} = $opt{message} }
        if (defined(my $lines = $cm->line_message(%params))) {
            print "$_: Messaged lines = @{$lines}\n"
        } else {
            printf "Error: %s\n", Cisco::Management->error
        }
    }

    if (defined($opt{clear})) {
        my %params;
        if (defined($opt{lines})) { $params{lines} = $opt{lines} }
        if (defined(my $lines = $cm->line_clear(%params))) {
            print "$_: Cleared lines = @{$lines}\n"
        } else {
            printf "Error: %s\n", Cisco::Management->error
        }
    }

    if ((!defined($opt{quantity})) && 
        (!defined($opt{message} )) && 
        (!defined($opt{clear}   ))) {
        if (defined(my $lines = $cm->line_info())) {
            my $sessions = $cm->line_sessions();
            print "Line Type Active\n";
            print "----------------\n";
            for my $line (sort {$a <=> $b} (keys(%{$lines}))) {
                printf "%4i %-5s   ", 
                    $line, 
                    $lines->{$line}->{Type};
                if ($lines->{$line}->{Active} == 1) {
                    print "YES";
                    if (exists($sessions->{$line})) {
                        for (0..$#{$sessions->{$line}}) {
                            print " ($sessions->{$line}->[$_]->{Type}://$sessions->{$line}->[$_]->{Address} [$sessions->{$line}->[$_]->{Direction}])"
                        }
                    }
                } else {
                    print " NO"
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

CISCO-LINE - Cisco Line Manager

=head1 SYNOPSIS

 cisco-line [options] host [...]

=head1 DESCRIPTION

Perform management tasks on console and terminal lines of provided 
hosts.  Management through SMMP using C<OLD-CISCO-TS-MIB>.

=head1 ARGUMENTS

 host             The Cisco device to manage.

=head1 OPTIONS

 -c <snmp_rw>     SNMP read/write community.
 --community      DEFAULT:  (or not specified) 'private'.

 -C               Clear lines.
 --Clear

 -l <range>       Lines to operate on.  Number for single line, 
 --lines          range for multiple lines.  Range uses , and - 
                  for individual and all inclusive.
                  DEFAULT:  (or not specified) [all].

 -me <text>       Message to send.  Use double-quotes to delimit a 
 --message        string with spaces.

 -q               Print number of lines on device.
 --quantity

=head1 LICENSE

This software is released under the same terms as Perl itself.
If you don't know what that means visit L<http://perl.com/>.

=head1 AUTHOR

Copyright (C) Michael Vincent 2010

L<http://www.VinsWorld.com>

All rights reserved

=cut
