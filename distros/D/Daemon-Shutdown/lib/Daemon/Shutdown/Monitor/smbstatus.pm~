package Daemon::Shutdown::Monitor::smbstatus;

use warnings;
use strict;
use Params::Validate qw/:all/;
use IPC::Run;
use YAML::Any;
use Log::Log4perl;

=head1 NAME

Daemon::Shutdown::Monitor::smbstatus - check for samba locks

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Monitor samba file locks

=head1 DESCRIPTION

Uses C<smbstatus> to look for locked files every "loop_sleep".  If no files are locked,
the flag "trigger_pending" is set.  If a further "trigger_time" seconds
pass and all disks are still in a spun down state, the trigger is sent back to the parent
process (return 1).

=head1 METHODS

=head2 new

=over 2

=item loop_sleep <Int>

How long to sleep between each test

Default: 60 (1 minute)

=item trigger_time <Int>

The time to wait after discovering that all disks are spun down before returning (trigger a shutdown).

Default: 3600 (1 hour)

=back

=head3 Example configuration
 
monitor:
  smbstatus:
    trigger_time: 1800
    loop_sleep: 360

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
        },
    );
    my $self = {};
    $self->{params} = \%params;

    $self->{trigger_pending} = 0;

    bless $self, $class;
    my $logger = Log::Log4perl->get_logger();
    $self->{logger} = $logger;
    $logger->debug( "Monitor smbstatus params:\n" . Dump( \%params ) );

    return $self;
}

=head2 run

Run the smbstatus lock monitor

=cut

sub run {
    my $self = shift;

    my $logger = $self->{logger};

    $logger->info( "Monitor started running: smbstatus" );
    my $conditions_met = 1;

    # look for locks
    my @cmd = ( qw/smbstatus -L/ );
    $logger->debug( "Monitor smbstatus CMD: " . join( ' ', @cmd ) );

    my ( $in, $out, $err );
    if ( not IPC::Run::run( \@cmd, \$in, \$out, \$err, IPC::Run::timeout( 10 ) ) ) {
        $logger->warn( "Could not run '" . join( ' ', @cmd ) . "': $!" );
    }

    if ( $err ) {
        $logger->error( "Monitor smbstatus: $err" );
        $conditions_met = 0;
    }

    # If are active locks, the conditions for trigger are not met
    # XXX other languages?
    if ( $out =~ m/Locked files:/ ) {
        $logger->debug( "Monitor smbstatus sees active file locks" );
        $conditions_met = 0;
    }

    if ( $conditions_met ) {
        $self->{trigger_pending} = $self->{trigger_pending} || time();

        if ( $self->{trigger_pending}
            and ( time() - $self->{trigger_pending} ) >= $self->{params}->{trigger_time} )
        {

            # ... and the trigger was set, and time has run out: time to return!
            $logger->info( "Monitor smbstatus trigger time reached after $self->{params}->{trigger_time}" );
            return 1;
        }

        $logger->info( "Monitor smbstatus found no locks: trigger pending." );
    } else {
        if ( $self->{trigger_pending} ) {
            $logger->info( "Monitor smbstatus trigger time being reset because of new file locks" );
        }

        # Conditions not met - reset the trigger incase it was previously set.
        $self->{trigger_pending} = 0;
    }

    return 0;
}

=head1 AUTHOR

Robin Clarke, C<< <perl at robinclarke.net> >>

Ioan Rogers, C<< <ioan.rogers at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Daemon::Shutdown::Monitor::smbstatus
