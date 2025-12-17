#!/usr/bin/perl

package BACnet::Subscription;

use warnings;
use strict;

use threads;
use threads::shared;



sub new
{
    my ($class, %args) = @_;

    my $lifetime;

    if (!defined $args{lifetime_in})
    {
        my $err = "udefined arg\n";
        return (undef, $err);
    }

    if ($args{lifetime_in} == 0)# infinit sub
    {
        $lifetime = 0;
    } else
    {
        $lifetime = $args{lifetime_in} + time();
    }

    my $self = {
        obj_type => $args{obj_type},
        obj_inst => $args{obj_inst},
        issue_confirmed_notifications => $args{issue_confirmed_notifications},
        lifetime => $lifetime, #time of death in unix standard time
        host_ip => $args{host_ip},
        peer_port => $args{peer_port},
        on_COV => $args{on_COV}
    };


    return bless $self, $class; 
}

1;
