package MHFS::EventLoop::Poll::Base v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use POSIX ":sys_wait_h";
use IO::Poll qw(POLLIN POLLOUT POLLHUP);
use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
use Scalar::Util qw(looks_like_number);
use Data::Dumper;
use Devel::Peek;
#use Devel::Refcount qw( refcount );

use constant POLLRDHUP => 0;
use constant ALWAYSMASK => (POLLRDHUP | POLLHUP);

# You must provide event handlers for the events you are listening for
# return undef to have them removed from poll's structures

sub _decode_status {
    my ($rc) = @_;
    print "$rc: normal exit with code ". WEXITSTATUS($rc)."\n" if WIFEXITED(  $rc);
    print "$rc: terminated with signal ".WTERMSIG(   $rc)."\n" if WIFSIGNALED($rc);
    print "$rc: stopped with signal ".   WSTOPSIG(   $rc)."\n" if WIFSTOPPED( $rc);
}

sub new {
    my ($class) = @_;
    my %self = ('poll' => IO::Poll->new(), 'fh_map' => {}, 'timers' => [], 'children' => {}, 'deadchildren' => []);
    bless \%self, $class;

    $SIG{CHLD} = sub {
        while((my $child = waitpid(-1, WNOHANG)) > 0) {
            my ($wstatus, $exitcode) = ($?, $?>> 8);
            if(defined $self{'children'}{$child}) {
                say "PID $child reaped (func) $exitcode";
                push @{$self{'deadchildren'}}, [$self{'children'}{$child}, $child, $wstatus];
                $self{'children'}{$child} = undef;
            }
            else {
                say "PID $child reaped (No func) $exitcode";
            }
        }
    };

    return \%self;
}

sub register_child {
    my ($self, $pid, $cb) = @_;
    $self->{'children'}{$pid} = $cb;
}

sub run_dead_children_callbacks {
    my ($self) = @_;
    while(my $chld = shift(@{$self->{'deadchildren'}})) {
        say "PID " . $chld->[1] . ' running SIGCHLD cb';
        $chld->[0]($chld->[2]);
    }
}

sub set {
    my ($self, $handle, $obj, $events) = @_;
    $self->{'poll'}->mask($handle, $events);
    $self->{'fh_map'}{$handle} = $obj;
}

sub getEvents {
    my ($self, $handle) = @_;
    return $self->{'poll'}->mask($handle);
}

sub remove {
    my ($self, $handle) = @_;
    $self->{'poll'}->remove($handle);
    $self->{'fh_map'}{$handle} = undef;
}


sub _insert_timer {
    my ($self, $timer) = @_;
    my $i;
    for($i = 0; defined($self->{'timers'}[$i]) && ($timer->{'desired'} >= $self->{'timers'}[$i]{'desired'}); $i++) { }
    splice @{$self->{'timers'}}, $i, 0, ($timer);
    return $i;
}


# all times are relative, is 0 is set as the interval, it will be run every main loop iteration
# return undef in the callback to delete the timer
sub add_timer {
    my ($self, $start, $interval, $callback, $id) = @_;
    my $current_time = clock_gettime(CLOCK_MONOTONIC);
    my $desired = $current_time + $start;
    my $timer = { 'desired' => $desired, 'interval' => $interval, 'callback' => $callback };
    $timer->{'id'} = $id if(defined $id);
    return _insert_timer($self, $timer);
}

sub remove_timer_by_id {
    my ($self, $id) = @_;
    my $lastindex = scalar(@{$self->{'timers'}}) - 1;
    for my $i (0 .. $lastindex) {
        next if(! defined $self->{'timers'}[$i]{'id'});
        if($self->{'timers'}[$i]{'id'} == $id) {
            #say "Removing timer with id: $id";
            splice(@{$self->{'timers'}}, $i, 1);
            return;
        }
    }
    say "unable to remove timer $id, not found";
}

sub requeue_timers {
    my ($self, $timers, $current_time) = @_;
    foreach my $timer (@$timers) {
        $timer->{'desired'} = $current_time + $timer->{'interval'};
        _insert_timer($self, $timer);
    }
}

sub check_timers {
    my ($self) = @_;
    my @requeue_timers;
    my $timerhit = 0;
    my $current_time =  clock_gettime(CLOCK_MONOTONIC);
    while(my $timer = shift (@{$self->{'timers'}})  ) {
        if($current_time >= $timer->{'desired'}) {
            $timerhit = 1;
            if(defined $timer->{'callback'}->($timer, $current_time, $self)) { # callback may change interval
                push @requeue_timers, $timer;
            }
        }
        else {
            unshift @{$self->{'timers'}}, $timer;
            last;
        }
    }
    $self->requeue_timers(\@requeue_timers, $current_time);
}

sub do_poll {
    my ($self, $loop_interval, $poll) = @_;
    my $pollret = $poll->poll($loop_interval);
    if($pollret > 0){
        foreach my $handle ($poll->handles()) {
            my $revents = $poll->events($handle);
            my $obj = $self->{'fh_map'}{$handle};
            if($revents & POLLIN) {
                #say "read Ready " .$$;
                if(! defined($obj->onReadReady)) {
                    $self->remove($handle);
                    say "poll has " . scalar ( $self->{'poll'}->handles) . " handles";
                    next;
                }
            }

            if($revents & POLLOUT) {
                #say "writeReady";
                if(! defined($obj->onWriteReady)) {
                    $self->remove($handle);
                        say "poll has " . scalar ( $self->{'poll'}->handles) . " handles";
                    next;
                }
            }

            if($revents & (POLLHUP | POLLRDHUP )) {
                say "Hangup $handle, before ". scalar ( $self->{'poll'}->handles);
                $obj->onHangUp();
                $self->remove($handle);
                say "poll has " . scalar ( $self->{'poll'}->handles) . " handles";
            }
        }

    }
    elsif($pollret == 0) {
        #say "pollret == 0";
    }
    elsif(! $!{EINTR}){
        say "Poll ERROR $!";
        #return undef;
    }

    $self->run_dead_children_callbacks;
}

sub run {
    my ($self, $loop_interval) = @_;
    my $default_lp_interval = $loop_interval // -1;
    my $poll = $self->{'poll'};
    for(;;)
    {
        check_timers($self);
        print "do_poll $$";
        if($self->{'timers'}) {
            say " timers " . scalar(@{$self->{'timers'}}) . ' handles ' . scalar($self->{'poll'}->handles());
        }
        else {
            print "\n";
        }
        # we don't need to expire until a timer is expiring
        if(@{$self->{'timers'}}) {
            $loop_interval = $self->{'timers'}[0]{'desired'} - clock_gettime(CLOCK_MONOTONIC);
        }
        else {
            $loop_interval = $default_lp_interval;
        }
        do_poll($self, $loop_interval, $poll);
    }
}

1;
