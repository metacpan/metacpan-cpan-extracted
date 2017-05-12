package Bot::Jabbot::Module::Replier;
use base qw(Bot::Jabbot::Module);
use warnings;
use strict;

use AnyEvent;

sub init
{
    my ($self, $cl, $jid) = @_;
    $self->{timer} = AnyEvent->timer (after => 5, interval => 10, cb => sub {
        $self->timer($cl,$jid);
     });
    return 0;
}

sub timer
{
    #do something good
}

sub message {
    my ($self,$msg,$bot) = @_;
    return unless defined $msg->any_body;
    return $self->loc("wtf?");
}

sub muc {
    my ($self,$msg,$mynick,$bot) = @_;
    return unless defined $msg->any_body;
    return $self->loc("wtf?");
}
1;