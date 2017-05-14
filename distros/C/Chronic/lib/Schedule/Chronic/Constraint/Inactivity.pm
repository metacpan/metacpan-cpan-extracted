##
## Detect System Inactivity
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Inactivity.pm,v 1.3 2004/07/15 21:11:08 hackworth Exp $
##

package Schedule::Chronic::Constraint::Inactivity;
use Schedule::Chronic::Base;
use Schedule::Chronic::Constraint::Loadavg;
use Schedule::Chronic::Constraint::DiskIO;
use base qw(Schedule::Chronic::Base);


sub new { 

    my ($class) = @_;

    return bless {

        loadavg => new Schedule::Chronic::Constraint::Loadavg ($debug),
        diskio  => new Schedule::Chronic::Constraint::DiskIO  ($debug),

        # This class doesn't have its own timer. Timers are maintained by
        # DiskIO and Loadavg.

    }, shift 

}


sub init { 

    my ($self, $schedule, $task, $logger, $active) = @_;
    return unless ref $self;
   
    $$self{loadavg}->init($schedule, $task, $logger, $active);
    $$self{diskio}->init($schedule, $task, $logger, $active);
    $$self{logger} = $logger;

    return $self;

}


sub met { 

    my ($self) = @_;

    if ($self->{loadavg}->met() && $self->{diskio}->met()) { 
        return 1;
    } else { 
        return 0;
    }

}


sub state { 

    # This is a "Container Constraint" that doesn't have a state of its
    # own, so we return undef. This is an indication to the poller that
    # the constraint doesn't have a state.

    return;

}


sub wait { 

    my $self = shift;
    my $loadavg_wait = $self->{loadavg}->wait();
    my $diskio_wait  = $self->{diskio}->wait();

    return $loadavg_wait > $diskio_wait ? $loadavg_wait : $diskio_wait;

}


1;

