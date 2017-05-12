package Catalyst::Plugin::Scheduler;

use strict;
use warnings;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;
use DateTime;
use DateTime::Event::Cron;
use DateTime::TimeZone;
use File::stat;
use Set::Scalar;
use Storable qw/lock_store lock_retrieve/;
use MRO::Compat;

our $VERSION = '0.10';

__PACKAGE__->mk_classdata( '_events' => [] );
__PACKAGE__->mk_accessors('_event_state');

sub schedule {
    my ( $class, %args ) = @_;

    unless ( $args{event} ) {
        Catalyst::Exception->throw(
            message => 'The schedule method requires an event parameter' );
    }

    my $conf = $class->config->{scheduler};
    
    my $event = {
        trigger  => $args{trigger},
        event    => $args{event},
        auto_run => ( defined $args{auto_run} ) ? $args{auto_run} : 1,
    };

    if ( $args{at} ) {

        # replace keywords that Set::Crontab doesn't support
        $args{at} = _prepare_cron( $args{at} );
        
        # parse the cron entry into a DateTime::Set
        my $set;
        eval { $set = DateTime::Event::Cron->from_cron( $args{at} ) };
        if ($@) {
            Catalyst::Exception->throw(
                      "Scheduler: Unable to parse 'at' value "
                    . $args{at} . ': '
                    . $@ );
        }
        else {
            $event->{at}  = $args{at};
            $event->{set} = $set;
        }
    }

    push @{ $class->_events }, $event;
}

sub dispatch {
    my $c = shift;

    $c->maybe::next::method();

    $c->_get_event_state();

    $c->_check_yaml();

    # check if a minute has passed since our last check
    # This check is not run if the user is manually triggering an event
    if ( time - $c->_event_state->{last_check} < 60 ) {
        return unless $c->req->params->{schedule_trigger};
    }
    my $last_check = $c->_event_state->{last_check};
    $c->_event_state->{last_check} = time;
    $c->_save_event_state();

    my $conf          = $c->config->{scheduler};
    my $last_check_dt = DateTime->from_epoch(
        epoch     => $last_check,
        time_zone => $conf->{time_zone}
    );
    my $now = DateTime->now( time_zone => $conf->{time_zone} );

    EVENT:
    for my $event ( @{ $c->_events } ) {
        my $next_run;

        if (   $event->{trigger} && $c->req->params->{schedule_trigger}
            && $event->{trigger} eq $c->req->params->{schedule_trigger} )
        {

            # manual trigger, run it now
            next EVENT unless $c->_event_authorized;
            $next_run = $now;
        }
        else {
            next EVENT unless $event->{set};
            $next_run = $event->{set}->next($last_check_dt);
        }

        if ( $next_run <= $now ) {

            # do some security checking for non-auto-run events
            if ( !$event->{auto_run} ) {
                next EVENT unless $c->_event_authorized;
            }

            # make sure we're the only process running this event
            next EVENT unless $c->_mark_running($event);

            my $event_name = $event->{trigger} || $event->{event};
            $c->log->debug("Scheduler: Executing $event_name")
                if $c->config->{scheduler}->{logging};

            # trap errors
            local $c->{error} = [];
            
            # return value/output from the event, if any
            my $output;

            # run event
            eval {

                # do not allow the event to modify the response
                local $c->res->{body};
                local $c->res->{cookies};
                local $c->res->{headers};
                local $c->res->{location};
                local $c->res->{status};

                if ( ref $event->{event} eq 'CODE' ) {
                    $output = $event->{event}->($c);
                }
                else {
                    $output = $c->forward( $event->{event} );
                }
            };
            my @errors = @{ $c->{error} };
            push @errors, $@ if $@;
            if (@errors) {
                $c->log->error(
                    'Scheduler: Error executing ' . "$event_name: $_" )
                    for @errors;
                $output = join '; ', @errors;
            }

            $c->_mark_finished( $event, $output );
        }
    }
}

