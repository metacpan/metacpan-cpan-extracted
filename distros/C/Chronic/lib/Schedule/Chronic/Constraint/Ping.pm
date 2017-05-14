##
## DiskIO constraint
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Ping.pm,v 1.1 2005/04/26 07:18:43 hackworth Exp $
##


package Schedule::Chronic::Constraint::Ping;
use Schedule::Chronic::Base;
use base qw(Schedule::Chronic::Base);


sub new { 
    
    my ($class) = @_;

    return bless { 
        ip           => '4.2.2.1',
        wait         => 5,
    }, $class;

}


sub init { 

    my ($self, $schedule, $task, $logger, $ip) = @_;
    return unless $self; 

    $$self{schedule}     = $schedule        if $schedule;
    $$self{task}         = $task            if $task;
    $$self{active}       = $active          if $active;
    $$self{ip}           = $ip              if $ip;
    $$self{logger}       = $logger;

    return $self;

}


sub met { 

    my ($self) = @_;

    my ($is_up) = $self->state;

    $self->debug("  ping = " . ($is_up ? "OK" : "Unreachable"));

    if ($is_up) { 
        return 1;
    } else { 
        $self->{wait} = 60;
        return 0;
    }

}


sub state { 

    my ($self) = @_;

    # We determine network reachability by pinging the IP
    # address. If the ping fails, we declare network is down.
    # Ideally, we should do this without depending on the
    # external program ``ping''. FIX!

    my $rv = system("ping -q -c 1 $$self{ip} 2>&1 > /dev/null");

    if ($rv == 0) { 
        return 1;
    } 

    return 0;

}


sub wait { 

    return $_[0]->{wait};

}


1;


