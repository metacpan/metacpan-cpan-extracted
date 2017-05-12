package Daemon::Shutdown;

use warnings;
use strict;
use YAML::Any qw/Dump LoadFile/;
use Log::Log4perl;
use Params::Validate qw/:all/;
use File::Basename;
use IPC::Run;
use User;
use AnyEvent;
use Try::Tiny;

our $VERSION = '0.13';

=head1 NAME

Daemon::Shutdown - A Shutdown Daemon

=head1 SYNOPSIS

This is the core of the shutdown daemon script.
 
use Daemon::Shutdown;
my $sdd = Daemon::Shutdown->new( %args );
$sdd->start();

=head1 METHODS

=head2 new

Create new instance of Daemon::Shutdown

=head3 PARAMS

=over 2

=item log_file <Str>

Path to log file

Default: /var/log/sdd.log'

=item log_level <Str>

Logging level (from Log::Log4perl).  Valid are: DEBUG, INFO, WARN, ERROR

Default: INFO

=item verbose 1|0

If enabled, logging info will be printed to screen as well

Default: 0

=item test 1|0

If enabled shutdown will not actually be executed.

Default: 0

=item sleep_before_run <Int>

Time in seconds to sleep before running the monitors.
e.g. to give the system time to boot, and not to shut down before users
have started using the freshly started system.

Default: 3600

=item exit_after_trigger 1|0

If enabled will exit the application after a monitor has triggered.
Normally it is a moot point, because if a monitor has triggered, then a shutdown
is initialised, so the script will stop running anyway.

Default: 0

=item monitor HASHREF

A hash of monitor definitions.  Each hash key must map to a Monitor module, and
contain a hash with the parameters for the module.

=item use_sudo 1|0

Use sudo for shutdown
 
sudo shutdown -h now

Default: 0

=item shutdown_binary <Str>

The full path to the shutdown binary

Default: /sbin/poweroff

=item shutdown_args <ArrayRef>

Any args to pass to your shutdown_binary

Default: none

=item shutdown_after_triggered_monitors <Str>

The number of monitors which need to be triggered at the same time to cause a 
shutdown. Can be a number or the word 'all'.

Default: 1

=item timeout_for_shutdown <Int>

Seconds which the system call for shutdown should wait before timing out.

Default: 10

=back

=head3 Example (YAML formatted) configuration file

  ---
  log_level: INFO
  log_file: /var/log/sdd.log
  shutdown_binary: /sbin/shutdown
  shutdown_args:
    - -h
    - now
  exit_after_trigger: 0
  sleep_before_run: 30
  verbose: 0
  use_sudo: 0
  monitor:
    hdparm:
      loop_sleep: 60
      disks: 
        - /dev/sdb
        - /dev/sdc
        - /dev/sdd
=cut

