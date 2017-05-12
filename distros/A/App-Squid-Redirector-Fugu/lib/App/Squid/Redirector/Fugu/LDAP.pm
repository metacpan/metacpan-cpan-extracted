use strict;
use warnings;

package App::Squid::Redirector::Fugu::LDAP;

use Net::LDAP;


sub new {
    my $class = shift;
    return bless({}, $class);
}

sub bind {
    my($self, $dn, $password) = @_;
    
    if($dn && $password) {   
        $self->{conn}->bind($dn, password => $password);
    } else {
        # anonymous bind
        $self->{conn}->bind();
    }
}

sub run {
    my($self, $fn, %attrs) = @_;

    my $mesg;

    if($attrs{base} && $attrs{filter}) {
    
        # default scope
        $attrs{scope} = 'subtree' unless($attrs{scope});
        
        # default attr
        $attrs{attr} = 'sAMAccountName' unless($attrs{attr});        
      
        $mesg = $self->{conn}->search(
            base => $attrs{base},
            scope => $attrs{scope},
            filter => $attrs{filter},
            attrs => [$attrs{attr}]
        );
    }
    
    # function will receive mesg as param
    &$fn($mesg);

}

sub set_logger {
    my($self, $logger) = @_;    
    $self->{logger} = $logger;
}

sub set_server {
    my($self, $server) = @_;    
    $self->{conn} = Net::LDAP->new($server) or $self->{logger}->die("Unable to connecto to ldap server $server: $@");    
}

1;
