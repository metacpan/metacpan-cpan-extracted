package Async::Microservice::Time;

use strict;
use warnings;
use 5.010;
use utf8;
use Moose;

with qw(Async::Microservice);

our $VERSION = 0.01;

use DateTime;
use Time::HiRes qw(time);
use AnyEvent;

sub service_name {
    return 'async-microservice-time';
}

sub get_routes {
    return (
        'datetime' => {
            defaults => {
                GET  => 'GET_datetime',
                POST => 'POST_datetime',
            },
        },
        'epoch' => {defaults => {GET => 'GET_epoch'}},
        'sleep' => {defaults => {GET => 'GET_sleep'}},
    );
}

sub GET_datetime {
    my ($self, $this_req) = @_;
    my $time_zone = $this_req->params->{time_zone} // 'UTC';
    my $time_dt = eval {DateTime->now(time_zone => $time_zone);};
    if ($@) {
        return $this_req->respond(
            405,
            [],
            {   err_status => 405,
                err_msg    => $@,
            }
        );
    }
    return $this_req->respond(200, [], _datetime_as_data($time_dt));
}

sub POST_datetime {
    my ($self, $this_req) = @_;
    my $epoch = eval {$this_req->json_content->{epoch}};
    if (!defined($epoch)) {
        return $this_req->respond(
            405,
            [],
            {   err_status => 405,
                err_msg    => $@ || 'epoch data missing',
            }
        );
    }
    if ($epoch !~ m/^-?[0-9]+$/) {
        return $this_req->respond(
            405,
            [],
            {   err_status => 405,
                err_msg    => 'epoch not a number',
            }
        );
    }
    return $this_req->respond(200, [], _datetime_as_data(DateTime->from_epoch(epoch => $epoch)));
}

sub GET_epoch {
    my ($self, $this_req) = @_;
    return $this_req->respond(200, [], {epoch => time()},);
}

sub GET_sleep {
    my ($self, $this_req) = @_;
    my $start_time = time();
    my $sleep_time = ($this_req->params->{duration} // rand(10)) + 0;
    if ($sleep_time <= 0) {
        return $this_req->respond(
            405,
            [],
            {   err_status => 405,
                err_msg    => 'invalid sleep duration',
            }
        );
    }

    my $w;
    $w = AnyEvent->timer(
        after => $sleep_time,
        cb    => sub {
            $w = undef;
            my $stop_time = time();
            $this_req->respond(
                200,
                [],
                {   start    => $start_time,
                    stop     => $stop_time,
                    duration => ($stop_time - $start_time),
                }
            );
        }
    );

    return;
}

sub _datetime_as_data {
    my ($dt) = @_;
    return {
        datetime       => $dt->strftime('%Y-%m-%d %H:%M:%S %z'),
        date           => $dt->strftime('%Y-%m-%d'),
        time           => $dt->strftime('%H:%M:%S'),
        time_zone      => $dt->strftime('%z'),
        time_zone_name => $dt->strftime('%Z'),
        day            => $dt->strftime('%d'),
        month          => $dt->strftime('%m'),
        year           => $dt->strftime('%Y'),
        hour           => $dt->strftime('%H'),
        minute         => $dt->strftime('%M'),
        second         => $dt->strftime('%S'),
        epoch          => $dt->epoch,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Async::Microservice::Time - example time async microservice

=head1 SYNOPSYS

    # can be started using:
    plackup --port 8085 -Ilib --access-log /dev/null --server Twiggy bin/async-microservice-time.psgi

    curl "http://localhost:8085/v1/hcheck" -H "accept: application/json"
    curl "http://localhost:8085/v1/epoch"  -H "accept: application/json"
    curl "http://localhost:8085/v1/datetime?time_zone=local" -H "accept: application/json"

=head1 DESCRIPTION

This is an example asynchronous http micro service using L<Async::Microservice>.
View the source code it's minimal.

=head1 METHODS

=head2 service_name

Just a name, used to identify process and look for OpenAPI documentation.

=head2 get_routes

L<Path::Router> configuration for dispatching

=head2 http response methods

=head3 GET_datetime

L<https://time.meon.eu/v1/datetime>

=head3 POST_datetime

    $ curl -X POST "https://time.meon.eu/v1/datetime" -H  "accept: application/json" -H  "Content-Type: application/json" -d "{\"epoch\":-42}"
    {
       "date" : "1969-12-31",
       "datetime" : "1969-12-31 23:59:18 +0000",
       "day" : "31",
       "epoch" : -42,
       "hour" : "23",
       "minute" : "59",
       "month" : "12",
       "second" : "18",
       "time" : "23:59:18",
       "time_zone" : "+0000",
       "time_zone_name" : "UTC",
       "year" : "1969"
    }

=head3 GET_epoch

L<https://time.meon.eu/v1/epoch>

=head3 GET_sleep

L<https://time.meon.eu/v1/sleep?duration=2.5>

This is the only parallel processed reponse method (the other ones are
pure CPU-only bound) that sleep given (or random) number of seconds and
only then returns the request response with when it started and how long
it took. Normally this the same as what is in duration parameter, but in
case the server is overloaded with requests, the event loop may call the
timer handler much later than the duration. Try:

    ab -n 1000 -c 500 http://localhost:8085/v1/sleep?duration=3
    Connection Times (ms)
                  min  mean[+/-sd] median   max
    Connect:        0  259 432.8     21    1033
    Processing:  3001 3090  72.5   3061    3253
    Waiting:     3001 3090  72.5   3061    3253
    Total:       3022 3349 394.1   3155    4065

Then try to run together with 100% CPU load:

    ab -q -n 10000 -c 50 http://localhost:8085/v1/datetime

=head3 the rest

Check out L<Async::Microservice> for built-in http response methods.

=head1 SEE ALSO

F<t/02_Async-Microservice-Time.t> for an example how to test this service.

=cut
