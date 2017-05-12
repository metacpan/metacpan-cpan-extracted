package BalanceOfPower::Player::Role::Traveler;
$BalanceOfPower::Player::Role::Traveler::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';



has position => (
    is => 'rw',
);

has movements => (
    is => 'rw',
);



sub print_travel_plan
{
    my $self = shift;
    my $world = shift;
    my $mode = shift || 'print';
    my %plan = $world->make_travel_plan($self->position);
    return BalanceOfPower::Printer::print($mode, $self, 'print_travel_plan', 
                                          { plan => \%plan } );
    
}

sub refill_movements
{
    my $self = shift;
    $self->movements(PLAYER_MOVEMENTS);
}
sub go
{
    my $self = shift;
    my $world = shift;
    my $destination = shift;
    my %plan = $world->make_travel_plan($self->position);
    foreach my $way ('air', 'ground')
    {
        if(my $route = $plan{$way}->{$destination})
        {
            if($route->{status} eq 'KO')
            {
                return -1;
            }        
            elsif($route->{cost} > $self->movements)
            {
                return -2;
            }
            $self->movements($self->movements - $route->{cost});
            $self->position($destination);   
            return (1, { destination => $destination, way => $way, cost => $route->{cost} });     
        }
    }
    return -3;
}
1;
