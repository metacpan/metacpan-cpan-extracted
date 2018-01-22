package Bot::BasicBot::Pluggable::Module::Nagios;

use warnings;
use strict;

our $VERSION = '0.06';

use base 'Bot::BasicBot::Pluggable::Module';

use Nagios::Scrape;

=head1 NAME

Bot::BasicBot::Pluggable::Module::Nagios - report Nagios alerts to IRC

=head1 DESCRIPTION

A module for IRC bots powered by L<Bot::BasicBot::Pluggable> to monitor a Nagios
install and report alerts to IRC.

Multiple Nagios instances are supported; these could be separate Nagios systems,
or just the same Nagios install but using different credentials.  As each
configured instance can have specific target channels defined, this means you
could have the bot check with the username "development" and report all visible
problems to the C<#development> channel, then check again with the "sysad"
username and report problems visible to that user to the C<#sysads> channel.

Actual monitoring is done using L<Nagios::Scrape>, which scrapes the information
from the C<status.cgi> script which powers Nagios' web interface.  This means
that, assuming your Nagios setup is configured to be viewable over the web, you
need no further setup to allow the bot to monitor it.


=head1 SYNOPSIS

Load the module as you would any other L<Bot::BasicBot::Pluggable> module, then
configure it to watch a Nagios install and report problems to the desired
channel(s) with the C<nagios add> command.

In a direct message to the bot:

    <user> nagios add http://nagios.example.com/cgi-bin/status.cgi username password #channel
    <bot> OK
    <user> nagios list
    <bot> I'm currently monitoring the following Nagios instances:
          .. 1 : http://example.com/cgi-bin/status.cgi as dave for #chan
    <user> nagios del 1
    <bot> OK, deleted instance 1

(You can supply a list of channel names separated by commas, if you want reports
from a given instance to be announced to more than one channel.)

=cut


sub help {
    return <<USAGE;
A module to report Nagios alerts to IRC channels.

   !nagios add http://example.com/cgi-bin/status.cgi username password #chan
   !nagios list
   !nagios del 1
   !nagios set setting_name value

Say "!nagios set" with no setting name for a list of valid settings.

Full help is available at http://p3rl.org/Bot::BasicBot::Pluggable::Module::Nagios
USAGE
}

