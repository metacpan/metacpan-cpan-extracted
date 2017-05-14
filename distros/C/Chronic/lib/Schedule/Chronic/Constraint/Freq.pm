##
## Load Average Constraint
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Freq.pm,v 1.6 2005/04/26 07:31:08 hackworth Exp $
##

package Schedule::Chronic::Constraint::Freq;
use Schedule::Chronic::Base;
use base qw(Schedule::Chronic::Base);

# NOTE: This module overloads the concept of wait to store the number of
#       seconds left before execution. Don't let this confuse you,
#       specially if you are looking at this as a an example for your
#       constraint module.


sub new {
    return bless {}, shift;
}


sub init { 

    my ($self, $schedule, $task, $logger, $seconds) = @_;

    # @args can be: 
    # 86400
    # 86400, Force
    # Force is not implemented

    $$self{schedule}  = $schedule; 
    $$self{task}      = $task;
    $$self{logger}    = $logger;

    $$self{seconds}   = $seconds;
    $$self{wait}      = 0;

    return $self;

}


sub met { 

    my ($self) = @_;

    return 1 if $$self{task}{last_ran} == 0;
    $$self{wait} = $$self{task}{last_ran} - (time() - $$self{seconds});
    $self->debug("  freq wait = $$self{wait} seconds");
    return 1 if ($$self{wait} < 0);
    return 0;
    
}


sub wait { 

    return $_[0]->{wait};
}


1;