sub new {
    my $class = shift;

    my %params = @_;

    # Remove any undefined parameters from the params hash
    map { delete( $params{$_} ) if not $params{$_} } keys %params;

    # Validate the config file
    %params = validate_with(
        params => \%params,
        spec   => {
            config => {
                callbacks => {
                    'File exists' => sub { -f shift }
                },
                default => '/etc/sdd.conf',
            },
        },
        allow_extra => 1,
    );
    my $self = {};

    # Read the config file
    if ( not $params{config} ) {
        $params{config} = '/etc/sdd.conf';
    }
    if ( not -f $params{config} ) {
        die( "Config file $params{config} not found\n" );
    }
    my $file_config = LoadFile( $params{config} );
    delete( $params{config} );

    # Merge the default, config file, and passed parameters
    %params = ( %$file_config, %params );

    my @validate = map { $_, $params{$_} } keys( %params );
    %params = validate_with(
        params => \%params,
        spec   => {
            log_file => {
                default   => '/var/log/sdd.log',
                callbacks => {
                    'Log file is writable' => sub {
                        my $filepath = shift;
                        if ( -f $filepath ) {
                            return -w $filepath;
                        } else {

                            # Is directory writable
                            return -w dirname( $filepath );
                        }
                    },
                },
            },
            log_level => {
                default => 'INFO',
                regex   => qr/^(DEBUG|INFO|WARN|ERROR)$/,
            },
            verbose => {
                default => 0,
                regex   => qr/^[1|0]$/,
            },
            test => {
                default => 0,
                regex   => qr/^[1|0]$/,
            },
            sleep_before_run => {
                default => 3600,
                regex   => qr/^\d*$/,
            },
            exit_after_trigger => {
                default => 0,
                regex   => qr/^[1|0]$/,
            },
            use_sudo => {
                default => 0,
                regex   => qr/^[1|0]$/,
            },
            shutdown_binary => {
                default   => '/sbin/poweroff',
                type      => SCALAR,
                callbacks => {
                    'Shutdown binary exists' => sub {
                        -x shift();
                    },
                },
            },
            shutdown_args => {
                type     => ARRAYREF,
                optional => 1
            },
            monitor                           => { type => HASHREF, },
            shutdown_after_triggered_monitors => {
                default => 1,
                type    => SCALAR,
                regex   => qr/^(all|\d+)$/,
            },
            timeout_for_shutdown    => {
                default => 10,
                regex   => qr/^\d+$/,
            }
        },

        # A little less verbose than Carp...
        on_fail => sub { die( shift() ) },
    );

    $self->{params} = \%params;

    bless $self, $class;

    # Set up the logging
    my $log4perl_conf = sprintf 'log4perl.rootLogger = %s, Logfile', $params{log_level} || 'WARN';
    if ( $params{verbose} > 0 ) {
        $log4perl_conf .= q(, Screen
            log4perl.appender.Screen         = Log::Log4perl::Appender::Screen
            log4perl.appender.Screen.stderr  = 0
            log4perl.appender.Screen.layout   = Log::Log4perl::Layout::PatternLayout
            log4perl.appender.Screen.layout.ConversionPattern = [%d] %p %m%n
        );

    }

    $log4perl_conf .= q(
        log4perl.appender.Logfile          = Log::Log4perl::Appender::File
        log4perl.appender.Logfile.layout   = Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Logfile.layout.ConversionPattern = [%d] %p %m%n
    );
    $log4perl_conf .= sprintf "log4perl.appender.Logfile.filename = %s\n", $params{log_file};

    # ... passed as a reference to init()
    Log::Log4perl::init( \$log4perl_conf );
    my $logger = Log::Log4perl->get_logger();
    $self->{logger} = $logger;

    $self->{is_root} = ( User->Login eq 'root' ? 1 : 0 );
    $self->{logger}->info( "You are " . User->Login );

    if ( not $self->{is_root} ) {
        $self->{logger}->warn( "You are not root. SDD will probably not work..." );
    }

    # Load the monitors
    my %monitors;
    foreach my $monitor_name ( keys( %{ $params{monitor} } ) ) {
        eval {
            my $monitor_package = 'Daemon::Shutdown::Monitor::' . $monitor_name;
            my $monitor_path    = 'Daemon/Shutdown/Monitor/' . $monitor_name . '.pm';
            require $monitor_path;

            $monitors{$monitor_name} = $monitor_package->new( %{ $params{monitor}->{$monitor_name} } );
        };
        if ( $@ ) {
            die( "Could not initialise monitor: $monitor_name\n$@\n" );
        }
    }
    $self->{monitors}           = \%monitors;
    $self->{triggered_monitors} = {};

    my $num_monitors = keys %monitors;
    if (   $self->{params}->{shutdown_after_triggered_monitors} eq 'all'
        || $self->{params}->{shutdown_after_triggered_monitors} > $num_monitors )
    {
        $self->{params}->{shutdown_after_triggered_monitors} = $num_monitors;
    }

    $logger->debug(
        sprintf "Will shutdown if %d of %d monitors agree",
        $self->{params}->{shutdown_after_triggered_monitors},
        $num_monitors
    );
    $self->{num_triggered_monitors} = 0;
    return $self;
}

=head2 toggle_trigger

Toggle whether a monitor wants to shutdown and, if enough agree, call shutdown