sub told {
    my ($self, $mess) = @_;

    return unless $mess->{address} && $mess->{body} =~ s/^!nagios\s+//i;
    my ($command, $params) = split /\s+/, $mess->{body}, 2;
    if (lc $command eq 'add') {
        my($url, $user, $pass, $channel_list) = split /\s+/, $params, 4;
        if ($url !~ /^http/i) {
            return "URL looks invalid!";
        }
        my @channels = split /\s+|,/, $channel_list;
        my $instances = $self->get('instances') || [];

        my $instance = {
            url      => $url,
            user     => $user,
            pass     => $pass,
            channels => \@channels,
        };

        my $poll_result = $self->poll_instance($instance);
        if ($poll_result->{error}) {
            my $instance_name = $self->instance_name($instance);
            return "Failed to poll $instance_name - "
                . $poll_result->{error} . " - not adding it";
        }

        push @$instances, $instance;
        $self->set('instances' => $instances);
        return "OK, added Nagios instance to monitor";
    }
    if (lc $command eq 'list') {
        my $instances = $self->get('instances') || [];
        if (!@$instances) {
            return "I'm not currently monitoring any Nagios instances.";
        }
        my $response = "I'm currently monitoring the following instances:\n";
        my $num = 0;
        for my $instance (@$instances) {
            $response .= sprintf "%d : %s as %s for %s\n",
                $num++,
                $instance->{url},
                $instance->{user},
                join ',', @{ $instance->{channels} };
        }
        return $response;
    }
    if (lc $command eq 'del' || lc $command eq 'delete') {
        my $num = $params;
        if ($num !~ /^\d+$/) {
            return "Usage: nagios del instancenum (e.g. 'nagios del 1')";
        }
        my $instances = $self->get('instances') || [];
        if (!$instances->[$num]) {
            return "No such instance";
        }
        splice @$instances, $num;
        $self->set('instances', $instances);
        return "OK, deleted instance $num";
    }
    if (lc $command eq 'set') {
        my ($setting, $value) = split /\s+/, $params, 2;
        $setting = lc $setting;
        
        # Validator for durations, which recognises e.g. 30m and turns into
        # seconds
        my $validate_duration = sub {
            my $value = lc shift;
            if (my($num,$unit) = $value =~ m{^
                (\d+)
                (
                    s(?:ecs?)?
                    |
                    m(?:mins?)?
                    |
                    h(?:hours?)?
                )?
            $}x) {
                my $multiplier = {
                    s => 1,
                    m => 60,
                    h => 60 * 60,
                }->{$unit} || 1;
                return $num * $multiplier;
            } else {
                return;
            }
        };

        # Declare the settings we accept, what they should look like, and their
        # description
        my $duration_help = " (in seconds, or with unit, e.g. 60, 3m, 5h)";
        my %valid_settings = (
            poll_interval => {
                description => "Interval between polls to Nagios"
                    . $duration_help,
                validator   => $validate_duration,
            },
            repeat_delay => {
                description => "Time between repeated notifications "
                    . "of the same issue" . $duration_help,
                validator   => $validate_duration,
            },
            report_statuses => {
                description => "List of statuses we should notify for"
                    . " (default: CRITICAL, WARNING, OK, UPDATE_FAIL)",
                validator   => sub {
                    my @statuses = split /[\s,]+/, uc shift;
                    return unless @statuses;
                    return if 
                        grep { 
                            !/^(OK|WARNING|CRITICAL|UNKNOWN|UPDATE_FAIL)$/
                        } @statuses;
                    return \@statuses;
                },
            },
            filter_services => {
                description => "A regex to match services which"
                    . " should be ignored",
                validator => sub {
                    my $in = shift;
                    my $re;
                    eval {
                        $re = qr/$in/;
                    };
                    return if $@;
                    return $in;
                },
            },
                    
        );

        # If we were called without a setting name, reply with the settings
        # which are valid:
        if (!$setting) {
            my $reply = "Valid settings are:\n";
            for my $setting (keys %valid_settings) {
                $reply .= sprintf "%s (%s)\n",
                    $setting, $valid_settings{$setting}->{description};
            }
            return $reply;
        }

        my $validator = $valid_settings{$setting}->{validator};
        if (!$validator) {
            return sprintf "Unknown setting '%s' (known settings: %s)",
                $setting,
                join ',', keys %valid_settings;
        }

        # The validator will return the value (possibly canonicalised) if it was
        # acceptable, or undef if not:
        if (defined(my $valid_value = $validator->($value))) {
            $self->set($setting, $valid_value);
            my $show_value = ref $valid_value eq 'ARRAY' 
                ? join(',', @$valid_value) : $valid_value;
            return "OK, set $setting to '$show_value'";
        } else {
            return "Value '$value' is not valid for setting $setting";
        }
    }
}

my $last_polled = 0;
my %last_status;
my %last_update_failure;

sub tick {
    my ($self) = @_;

    my $repeat_delay = $self->get('repeat_delay') || 15 * 60;
    my $poll_delay = $self->get('poll_interval') || 120;
    return if (time - $last_polled < $poll_delay);
    $last_polled = time;

    # OK, time to poll Nagios and report stuff.
    $self->check_nagios;
}

sub instance_name {
    my ($self, $instance) = @_;
    return join "@", @$instance{qw(user url)};
}

