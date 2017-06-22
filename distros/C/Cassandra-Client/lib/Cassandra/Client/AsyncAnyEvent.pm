package Cassandra::Client::AsyncAnyEvent;
use 5.010;
use strict;
use warnings;

use Time::HiRes qw(CLOCK_MONOTONIC);
use vars qw/@TIMEOUTS/;

sub new {
    my ($class, %args)= @_;

    my $options= $args{options};

    require AnyEvent;

    return bless {
        timer_granularity => ($options->{timer_granularity} || 0.1),
        ae_read => {},
        ae_write => {},
        ae_timeout => undef,
        fh_to_obj => {},
        timeouts => [],
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
    undef $self->{ae_timeout} unless @{$self->{timeouts}};
    return;
}

sub register_read {
    my ($self, $fh)= @_;
    my $connection= $self->{fh_to_obj}{$fh} or die;

    $self->{ae_read}{$fh}= AnyEvent->io(
        poll => 'r',
        fh => $fh,
        cb => sub {
            $connection->can_read;
        },
    );

    return;
}

sub register_write {
    my ($self, $fh)= @_;
    my $connection= $self->{fh_to_obj}{$fh} or die;

    $self->{ae_write}{$fh}= AnyEvent->io(
        poll => 'w',
        fh => $fh,
        cb => sub {
            $connection->can_write;
        },
    );

    return;
}

sub unregister_read {
    my ($self, $fh)= @_;
    undef $self->{ae_read}{$fh};

    return;
}

sub unregister_write {
    my ($self, $fh)= @_;
    undef $self->{ae_write}{$fh};

    return;
}

sub deadline {
    my ($self, $fh, $id, $timeout)= @_;
    local *TIMEOUTS= $self->{timeouts};

    if (!$self->{ae_timeout}) {
        $self->{ae_timeout}= AnyEvent->timer(
            after => $self->{timer_granularity},
            interval => $self->{timer_granularity},
            cb => sub { $self->handle_timeouts(Time::HiRes::clock_gettime(CLOCK_MONOTONIC)) },
        );
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
        $self->{ae_timeout}= undef;
    }

    return;
}

sub timer {
    my ($self, $callback, $wait)= @_;
    my $t; $t= AE::timer($wait, 0, sub {
        undef $t;
        $callback->();
    });
}

# $something->($async->wait(my $w)); my ($error, $result)= $w->();
sub wait {
    my ($self)= @_;
    my $output= \$_[1];

    my $cv= AnyEvent->condvar;
    my @output;
    my $callback= sub {
        @output= @_;
        $cv->send;
    };

    $$output= sub {
        $cv->recv;
        return @output;
    };

    return $callback;
}

1;
