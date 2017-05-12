package BalanceOfPower::Player::Role::Cargo;
$BalanceOfPower::Player::Role::Cargo::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils;

has hold => (
    is => 'ro',
    default => sub { {} }
);

sub add_cargo
{
    my $self = shift;
    my $type = shift;
    my $q = shift;
    my $cost = shift;
    my $stat = shift;

    my $present_q = $self->get_cargo($type);
    my $present_cost = $self->get_cargo($type, 'cost');
    my $present_stat = $self->get_cargo($type, 'stat');
    
    my $new_q = $present_q + $q;
    my $new_cost = $q > 0 ? (($present_q * $cost) + ($q * $cost))/($new_q) : $present_cost;
    my $new_stat = $q > 0 ? (($present_q * $stat) + ($q * $stat))/($new_q) : $present_stat;
    
    return -1 if($new_q < 0);
    $self->hold->{$type} = { q => $new_q,
                             cost => $new_cost,
                             stat => $new_stat };
    return 1;
}

sub get_cargo
{
    my $self = shift;
    my $type = shift;
    my $what = shift || 'q';
    if(exists $self->hold->{$type})
    {
        return $self->hold->{$type}->{$what};
    }
    else
    {
        return 0;
    }
}

sub cargo_free_space
{
    my $self = shift;
    my $occupied = 0;
    foreach my $t (%{$self->hold})
    {
        $occupied += $self->hold->{$t}->{'q'};
    }
    if($occupied > CARGO_TOTAL_SPACE)
    {
        say "Load exceed available space";
        return 0;
    }
    else
    {   
        return CARGO_TOTAL_SPACE - $occupied;
    }
}

sub print_cargo
{
    my $self = shift;
    my $mode = shift || 'print';
    my $data = {};
    foreach my $p ( ( 'goods', 'luxury', 'arms', 'tech', 'culture' ) )
    {
        $data->{$p} = $self->get_cargo($p);
    }
    $data->{'free'} = $self->cargo_free_space;
    return BalanceOfPower::Printer::print($mode, $self, 'print_cargo', $data); 
}


1;