=cut

sub toggle_trigger {
    my ( $self, $monitor_name, $toggle ) = @_;
    my $logger = $self->{logger};

    if ( !defined $toggle || $toggle !~ /^0|1$/ ) {
        $logger->logdie( "Called with invalid value for toggle" );
    }

    # set/unset the toggle
    if ( $toggle and not $self->{triggered_monitors}->{$monitor_name} ) {
        $self->{triggered_monitors}->{$monitor_name} = 1;
    } elsif ( $self->{triggered_monitors}->{$monitor_name} and not $toggle ) {
        delete( $self->{triggered_monitors}->{$monitor_name} );
    } else { 
        # seen it before, do care, because maybe last attempt to shutdown failed?
    }

    # Store how many are triggered, and shutdown if limit reached
    $self->{num_triggered_monitors} = scalar keys %{ $self->{triggered_monitors} };
    $logger->debug( $self->{num_triggered_monitors} . " monitors are ready to shutdown" );
    if ( $self->{num_triggered_monitors} >= $self->{params}->{shutdown_after_triggered_monitors} ) {
        $self->shutdown();
    }
}

=head2 shutdown

Shutdown the system, if not in test mode

=cut

sub shutdown {
    my $self   = shift;
    my $logger = $self->{logger};

    $logger->info( "Shutting down" );

    if ( $self->{params}->{test} ) {
        $logger->info( "Not really shutting down because running in test mode" );
    } else {

        # Do the actual shutdown
        my @cmd = ( $self->{params}->{shutdown_binary} );

        # have any args?
        if ( $self->{params}->{shutdown_args} ) {
            push @cmd, @{ $self->{params}->{shutdown_args} };
        }

        if ( $self->{params}->{use_sudo} ) {
            unshift( @cmd, 'sudo' );
        }
        $logger->debug( "Shutting down with cmd: " . join( ' ', @cmd ) );

        # Sometimes the shutdown call can timeout (system unresponsive?). In this case, don't
        # die, and also don't exit_after_trigger - allow the trigger to hit again, and try again.
        try {
            my ( $in, $out, $err );
            IPC::Run::run( \@cmd, \$in, \$out, \$err, IPC::Run::timeout( $self->{params}->{timeout_for_shutdown} ) );
            if ( $err ) {
                $logger->error( "Could not shutdown: $err" );
            }
            if ( $self->{params}->{exit_after_trigger} ) {
                exit;
            }
        }
        catch {
            $logger->error( "Shutdown command failed '" . join( ' ', @cmd ) . "': $_" );
        };
    }
}

=head2 start

Start the shutdown daemon

=cut

sub start {
    my $self   = shift;
    my $logger = $self->{logger};

    $logger->info( "Started" );

    $logger->info( "Sleeping $self->{params}->{sleep_before_run} seconds before starting monitoring" );

    sleep( $self->{params}->{sleep_before_run} );

    # set up timers then wait forever
    foreach my $monitor_name ( keys %{ $self->{monitors} } ) {
        my $monitor = $self->{monitors}->{$monitor_name};

        $logger->debug( "Setting timer for monitor $monitor_name: $monitor->{params}->{loop_sleep} seconds" );
        $monitor->{timer} = AnyEvent->timer(
            after    => 0,
            interval => $monitor->{params}->{loop_sleep},
            cb       => sub {
                if ( $monitor->run() ) {
                    $self->toggle_trigger( $monitor_name, 1 );
                } else {
                    $self->toggle_trigger( $monitor_name, 0 );
                }
            }
        );
    }
    $logger->debug( 'Entering main listen loop using ' . $AnyEvent::MODEL );
    AnyEvent::CondVar->recv;

}

=head1 AUTHOR

Robin Clarke, C<perl at robinclarke.net>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/robin13/sdd>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Daemon::Shutdown


You can also look for information at:

=over 4

=item * Github

L<https://github.com/robin13/sdd>

=item * Search CPAN

L<http://search.cpan.org/dist/Daemon/Shutdown/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Robin Clarke.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Daemon::Shutdown