# Polls the specified Nagios instance and returns all host and service
# statuses.  Returns a hashref with keys hosts, services, and possibly
# error, if there was one.
sub poll_instance {
    my ($self, $instance) = @_;

    my $ns = Nagios::Scrape->new(
        username => $instance->{user},
        password => $instance->{pass},
        url      => $instance->{url},
    );

    # Get a list of all hosts, and assemble a lookup hash so we can
    # easily look up whether a host is down in order to skip reporting
    # services
    $ns->host_state(14); # All hosts, including OK ones
    my @all_hosts;
    # Nagios::Scrape will die() on error
    eval { @all_hosts = $ns->get_host_status; 1 };

    if (my $eval_error = $@) {
        my $error = sprintf "Failed to poll hosts on %s - %s",
            $self->instance_name($instance), $eval_error;
        warn $error;
        return { error => $error };
    }

    if (!@all_hosts) {
        my $error = "No hosts returned for " . $self->instance_name($instance);
        warn $error;
        return { error => $error };
    }

    # Get services in all states except PENDING - we want OK ones, too, so
    # we can easily report problem -> OK transitions
    # PENDING 1 OK 2 WARNING 4 UNKNOWN 8 CRITICAL 16
    # 16 + 8 + 4 + 2 = 30 = OK/WARNING/UNKNOWN/CRITICAL
    # TODO: make state filter configurable
    $ns->service_state(30);

    my @service_statuses;
    eval { @service_statuses = $ns->get_service_status; };
    if (my $eval_error = $@) {
        my $error = sprintf "Failed to poll services on %s - %s",
            $self->instance_name($instance), $eval_error;
        warn $error;
        return { error => $error };
    }

    if (!@service_statuses) {
        my $error = "No services returned for "
            . $self->instance_name($instance);
        warn $error;
        return { error => $error };
    }

    # OK, looks good, return the service and host statuses we found.
    return {
        services => \@service_statuses,
        hosts    => \@all_hosts,
    };
}

sub check_nagios {
    my ($self) = @_;

    my $repeat_delay = $self->get('repeat_delay') || 15 * 60;


    # Find out what statuses we should report; do this here, so it's ready for
    # use in the loop later (we don't want to re-do it for every service :) )
    my $report_statuses = $self->get('report_statuses')
        || [ qw( CRITICAL WARNING OK UPDATE_FAIL ) ];
    my %should_report = map { $_ => 1 } @$report_statuses;


    my $instances = $self->get('instances') || [];
    instance:
    for my $instance (@$instances) {
        my $instance_name = $self->instance_name($instance);
        my $result = $self->poll_instance($instance);

        # First, if there was an error polling this instance, report it and move
        # on:
        if ($result->{error} && $should_report{UPDATE_FAIL}) {
            my $instance_name = $self->instance_name($instance);
            if (time - $last_update_failure{$instance_name}
                > $repeat_delay)
            {
                for my $channel (@{ $instance->{channels} }) {
                    $self->tell(
                        $channel,
                        "NAGIOS: Update failure for $instance_name: "
                            . $result->{error}
                    );
                }
            }
            $last_update_failure{$instance_name} = time;
            next instance;
        }
        
        my %host_down  = 
            map  { $_->{host} => 1        } 
            grep { $_->{status} eq 'DOWN' }
            @{ $result->{hosts} };


        my $instance_statuses = $last_status{$instance_name} ||= {};

        # Firstly, report host status changes:
        my @host_reports;
        host:
        for my $host (@{ $result->{hosts} }) {
            if (my $last_status = $instance_statuses->{$host->{host}}) {
                # If it was UP before and is still UP, move on swiftly
                next if $last_status->{status} eq 'UP'
                    and $host->{status} eq 'UP';

                # If we've reported it as down recently, don't do so again yet
                if ($last_status->{status} eq $host->{status}
                    && time - $last_status->{timestamp} < $repeat_delay)
                {
                    next host;
                }

                # OK, we need to announce that this host is down
                push @host_reports, $host;
            } else {
                # We've not seen this one before; if it's 'UP', just remember 
                # but don't announce it, otherwise we'd send a flood of UP
                # notifications on first run
                if ($host->{status} eq 'UP') {
                    $instance_statuses->{$host->{host}} =
                        { timestamp => time(), status => $host->{status} };
                    next host;
                } else {
                    # First result for this host, but it's down - announce:
                    push @host_reports, $host;
                }
            }

            # Now we've decided if we need to report any hosts, go ahead and
            # do so, and remember we did
            for my $host (@host_reports) {
                for my $channel (@{ $instance->{channels} }) {
                    $self->tell($channel,
                        "NAGIOS: Host $host->{host} is $host->{status}"
                    );
                    $instance_statuses->{$host->{host}} =
                        { timestamp => time(), status => $host->{status} };
                }
            }
        }

        # Fetch & compile the service filtering regex once, rather than once for
        # each service:
        my $filter_re = $self->get('filter_services') || '';
        $filter_re = qr($filter_re) if $filter_re;

        # Group problems by host, ignoring any which we've already reported 
        # recently, or which are on a host which is down.
        my %service_by_host;
        service:
        for my $service (@{ $result->{services} }) {
            next if $host_down{$service->{host}};

            # Skip it if we should be filtering it out
            next if $filter_re && $service->{service} !~ $filter_re;

            # See how many check attempts have found the service in this status;
            # if it's not enough for Nagios to send alerts, don't alert on IRC.
            # Don't do this if the status is "OK", though, as "OK" services
            # always show as e.g. 1/4.
            my ($attempt, $max_attempts) = split '/', $service->{attempts};
            next service if $service->{status} ne 'OK' &&  $attempt < $max_attempts;

            my $service_key = join '_', $service->{host}, $service->{service};
            if (my $last_status = $instance_statuses->{$service_key}) {
                # If it was OK before and still OK now, move on swiftly
                next if $last_status->{status} eq 'OK'
                    and $service->{status} eq 'OK';

                # If we've already seen it in this status, don't report it again
                # until the $repeat_delay is up
                if ($last_status->{status} eq $service->{status}
                    && time - $last_status->{timestamp} < $repeat_delay)
                {
                    next service;
                }

            } else {
                # We've not seen this one before; if it's 'OK', just remember it
                # but don't announce it, otherwise we'd send a flood of OK
                # notifications on first run
                if ($service->{status} eq 'OK') {
                    $instance_statuses->{$service_key} =
                        { timestamp => time(), status => $service->{status} };
                    next service;
                }
            }

            # See if it's a status we should report.  
            next service if !$should_report{ $service->{status} };

            # Note that we're about to bitch about this one, and add it to
            # %service_by_host ready for reporting
            $instance_statuses->{$service_key} = { 
                timestamp => time(), status => $service->{status},
            };
            push @{ $service_by_host{ $service->{host} } }, $service;
        }

        for my $host (sort keys %service_by_host) {
            my $msg = "NAGIOS: $host : "
                . join ', ',
                map { "$_->{service} is $_->{status} ($_->{information})" }
                @{ $service_by_host{$host} };
            for my $channel (@{$instance->{channels}}) {
                $self->tell($channel, $msg);
            }
        }
    }
}