sub setup {
    my $c = shift;

    # initial configuration
    $c->config->{scheduler}->{logging}     ||= ( $c->debug ) ? 1 : 0;
    $c->config->{scheduler}->{time_zone}   ||= $c->_detect_timezone();
    $c->config->{scheduler}->{state_file}  ||= $c->path_to('scheduler.state');
    $c->config->{scheduler}->{hosts_allow} ||= '127.0.0.1';
    $c->config->{scheduler}->{yaml_file}   ||= $c->path_to('scheduler.yml');
    
    # Always start with a clean state
    if ( -e $c->config->{scheduler}->{state_file} ) {
        $c->log->debug( 
            'Scheduler: Removing old state file ' .
            $c->config->{scheduler}->{state_file}
        ) if $c->config->{scheduler}->{logging};
        
        unlink $c->config->{scheduler}->{state_file}
            or Catalyst::Exception->throw(
                message => 'Scheduler: Unable to remove old state file '
                    . $c->config->{scheduler}->{state_file} . " ($!)"
            );
    }

    $c->maybe::next::method(@_);
}

sub dump_these {
    my $c = shift;
    
    return ( $c->maybe::next::method(@_) ) unless @{ $c->_events };
        
    # for debugging, we dump out a list of all events with their next
    # scheduled run time
    return ( 
        $c->maybe::next::method(@_),
        [ 'Scheduled Events', $c->scheduler_state ],
    );
}

sub scheduler_state {
    my $c = shift;
    
    $c->_get_event_state();

    my $conf = $c->config->{scheduler};
    my $now  = DateTime->now( time_zone => $conf->{time_zone} );
    
    my $last_check = $c->_event_state->{last_check};
    my $last_check_dt = DateTime->from_epoch(
        epoch     => $last_check,
        time_zone => $conf->{time_zone},
    ); 

    my $event_dump = [];
    for my $event ( @{ $c->_events } ) {
        my $dump = {};
        for my $key ( qw/at trigger event auto_run/ ) {
            $dump->{$key} = $event->{$key} if $event->{$key};
        }

        # display the next run time
        if ( $event->{set} ) {
            my $next_run = $event->{set}->next($last_check_dt);
            $dump->{next_run} 
                = $next_run->ymd 
                . q{ } . $next_run->hms 
                . q{ } . $next_run->time_zone_short_name;
        }
        
        # display the last run time
        my $last_run
            = $c->_event_state->{events}->{ $event->{event} }->{last_run};
        if ( $last_run ) {
            $last_run = DateTime->from_epoch(
                epoch     => $last_run,
                time_zone => $conf->{time_zone},
            );
            $dump->{last_run} 
                = $last_run->ymd
                . q{ } . $last_run->hms
                . q{ } . $last_run->time_zone_short_name;
        }
        
        # display the result of the last run
        my $output
            = $c->_event_state->{events}->{ $event->{event} }->{last_output};
        if ( $output ) {
            $dump->{last_output} = $output;
        }
            
        push @{$event_dump}, $dump;
    }
    
    return $event_dump;
}        

# check and reload the YAML file with schedule data
sub _check_yaml {
    my ($c) = @_;

    # each process needs to load the YAML file independently
    if ( $c->_event_state->{yaml_mtime}->{$$} ||= 0 ) {
        return if ( time - $c->_event_state->{last_check} < 60 );
    }

    return unless -e $c->config->{scheduler}->{yaml_file};

    eval {
        my $mtime = ( stat $c->config->{scheduler}->{yaml_file} )->mtime;
        if ( $mtime > $c->_event_state->{yaml_mtime}->{$$} ) {
            $c->_event_state->{yaml_mtime}->{$$} = $mtime;

            # clean up old PIDs listed in yaml_mtime
            foreach my $pid ( keys %{ $c->_event_state->{yaml_mtime} } ) {
                if ( $c->_event_state->{yaml_mtime}->{$pid} < $mtime ) {
                    delete $c->_event_state->{yaml_mtime}->{$pid};
                }
            }            
            $c->_save_event_state();
            
            # wipe out all current events and reload from YAML
            $c->_events( [] );

            my $file = $c->config->{scheduler}->{yaml_file};
            my $yaml;

            eval { require YAML::Syck; };
            if( $@ ) {
                require YAML;
                $yaml = YAML::LoadFile( "$file" );
            }
            else {
                open( my $fh, $file ) or die $!;
                my $content = do { local $/; <$fh> };
                close $fh;
                $yaml = YAML::Syck::Load( $content );
            }
            
            foreach my $event ( @{$yaml} ) {
                $c->schedule( %{$event} );
            }

            $c->log->info( "Scheduler: PID $$ loaded "
                    . scalar @{$yaml}
                    . ' events from YAML file' )
                if $c->config->{scheduler}->{logging};
        }
    };
    if ($@) {
        $c->log->error("Scheduler: Error reading YAML file: $@");
    }
}

