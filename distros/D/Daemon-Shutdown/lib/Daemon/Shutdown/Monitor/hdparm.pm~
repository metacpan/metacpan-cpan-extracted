package Daemon::Shutdown::Monitor::hdparm;

use warnings;
use strict;
use Params::Validate qw/:all/;
use IPC::Run;
use YAML::Any;
use User;
use Log::Log4perl;

=head1 NAME

Daemon::Shutdown::Monitor::hdparm - a hdparm specific monitor

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

Monitor hard disk spindown state using hdparm

=head1 DESCRIPTION

Tests the spin state of all the disks listed in "disks" every "loop_sleep".  When all disks
are in spun down state, the flag "trigger_pending" is set.  If a further "trigger_time" seconds
pass and all disks are still in a spun down state, the trigger is sent back to the parent
process (return 1).

=head1 METHODS

=head2 new

=over 2

=item loop_sleep <Int>

How long to sleep between each test

Default: 60 (1 minute)

=item disks <ArrayRef>

An array of disks to be tested.  e.g. /dev/sda

Default: [ '/dev/sda' ]

=item trigger_time <Int>

The time to wait after discovering that all disks are spun down before returning (trigger a shutdown).

Default: 3600 (1 hour)

=item use_sudo 1|0

Use sudo for hdparm
 
sudo hdparm -C /dev/sda

Default: 0

=back

=head3 Example configuration
 
monitor:
  hdparm:
    trigger_time: 1800
    loop_sleep: 1
    use_sudo: 0
    disks: 
      - /dev/sdb
      - /dev/sdc
      - /dev/sdd

=cut

sub new {
    my $class  = shift;
    my %params = @_;

    # Validate the config file
    %params = validate_with(
        params => \%params,
        spec   => {
            loop_sleep => {
                regex   => qr/^\d*$/,
                default => 60,
            },
            trigger_time => {
                regex   => qr/^\d*$/,
                default => 3600,
            },
            disks => {
                type      => ARRAYREF,
                default   => [ '/dev/sda' ],
                callbacks => {
                    'Disks exist' => sub {
                        my $disks_ref = shift();
                        foreach my $disk ( @{$disks_ref} ) {
                            return 0 if !-e $disk;
                        }
                        return 1;
                    },
                },
            },
            use_sudo => {
                default => 0,
                regex   => qr/^[1|0]$/,
            },
        },
    );
    my $self = {};
    $self->{params} = \%params;

    $self->{trigger_pending} = 0;

    bless $self, $class;
    my $logger = Log::Log4perl->get_logger();
    $self->{logger} = $logger;
    $logger->debug( "Monitor hdparm params:\n" . Dump( \%params ) );

    return $self;
}

=head2 run

Run the hdparm spindown Monitor

=cut

sub run {
    my $self = shift;

    my $logger = $self->{logger};

    $logger->info( "Monitor started running: hdparm" );

    my $conditions_met = 1;

    # Test each disk
    foreach my $disk ( @{ $self->{params}->{disks} } ) {
        $logger->debug( "Monitor hdparm testing $disk" );
        my @cmd = ( qw/hdparm -C/, $disk );
        if ( $self->{params}->{use_sudo} ) {
            unshift( @cmd, 'sudo' );
        }
        $logger->debug( "Monitor hdparm CMD: " . join( ' ', @cmd ) );
        my ( $in, $out, $err );
        if ( not IPC::Run::run( \@cmd, \$in, \$out, \$err, IPC::Run::timeout( 10 ) ) ) {
            $logger->warn( "Could not run '" . join( ' ', @cmd ) . "': $!" );
        }
        if ( $err ) {
            $logger->error( "Monitor hdparm: $err" );
            $conditions_met = 0;
        }

        # If any of the disks are active, the conditions for trigger are not met
        if ( $out =~ m/drive state is:  active/s ) {
            $logger->debug( "Monitor hdparm sees disk is active: $disk" );
            $conditions_met = 0;
        }
    }

    if ( $conditions_met ) {

        # All disks are spun down! Set the trigger_pending time.
        $self->{trigger_pending} = $self->{trigger_pending} || time();
        if ( $self->{trigger_pending}
            and ( time() - $self->{trigger_pending} ) >= $self->{params}->{trigger_time} )
        {

            # ... and the trigger was set, and time has run out: time to return!
            $logger->info( "Monitor hdparm trigger time reached after $self->{params}->{trigger_time}" );
            return 1;
        }

        $logger->info( "Monitor hdparm found all disks spun down: trigger pending." );
    } else {
        if ( $self->{trigger_pending} ) {
            $logger->info( "Monitor hdparm trigger time being reset because of disk activity" );
        }

        # Conditions not met - reset the trigger incase it was previously set.
        $self->{trigger_pending} = 0;
    }
    return 0;
}

=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Daemon::Shutdown::Monitor::hdparm
