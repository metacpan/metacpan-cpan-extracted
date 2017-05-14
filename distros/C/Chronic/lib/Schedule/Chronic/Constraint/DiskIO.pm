##
## DiskIO constraint
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: DiskIO.pm,v 1.6 2004/08/15 21:01:48 hackworth Exp $
##


package Schedule::Chronic::Constraint::DiskIO;
use Schedule::Chronic::Base;
use Schedule::Chronic::Timer;
use base qw(Schedule::Chronic::Base);


sub new { 
    
    my ($class) = @_;

    return bless { 
        bi_threshold => 5,
        bo_threshold => 5,
        active       => 10,
        timer        => new Schedule::Chronic::Timer ('down'),
    }, $class;

}


sub init { 

    my ($self, $schedule, $task, $logger, $active, $bi_threshold, $bo_threshold) = @_;
    return unless $self; 

    $$self{schedule}     = $schedule        if $schedule;
    $$self{task}         = $task            if $task;
    $$self{active}       = $active          if $active;
    $$self{bi_threshold} = $bi_threshold    if $bi_threshold;
    $$self{bo_threshold} = $bo_threshold    if $bo_threshold;
    $$self{logger}       = $logger;

    return $self;

}


sub met { 

    my ($self) = @_;

    my ($bi, $bo) = $self->state();

    $self->debug("DiskIO: buffers in = $bi ($$self{bi_threshold}), " .
       "buffers out = $bo ($$self{bo_threshold}), timer = " . $$self{timer}->get());

    if ($bo <= $$self{bo_threshold} and $bi <= $$self{bi_threshold} ) { 

        $$self{timer}->set($$self{active}) unless 
            $$self{timer}->running();

        if ($$self{timer}->get() <= 0) { 
            return 1;
        } else { 
            return 0;
        }

    } 

    $$self{timer}->stop();
    return 0;

}


sub state { 

    my ($self) = @_;

    # Should we use the proc file system (/proc/stat) to gather
    # this information? Doesn't seem like a good idea to depend
    # on existence of vmstat. On the other hand for OSes that
    # don't have a proc filesystem, vmstat might be more
    # dependable. This requires more research.

    my @vmstat = `vmstat 1 2`;

    my $io = $vmstat[3];
       $io =~ s/^\s+//;
    my @stats = split /\s+/, $io;

    return ($stats[8], $stats[9]);

}


sub wait { 

    return 0;

}


1;


