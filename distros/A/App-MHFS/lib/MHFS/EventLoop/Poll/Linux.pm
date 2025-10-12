package MHFS::EventLoop::Poll::Linux v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use parent 'MHFS::EventLoop::Poll::Base';
use MHFS::EventLoop::Poll::Linux::Timer;
sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{'evp_timer'} = MHFS::EventLoop::Poll::Linux::Timer->new($self);
    return $self;
};

sub add_timer {
    my ($self, $start) = @_;
    shift @_;
    if($self->SUPER::add_timer(@_) == 0) {
        say __PACKAGE__.": add_timer, updating linux timer to $start";
        $self->{'evp_timer'}->settime_linux($start, 0);
    }
};

sub requeue_timers {
    my $self = shift @_;
    $self->SUPER::requeue_timers(@_);
    my ($timers, $current_time) = @_;
    if(@{$self->{'timers'}}) {
        my $start = $self->{'timers'}[0]{'desired'} - $current_time;
        say __PACKAGE__.": requeue_timers, updating linux timer to $start";
        $self->{'evp_timer'}->settime_linux($start, 0);
    }
};

sub run {
    my ($self, $loop_interval) = @_;
    $loop_interval //= -1;
    my $poll = $self->{'poll'};
    for(;;)
    {
        print __PACKAGE__.": do_poll LINUX_X86_64 $$";
        if($self->{'timers'}) {
            say " timers " . scalar(@{$self->{'timers'}}) . ' handles ' . scalar($self->{'poll'}->handles());
        }
        else {
            print "\n";
        }

        $self->SUPER::do_poll($loop_interval, $poll);
    }
};

1;