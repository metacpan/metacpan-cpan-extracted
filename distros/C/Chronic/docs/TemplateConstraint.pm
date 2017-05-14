##
## Template constraint
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: TemplateConstraint.pm,v 1.1 2004/06/04 21:57:51 hackworth Exp $
##


package Schedule::Chronic::Constraint::NAME;
use base qw(Schedule::Chronic::Base);
# Include other modules here.


sub new { 
    
    my ($class, $debug) = @_;

    return bless { 

        # ``debug'' is mandatory, get the value from the caller, so higher
        # level logic can turn debugging, on/off.

        'debug'     => $debug,                                 

        # ``wait'' is optional. If you don't modify the wait() method, you
        # can set this parameter and wait() will return it's current value
        # to the caller.

        'wait'      => 0,

        # ``timer'' is an optional timer, a lot of constraints use it. 

        'timer'     => new Schedule::Chronic::Timer ('down'), 

    }, $class;

}


sub init { 

    my ($self, $schedule, $task, @params) = @_; 
    return unless $self; 

    $$self{schedule}     = $schedule        if $schedule;
    $$self{task}         = $task            if $task;

    # Initialize parameters.

    return $self;

}


sub met { 

    my ($self) = @_;

    my $state = $self->state();

    # check if met
    # return 0 if not met
    # return 1 if met

}


sub state { 

    my ($self) = @_;

    # Do the meat of the constraint check here and return a state value.
    # e.g. in case of the LoadAvg constraint, the load average is
    # determined in this routine and returned to met(). state() could be called 
    # by higher level logic, so it should communicate using its return value.

}


sub wait {

    return $_[0]->{wait};

}


sub DESTROY { 

    my $self = shift;

    # If any special destruction needs to be done, do it here.

}


1;

