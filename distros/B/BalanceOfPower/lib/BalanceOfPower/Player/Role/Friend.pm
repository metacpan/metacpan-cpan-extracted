package BalanceOfPower::Player::Role::Friend;
$BalanceOfPower::Player::Role::Friend::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';

has friendship => (
    is => 'ro',
    default => sub { {} },
);

sub get_friendship
{
    my $self = shift;
    my $nation = shift;
    if(exists $self->friendship->{$nation})
    {
        return 50 + $self->friendship->{$nation};
    }
    else
    {
        return 50;
    }
}

sub add_friendship
{
    my $self = shift;
    my $nation = shift;
    my $value = shift;
    if(exists $self->friendship->{$nation})
    {
        $self->friendship->{$nation} = $self->friendship->{$nation} + $value;
        $self->friendship->{$nation} = 50 if $self->friendship->{$nation} > 50;
        $self->friendship->{$nation} = -50 if $self->friendship->{$nation} < -50;
        delete $self->friendship->{$nation} if $self->friendship->{$nation} == 0;
    }
    else
    {
        $self->friendship->{$nation} = $value;
    }   
    return $self->get_friendship($nation);
}
sub print_friendship
{
    my $self = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    if(! $nation)
    {
        my $data = { player => $self->name,
                     friendship => $self->friendship,
                     others => 1 };
        return BalanceOfPower::Printer::print($mode, $self, 'print_player_friendship', $data); 
    }
    else
    {
        my $data = { player => $self->name,
                     friendship => { $nation => $self->get_friendship($nation) },
                     others => 0 };
        return BalanceOfPower::Printer::print($mode, $self, 'print_player_friendship', $data); 
    }

}

1;
