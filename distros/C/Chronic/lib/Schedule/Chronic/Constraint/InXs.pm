##
## Detect System Inactivity or Xscreensaved Locking
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: InXs.pm,v 1.2 2004/07/15 21:11:07 hackworth Exp $
##

package Schedule::Chronic::Constraint::InXs;
use Schedule::Chronic::Base;
use Schedule::Chronic::Constraint::Inactivity;
use Schedule::Chronic::Constraint::Xscreensaver;
use base qw(Schedule::Chronic::Base);


sub new { 

    my ($class) = @_;

    return bless {

        inactivity   => new Schedule::Chronic::Constraint::Inactivity   ($debug),
        xscreensaver => new Schedule::Chronic::Constraint::Xscreensaver ($debug),

    }, shift 

}


sub init { 

    my ($self, $schedule, $task, $logger, $active) = @_;
    return unless ref $self;
   
    $$self{inactivity}->init($schedule, $task, $logger, $active);
    $$self{xscreensaver}->init($schedule, $task, $logger, $active);
    $$self{logger} = $logger;

    return $self;

}


sub met { 

    my ($self) = @_;

    if ($self->{xscreensaver}->met() || $self->{inactivity}->met()) { 
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
    my $xs_wait = $self->{xscreensaver}->wait();
    my $in_wait = $self->{inactivity}->wait();

    return $xs_wait > $in_wait ? $xs_wait : $in_wait;

}


1;

