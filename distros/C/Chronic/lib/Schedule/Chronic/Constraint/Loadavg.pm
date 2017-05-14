##
## Load Average Constraint
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Loadavg.pm,v 1.6 2004/08/15 21:03:35 hackworth Exp $
##

package Schedule::Chronic::Constraint::Loadavg;
use Schedule::Chronic::Base;
use Schedule::Chronic::Timer;
use base qw(Schedule::Chronic::Base);


sub new { 
    
    my ($class) = @_;

    return bless { 
        active       => 60,
        load_avg     => 0.00,
        timer        => new Schedule::Chronic::Timer ('down'),
    }, $class;

}


sub init { 

    my ($self, $schedule, $task, $logger, $active, $load_avg) = @_;
    return unless ref $self;
   
    $$self{schedule}  = $schedule; 
    $$self{task}      = $task;
    $$self{active}    = $active     if $active;
    $$self{load_avg}  = $load_avg   if $load_avg;
    $$self{logger}    = $logger;

    return $self;

}


sub met { 

    my ($self) = @_;

    my $load_avg = $self->state();

    $self->debug("  load average = $load_avg ($$self{load_avg})");

    if ($load_avg <= $$self{load_avg}) { 

        $$self{timer}->set($$self{active}) unless 
            $$self{timer}->running();

        if ($$self{timer}->get() <= 0) { 
            return 1;
        } else { 
            return 0;
        }

    }  

    $$self{timer}->stop();

    # Compute wait as a factor of the current load_avg and the required
    # load_avg. The wait should be bound between 5 and 120 seconds.
    # There ought to be a better algorithm to derive the wait... FIX.

    my $divisor = $$self{load_avg} == 0 ? 0.01 : $$self{load_avg};
    my $wait = int($load_avg/$divisor);
    $wait = 5 if $wait < 5;
    $wait = 120 if $wait > 120;

    $$self{wait} = $wait;

    return 0;

}


sub state { 

    my ($self) = @_;
    open LOADAVG, "/proc/loadavg" or die $!;
    my $load_avg = <LOADAVG>;
    close LOADAVG;
    
    my @undef;
    ($load_avg, @undef) = split /\s/, $load_avg;
    return $load_avg;

}


sub wait { 

    return $_[0]->{wait} || 0;
}


1;