# Detect the current time zone
sub _detect_timezone {
    my $c = shift;

    my $tz;
    eval { $tz = DateTime::TimeZone->new( name => 'local' ) };
    if ($@) {
        $c->log->warn(
            'Scheduler: Unable to autodetect local time zone, using UTC')
            if $c->config->{scheduler}->{logging}; 
        return 'UTC';
    }
    else {
        $c->log->debug(
            'Scheduler: Using autodetected time zone: ' . $tz->name )
            if $c->config->{scheduler}->{logging};
        return $tz->name;
    }
}

# Check for authorized users on non-auto events
sub _event_authorized {
    my $c = shift;

    # this should never happen, but just in case...
    return unless $c->req->address;

    my $hosts_allow = $c->config->{scheduler}->{hosts_allow};
    $hosts_allow = [$hosts_allow] unless ref($hosts_allow) eq 'ARRAY';
    my $allowed = Set::Scalar->new( @{$hosts_allow} );
    return $allowed->contains( $c->req->address );
}

# get the state from the state file
sub _get_event_state {
    my $c = shift;

    if ( -e $c->config->{scheduler}->{state_file} ) {
        $c->_event_state(
            lock_retrieve $c->config->{scheduler}->{state_file} );
    }
    else {

        # initialize the state file
        $c->_event_state(
            {   last_check  => time,
                events      => {},
                yaml_mtime  => {},
            }
        );
        $c->_save_event_state();
    }
}

# Check the state file to ensure we are the only process running an event
sub _mark_running {
    my ( $c, $event ) = @_;

    $c->_get_event_state();

    return if 
        $c->_event_state->{events}->{ $event->{event} }->{running};

    # this is a 2-step process to prevent race conditions
    # 1. write the state file with our PID
    $c->_event_state->{events}->{ $event->{event} }->{running} = $$;
    $c->_save_event_state();

    # 2. re-read the state file and make sure it's got the same PID
    $c->_get_event_state();
    if ( $c->_event_state->{events}->{ $event->{event} }->{running} == $$ ) {
        return 1;
    }

    return;
}

# Mark an event as finished
sub _mark_finished {
    my ( $c, $event, $output ) = @_;

    $c->_event_state->{events}->{ $event->{event} }->{running}     = 0;
    $c->_event_state->{events}->{ $event->{event} }->{last_run}    = time;
    $c->_event_state->{events}->{ $event->{event} }->{last_output} = $output;
    $c->_save_event_state();
}

# update the state file on disk
sub _save_event_state {
    my $c = shift;

    lock_store $c->_event_state, $c->config->{scheduler}->{state_file};
}

