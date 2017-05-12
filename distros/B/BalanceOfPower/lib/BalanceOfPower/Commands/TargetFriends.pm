package BalanceOfPower::Commands::TargetFriends;
$BalanceOfPower::Commands::TargetFriends::VERSION = '0.400115';
use Moo;

extends 'BalanceOfPower::Commands::TargetNation';

sub get_available_targets
{
    my $self = shift;
    return $self->world->get_friends($self->actor);    
}

1;
