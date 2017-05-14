##
## Timer Class for Chronic Scheduler
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Timer.pm,v 1.2 2004/08/15 21:02:36 hackworth Exp $

package Schedule::Chronic::Timer; 

sub new { 

    my ($class, $direction) = @_;

    my $self = bless { 
        value       => 0, 
        starttime   => time(),
        direction   => $direction,
        running     => 0,
    }, $class;

    return $self;

}


sub set { 

    $_[0]->{value} = $_[1];
    $_[0]->{starttime} = time();
    $_[0]->start();

}



sub start { 

    $_[0]->{running} = 1;

}


sub stop { 

    $_[0]->{running} = 0;

}


sub running { 

    $_[0]->{running};

}


sub get { 

    my $self = shift;
    my $ticks = 0;

    if ($self->{running}) {  
        if ($self->{direction} eq 'up') { 
            $ticks = $self->{value} - (time() - $self->{starttime});
        } else { 
            $ticks = ($self->{value} + $self->{starttime}) - time();
        } 
    } else { 
        return $self->{value};
    }

     return $ticks;

}


1;