# Set::Crontab does not support day names, or '@' shortcuts
sub _prepare_cron {
    my $cron = shift;

    return $cron unless $cron =~ /\w/;

    my %replace = (
        jan   => 1,
        feb   => 2,
        mar   => 3,
        apr   => 4,
        may   => 5,
        jun   => 6,
        jul   => 7,
        aug   => 8,
        sep   => 9,
        'oct' => 10,
        nov   => 11,
        dec   => 12,

        sun => 0,
        mon => 1,
        tue => 2,
        wed => 3,
        thu => 4,
        fri => 5,
        sat => 6,
    );
    
    my %replace_at = (
        'yearly'   => '0 0 1 1 *',
        'annually' => '0 0 1 1 *',
        'monthly'  => '0 0 1 * *',
        'weekly'   => '0 0 * * 0',
        'daily'    => '0 0 * * *',
        'midnight' => '0 0 * * *',
        'hourly'   => '0 * * * *',
    );
    
    if ( $cron =~ /^\@/ ) {
        $cron =~ s/^\@//;
        return $replace_at{ $cron };
    }

    for my $name ( keys %replace ) {
        my $value = $replace{$name};
        $cron =~ s/$name/$value/i;
        last unless $cron =~ /\w/;
    }
    return $cron;
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::Scheduler - Schedule events to run in a cron-like fashion

=head1 SYNOPSIS

    use Catalyst qw/Scheduler/;
    
    # run remove_sessions in the Cron controller every hour
    __PACKAGE__->schedule(
        at    => '0 * * * *',
        event => '/cron/remove_sessions'
    );
    
    # Run a subroutine at 4:05am every Sunday
    __PACKAGE__->schedule(
        at    => '5 4 * * sun',
        event => \&do_stuff,
    );
    
    # A long-running scheduled event that must be triggered 
    # manually by an authorized user
    __PACKAGE__->schedule(
        trigger => 'rebuild_search_index',
        event   => '/cron/rebuild_search_index',
    );
    $ wget -q http://www.myapp.com/?schedule_trigger=rebuild_search_index
    
=head1 DESCRIPTION

This plugin allows you to schedule events to run at recurring intervals.
Events will run during the first request which meets or exceeds the specified
time.  Depending on the level of traffic to the application, events may or may
not run at exactly the correct time, but it should be enough to satisfy many
basic scheduling needs.

=head1 CONFIGURATION

Configuration is optional and is specified in MyApp->config->{scheduler}.

=head2 logging

Set to 1 to enable logging of events as they are executed.  This option is
enabled by default when running under -Debug mode.  Errors are always logged
regardless of the value of this option.

=head2 time_zone

The time zone of your system.  This will be autodetected where possible, or
will default to UTC (GMT).  You can override the detection by providing a
valid L<DateTime> time zone string, such as 'America/New_York'.

=head2 state_file

The current state of every event is stored in a file.  By default this is
$APP_HOME/scheduler.state.  This file is created on the first request if it
does not already exist.

=head2 yaml_file

The location of the optional YAML event configuration file.  By default this
is $APP_HOME/scheduler.yml.

=head2 hosts_allow

This option specifies IP addresses for trusted users.  This option defaults
to 127.0.0.1.  Multiple addresses can be specified by using an array
reference.  This option is used for both events where auto_run is set to 0
and for manually-triggered events.

    __PACKAGE__->config->{scheduler}->{hosts_allow} = '192.168.1.1';
    __PACKAGE__->config->{scheduler}->{hosts_allow} = [ 
        '127.0.0.1',
        '192.168.1.1'
    ];

=head1 SCHEDULING

=head2 AUTOMATED EVENTS

Events are scheduled by calling the class method C<schedule>.
    
    MyApp->schedule(
        at       => '0 * * * *',
        event    => '/cron/remove_sessions',
    );
    
    package MyApp::Controller::Cron;
    
    sub remove_sessions : Private {
        my ( $self, $c ) = @_;
        
        $c->delete_expired_sessions;
    }

=head3 at

The time to run an event is specified using L<crontab(5)>-style syntax.

    5 0 * * *      # 5 minutes after midnight, every day
    15 14 1 * *    # run at 2:15pm on the first of every month
    0 22 * * 1-5   # run at 10 pm on weekdays
    5 4 * * sun    # run at 4:05am every Sunday

From crontab(5):

    field          allowed values
    -----          --------------
    minute         0-59
    hour           0-23
    day of month   1-31
    month          0-12 (or names, see below)
    day of week    0-7 (0 or 7 is Sun, or use names)
    
Instead of the first five fields, one of seven special strings may appear:

    string         meaning
    ------         -------
    @yearly        Run once a year, "0 0 1 1 *".
    @annually      (same as @yearly)
    @monthly       Run once a month, "0 0 1 * *".
    @weekly        Run once a week, "0 0 * * 0".
    @daily         Run once a day, "0 0 * * *".
    @midnight      (same as @daily)
    @hourly        Run once an hour, "0 * * * *".

=head3 event

The event to run at the specified time can be either a Catalyst private
action path or a coderef.  Both types of event methods will receive the $c
object from the current request, but you must not rely on any request-specific
information present in $c as it will be from a random user request at or near
the event's specified run time.

Important: Methods used for events should be marked C<Private> so that
they can not be executed via the browser.

=head3 auto_run

The auto_run parameter specifies when the event is allowed to be executed.
By default this option is set to 1, so the event will be executed during the
first request that matches the specified time in C<at>.

If set to 0, the event will only run when a request is made by a user from
an authorized address.  The purpose of this option is to allow long-running
tasks to execute only for certain users.

    MyApp->schedule(
        at       => '0 0 * * *',
        event    => '/cron/rebuild_search_index',
        auto_run => 0,
    );
    
    package MyApp::Controller::Cron;
    
    sub rebuild_search_index : Private {
        my ( $self, $c ) = @_;
        
        # rebuild the search index, this may take a long time
    }
    
Now, the search index will only be rebuilt when a request is made from a user
whose IP address matches the list in the C<hosts_allow> config option.  To
run this event, you probably want to ping the app from a cron job.

    0 0 * * * wget -q http://www.myapp.com/

=head2 MANUAL EVENTS

To create an event that does not run on a set schedule and must be manually
triggered, you can specify the C<trigger> option instead of C<at>.

    __PACKAGE__->schedule(
        trigger => 'send_email',
        event   => '/events/send_email',
    );
    
The event may then be triggered by a standard web request from an authorized
user.  The trigger to run is specified by using a special GET parameter,
'schedule_trigger'; the path requested does not matter.

    http://www.myapp.com/?schedule_trigger=send_email
    
By default, manual events may only be triggered by requests made from
localhost (127.0.0.1).  To allow other addresses to run events, use the
configuration option L</hosts_allow>.

=head1 SCHEDULING USING A YAML FILE

As an alternative to using the schedule() method, you may define scheduled
events in an external YAML file.  By default, the plugin looks for the
existence of a file called C<scheduler.yml> in your application's home
directory.  You can change the filename using the configuration option
L</yaml_file>.

Modifications to this file will be re-read once per minute during the normal
event checking process.

Here's an example YAML configuration file with 4 events.  Each event is
denoted with a '-' character, followed by the same parameters used by the
C<schedule> method.  Note that coderef events are not supported by the YAML
file.

    ---
    - at: '* * * * *'
      event: /cron/delete_sessions
    - event: /cron/send_email
      trigger: send_email
    - at: '@hourly'
      event: /cron/hourly
    - at: 0 0 * * *
      auto_run: 0
      event: /cron/rebuild_search_index
    
=head1 SECURITY

All events are run inside of an eval container.  This protects the user from
receiving any error messages or page crashes if an event fails to run
properly.  All event errors are logged, even if logging is disabled.

=head1 PLUGIN SUPPORT

Other plugins may register scheduled events if they need to perform periodic
maintenance.  Plugin authors, B<be sure to inform your users> if you do this!
Events should be registered from a plugin's C<setup> method.

    sub setup {
        my $c = shift;        
        $c->maybe::next::method(@_);
        
        if ( $c->can('schedule') ) {
            $c->schedule(
                at    => '0 * * * *',
                event => \&cleanup,
            );
        }
    }
    
=head1 CAVEATS

The time at which an event will run is determined completely by the requests
made to the application.  Apps with heavy traffic may have events run at very
close to the correct time, whereas apps with low levels of traffic may see
events running much later than scheduled.  If this is a problem, you can use
a real cron entry that simply hits your application at the desired time.

    0 * * * * wget -q http://www.myapp.com/

Events which consume a lot of time will slow the request processing for the
user who triggers the event.  For these types of events, you should use
auto_run => 0 or manual event triggering.

=head1 PERFORMANCE

The plugin only checks once per minute if any events need to be run, so the
overhead on each request is minimal.  On my test server, the difference
between running with Scheduler and without was only around 0.02% (0.004
seconds).

Of course, when a scheduled event runs, performance will depend on what's
being run in the event.

=head1 METHODS

=head2 schedule

Schedule is a class method for adding scheduled events.  See the
L<"/SCHEDULING"> section for more information.

=head2 scheduler_state

The current state of all scheduled events is available in an easy-to-use
format by calling $c->scheduler_state.  You can use this data to build an
admin view into the scheduling engine, for example.  This same data is also
displayed on the Catalyst debug screen.

This method returns an array reference containing a hash reference for each
event.

    [
        {
            'last_run'    => '2005-12-29 16:29:33 EST',
            'auto_run'    => 1,
            'last_output' => 1,
            'at'          => '0 0 * * *',
            'next_run'    => '2005-12-30 00:00:00 EST',
            'event'       => '/cron/session_cleanup'
        },
        {
            'auto_run'    => 1,
            'at'          => '0 0 * * *',
            'next_run'    => '2005-12-30 00:00:00 EST',
            'event'       => '/cron/build_rss'
        },
    ]

=head1 INTERNAL METHODS

The following methods are extended by this plugin.

=over 4

=item dispatch

The main scheduling logic takes place during the dispatch phase.

=item dump_these

On the Catalyst debug screen, all scheduled events are displayed along with
the next time they will be executed.

=item setup

=back
    
=head1 SEE ALSO

L<crontab(5)>

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