=head1 TODO

Plenty of improvements are planned, including:

=over 4

=item * Better documentation

I need to improve the module's documentation.  For now, extra information is
available by saying <help nagios> to the bot on IRC, or C<nagios set> with no
setting name for a list of valid settings with descriptions.

I'd rather work out a good way to auto-generate documentation from the settings
definitions in the code in order to make sure the docs stay in sync.

=item * Acknowledging problems

It should probably be possible to acknowledge a reported problem, preventing
repeated reports of the same service/host in the same state.

=item * Configurable reporting hours

It would make sense to be able to configure the bot to only report problems
during hours in which staff/volunteers are likely to be awake and paying
attention to the IRC channel.

=item * Configurable report templates

It would be nice to be able to configure the format used for report messages -
perhaps including colour codes to colourise elements of the message, where the
channel allows it and users clients support it.

=back

=head1 AUTHOR

David Precious, C<< <davidp at preshweb.co.uk> >>

=head1 CONTRIBUTING

This module is developed on GitHub:

L<https://github.com/bigpresh/Bot-BasicBot-Pluggable-Module-Nagios>

Pull requests / suggestions / bug reports are welcomed.

If you feel like it, even a "I'm using this and find it useful" mail to
C<davidp@preshweb.co.uk> would be appreciated - it's nice to know when people
find your work useful.

(Reviews on cpanratings and/or ++'s on MetaCPAN are also very welcome.)



=head1 SUPPORT / BUGS / FEATURE REQUESTS

You can find documentation for this module with the perldoc command.

    perldoc Bot::BasicBot::Pluggable::Module::Nagios

You can report bugs or make feature requests using GitHub Issues:

L<https://github.com/bigpresh/Bot-BasicBot-Pluggable-Module-Nagios/issues>



=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2018 David Precious.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Bot::BasicBot::Pluggable::Module::Nagios
