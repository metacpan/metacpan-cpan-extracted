##
## DiskIO constraint
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Concurrent.pm,v 1.1 2005/04/26 07:22:32 hackworth Exp $
##


package Schedule::Chronic::Constraint::Concurrent;
use Schedule::Chronic::Base;
use base qw(Schedule::Chronic::Base);


sub new { 
    
    my ($class) = @_;

    return bless { 
        wait         => 5,
    }, $class;

}


sub init { 

    my ($self, $schedule, $task, $logger, $process, $concurrent) = @_;
    return unless ($self and $process and $concurrent);

    $$self{schedule}     = $schedule        if $schedule;
    $$self{task}         = $task            if $task;
    $$self{active}       = $active          if $active;
    $$self{process}      = $process;
    $$self{concurrent}   = $concurrent;
    $$self{logger}       = $logger;

    return $self;

}


sub met { 

    my ($self) = @_;

    my ($number) = $self->state;

    $self->debug("  concurrent = $number $$self{process} processes");

    if ($number < $$self{concurrent}) {
        return 1;
    } else { 
        $self->{wait} = 10;
        return 0;
    }

}


sub state { 

    my ($self) = @_;

    my @number = `ps -C $$self{process}`;

    # Sample output: 
    # vipul@precog Constraint $ ps -C mutt
    #   PID TTY          TIME CMD
    #  6468 pts/1    00:00:00 mutt
    #  6470 pts/1    00:00:00 mutt
    #  9000 pts/1    00:00:00 mutt

    return (scalar @number - 1);

}


sub wait { 

    return $_[0]->{wait};

}


1;


