##
## Xscreensaver constraint
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Xscreensaver.pm,v 1.5 2004/08/15 21:10:03 hackworth Exp $
##


package Schedule::Chronic::Constraint::Xscreensaver;
use Schedule::Chronic::Base;
use Schedule::Chronic::Timer;
use IO::File;
use IO::Poll;
use Data::Dumper;
use base qw(Schedule::Chronic::Base);


sub new { 
    
    my ($class) = @_;

    return bless { 
        active       => 10,
        wait         => 5,
        timer        => new Schedule::Chronic::Timer ('down'),
    }, $class;

}


sub init { 

    my ($self, $schedule, $task, $logger, $active) = @_;
    return unless $self; 

    $$self{schedule}     = $schedule        if $schedule;
    $$self{task}         = $task            if $task;
    $$self{active}       = $active          if $active;
    $$self{logger}       = $logger;

    my $xscrn = $self->which("xscreensaver-command");
    return unless $xscrn;

    $$self{watch} = new IO::File;
    $$self{pid}   = $$self{watch}->open("$xscrn -watch |");

    $$self{watch}->blocking(0);
    $$self{poll}  = new IO::Poll;
    $$self{poll}->mask($$self{watch} => POLLIN);

    return $self;

}


sub met { 

    my ($self) = @_;

    my $state = $self->state();

    # $state values: 
    # 0 means no change
    # 1 means toggled to locked
    # 2 means toggled to unlocked

    my @states = ('NO CHANGE', 'LOCKED', 'UNLOCKED');

    $self->debug("  xscreensaver state = $states[$state]");

    if ($$self{timer}->running() and $state == 0) { 
        
        # We are still in locked mode.

        if ($$self{timer}->get() <= 0) { 
            return 1;
        } else { 
            $$self{wait} = $$self{timer}->get();
            $self->debug("  xscreensaver locked, " . $$self{timer}->get() . " seconds remain.");
            return 0;
        }

    }

    if ($$self{timer}->running() and $state == 2) { 

        # In unlocked mode.

        $$self{wait} = 5;
        $$self{timer}->stop();
        return 0;

    } 


    if (!$$self{timer}->running() and $state == 1) { 

        # Toggled into locked mode.

        $$self{timer}->set($$self{active});
        $$self{wait} = 0;
        return 0;

    }

    return 0;

}


sub state { 

    my ($self) = @_;

    my $ready   = $$self{poll}->poll(0.005);
    return 0 unless $ready;

    my @readers = $$self{poll}->handles(POLLIN);
    
    my $watch = $readers[0];
    my $state;
    return 0 unless $watch;
    sysread($watch, $state, 256);

    # If we lock and unlock rapidly, we can get both LOCK and
    # UNBLANK notifications in one read. Due to this we look
    # negative look-ahead assertions to ensure LOCK is not
    # followed by UNBLABK and vice versa.

    my $state_i = 0;

    if ($state =~ m/LOCK.*?(?!UNBLANK)/s) {
        $state_i = 1;
    } 

    if ($state =~ m/UNBLANK.*?(?!LOCK)/s) { 
        $state_i = 2;
    }

    return $state_i;

}


sub wait {

    return $_[0]->{wait};

}


sub DESTROY { 

    my $self = shift;

    # We must cleanup by killing off the xscreensaver-command
    # process. Since the process only writes to STDOUT when a
    # state change happens, closing the pipe will not result in
    # a SIGPIPE till the next state change occurs, and
    # concequently our process will wait() on the child process
    # to terminate. We are going to send a SIGTERM to the
    # process manually when we are ready to shutdown.

    kill(9, $$self{pid});
    $$self{watch}->close() if $$self{watch};

}


1;

