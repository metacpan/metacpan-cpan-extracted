package Cassandra::Client::AsyncEV;
use 5.010;
use strict;
use warnings;

use Time::HiRes qw(CLOCK_MONOTONIC);
use vars qw/@TIMEOUTS/;

sub new {
    my ($class, %args)= @_;

    my $options= $args{options};

    require EV;

    return bless {
        timer_granularity => ($options->{timer_granularity} || 0.1),
        ev_read => {},
        ev_write => {},
        ev_timeout => undef,
        fh_to_obj => {},
        timeouts => [],
        ev => EV::Loop->new(),
    }, $class;
}

sub register {
    my ($self, $fh, $connection)= @_;
    $self->{fh_to_obj}{$fh}= $connection;
    return;
}

sub unregister {
    my ($self, $fh)= @_;
    delete $self->{fh_to_obj}{$fh};
    if ($self->{timeouts} && grep { $_->[1] == $fh && !$_->[3] } @{$self->{timeouts}}) {
        warn 'In unregister(): not all timeouts were dismissed!';
    }
    @{$self->{timeouts}}= grep { $_->[1] != $fh } @{$self->{timeouts}};
    undef $self->{ev_timeout} unless @{$self->{timeouts}};
    return;
}

sub register_read {
    my ($self, $fh)= @_;
    my $connection= $self->{fh_to_obj}{$fh} or die;

    $self->{ev_read}{$fh}= $self->{ev}->io( $fh, &EV::READ, sub { $connection->can_read } );
    return;
}

sub register_write {
    my ($self, $fh)= @_;
    my $connection= $self->{fh_to_obj}{$fh} or die;

    $self->{ev_write}{$fh}= $self->{ev}->io( $fh, &EV::WRITE, sub { $connection->can_write } );
    return;
}

sub unregister_read {
    my ($self, $fh)= @_;
    undef $self->{ev_read}{$fh};

    return;
}

sub unregister_write {
    my ($self, $fh)= @_;
    undef $self->{ev_write}{$fh};

    return;
}

sub deadline {
    my ($self, $fh, $id, $timeout)= @_;
    local *TIMEOUTS= $self->{timeouts};

    if (!$self->{ev_timeout}) {
        $self->{ev_timeout}= $self->{ev}->timer( $self->{timer_granularity}, $self->{timer_granularity}, sub {
            $self->handle_timeouts(Time::HiRes::clock_gettime(CLOCK_MONOTONIC));
        } );
    }

    my $curtime= Time::HiRes::clock_gettime(CLOCK_MONOTONIC);
    my $deadline= $curtime + $timeout;
    my $additem= [ $deadline, $fh, $id, 0 ];

    if (@TIMEOUTS && $TIMEOUTS[-1][0] > $deadline) {
        # Grumble... that's slow
        push @TIMEOUTS, $additem;
        @TIMEOUTS= sort { $a->[0] <=> $b->[0] } @TIMEOUTS;
    } else {
        # Common case
        push @TIMEOUTS, $additem;
    }

    return \($additem->[3]);
}

sub handle_timeouts {
    my ($self, $curtime)= @_;

    local *TIMEOUTS= $self->{timeouts};

    my %triggered_read;
    while (@TIMEOUTS && $curtime >= $TIMEOUTS[0][0]) {
        my $item= shift @TIMEOUTS;
        if (!$item->[3]) { # If it timed out
            my ($deadline, $fh, $id, $timedout)= @$item;
            my $obj= $self->{fh_to_obj}{$fh};
            $obj->can_read unless $triggered_read{$fh}++;
            $obj->can_timeout($id) unless $item->[3]; # We may have received an answer...
        }
    }

    if (!@TIMEOUTS) {
        $self->{ev_timeout}= undef;
    }

    return;
}

sub timer {
    my ($self, $callback, $wait)= @_;
    my $t; $t= $self->{ev}->timer($wait, 0, sub {
        undef $t;
        $callback->();
    });
}

# $something->($async->wait(my $w)); my ($error, $result)= $w->();
sub wait {
    my ($self)= @_;
    my $output= \$_[1];

    my ($done, $in_run);
    my @output;
    my $callback= sub {
        $done= 1;
        @output= @_;
        $self->{ev}->break() if $in_run;
    };

    $$output= sub {
        if ($self->{in_wait}) {
            die "Unable to recursively wait for callbacks; are you doing synchronous Cassandra queries from asynchronous callbacks?";
        }
        local $self->{in_wait}= 1;

        $in_run= 1;
        $self->{ev}->run unless $done;
        return @output;
    };

    return $callback;
}

1;
