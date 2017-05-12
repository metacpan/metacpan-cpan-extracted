package BalanceOfPower::Commands::TargetRoute;
$BalanceOfPower::Commands::TargetRoute::VERSION = '0.400115';
use Moo;
use Data::Dumper;

extends 'BalanceOfPower::Commands::TargetNation';

sub select_message
{
    my $self = shift;
    my $message = "";
    foreach my $tr ($self->world->routes_for_node($self->actor))
    {
        $message .= $tr->print($self->actor) . "\n";
    }
    $message .= "\n";
    $message .= "Select traderoute:\n";
    return $message;
}

sub get_available_targets
{
    my $self = shift;
    return $self->world->route_destinations_for_node($self->actor);    
}



1;

