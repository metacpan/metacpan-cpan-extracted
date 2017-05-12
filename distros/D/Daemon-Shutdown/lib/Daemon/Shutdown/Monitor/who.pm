package Daemon::Shutdown::Monitor::who;

use warnings;
use strict;
use Params::Validate qw/:all/;
use IPC::Run;
use YAML::Any;
use User;
use Log::Log4perl;

=head1 NAME

Daemon::Shutdown::Monitor::who - a who specific monitor

=head1 SYNOPSIS

Monitor users logged in with 'who'

=head1 DESCRIPTION

Tests if any users are logged in (using the 'who' command).  When no users are logged in
the flag "trigger_pending" is set.  If a further "trigger_time" seconds
pass and there are still no users logged in the trigger is sent back to the parent
process (return 1).

=head1 METHODS

=head2 new

=over 2

=item loop_sleep <Int>

How long to sleep between each test

Default: 60 (1 minute)

=item trigger_time <Int>

The time to wait after discovering that no users are currently logged in

Default: 360 (10 minutes)

=item user <Str>

Monitor only a specific user.

Default: undef

=back

=head3 Example configuration
 
monitor:
  who:
    trigger_time: 1800
    user: rclarke
    loop_sleep: 1

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
            user => {
                optional => 1,
                regex => qr/^\w+$/,
            },
        },
    );
    my $self = {};
    $self->{params} = \%params;

    $self->{trigger_pending} = 0;

    bless $self, $class;
    my $logger = Log::Log4perl->get_logger();
    $self->{logger} = $logger;
    $logger->debug( "Monitor 'who' params:\n" . Dump( \%params ) );

    return $self;
}

=head2 run

Run the who Monitor

=cut

sub run {
    my $self = shift;

    my $logger = $self->{logger};

    $logger->info( "Monitor started running: who" );

    my $users_count = 0;
    my @cmd = ( 'who' );
    $logger->debug( "Monitor 'who' CMD: " . join( ' ', @cmd ) );
    my ( $in, $out, $err );
    if ( not IPC::Run::run( \@cmd, \$in, \$out, \$err, IPC::Run::timeout( 10 ) ) ) {
        $logger->warn( "Could not run '" . join( ' ', @cmd ) . "': $!" );
    }
    if ( $err ) {
        $logger->error( "Monitor 'who' error: $err" );
    }
    my @lines = split( /\n/, $out );
    my %users_logged_in;
    
    foreach my $line( @lines ){
        my( $username ) = split( ' ' , $line );
        $users_logged_in{$username}++;
    }
    
    if( $self->{params}{user} ){
        $users_count = $users_logged_in{$self->{params}{user}} || 0;
    }else{
        $users_count = scalar( keys( %users_logged_in ) );
    }
    $logger->debug( sprintf( "Monitor 'who' sees %u users logged in:\n%s", $users_count, $out ) );
    
    if ( $users_count == 0 ) {
        $self->{trigger_pending} ||= time();
        if ( $self->{trigger_pending}
            and ( time() - $self->{trigger_pending} ) >= $self->{params}{trigger_time} )
        {
            # ... and the trigger was set, and time has run out: time to return!
            my $time_since_trigger = time() - $self->{trigger_pending};
            $logger->info( "Monitor 'who' trigger time reached after $time_since_trigger" );
            # Reset the trigger_pending because otherwise if this was a suspend, and the computer comes
            # up again hours/days later, it will immediately fall asleep again...
            $self->{trigger_pending} = 0;
            return 1;
        }

        $logger->info( "Monitor 'who' found no users logged in: trigger pending." );
    } else {
        if ( $self->{trigger_pending} ) {
            $logger->info( "Monitor 'who' trigger time being reset because users are now logged in" );
        }

        # Conditions not met - reset the trigger incase it was previously set.
        $self->{trigger_pending} = 0;
    }
    return 0;
}

=head1 AUTHOR

Robin Clarke, C<perl at robinclarke.net>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Daemon::Shutdown::Monitor::who
