package BalanceOfPower::Role::GameMaster;
$BalanceOfPower::Role::GameMaster::VERSION = '0.400115';
use strict;
use v5.10;

use Moo::Role;
use List::Util qw(shuffle);

use BalanceOfPower::Player;
use BalanceOfPower::Targets::Fall;

use BalanceOfPower::Constants ':all';

has players => (
    is => 'rw',
    default => sub { [] }
);

sub get_player
{
    my $self = shift;
    my $name = shift;
    my @good = grep { $_->name eq $name} @{$self->players};
    if(@good)
    {
        return $good[0];
    }
    else
    {
        return undef;
    }
}
sub create_player
{
    my $self = shift;
    my $username = shift;
    my $position = shift;
    my $money = shift || START_PLAYER_MONEY;
    my $already = $self->get_player($username);
    if($already)
    {
        $already->position($position) if $position;
        $already->money($money) if $money;
        return 0;
    }
    if(! $position)
    {
        my @nations = @{$self->nation_names};
        @nations = shuffle @nations;
        $position = $nations[0];
    }
    my $log_name = $username . ".log";
    $log_name =~ s/ /_/g;
    my $pl = BalanceOfPower::Player->new(name => $username, money => $money, log_name => $log_name, log_dir => $self->log_dir, current_year => $self->current_year, position => $position);
    $pl->delete_log();
    $pl->register_event("ENTERING THE GAME");
    $self->register_event("$username IS ENTERING THE GAME");
    $self->add_player($pl);
    return 1;
}


sub add_player
{
    my $self = shift;
    my $player = shift;
    if($self->get_player($player->name))
    {
        return 0;
    }
    else
    {
        push @{$self->players}, $player;
        return 1;
    }
}
sub delete_player
{
    my $self = shift;
    my $player = shift;
    my @players = grep { $_->name ne $player} @{$self->players};
    $self->players(\@players);
}
sub player_start_turn
{
    my $self = shift;
    for(@{$self->players})
    {
        $_->current_year($self->current_year);
        $_->refill_movements();
    }
}

sub player_targets
{
    my $self = shift;
    for(@{$self->players})
    {
        my $p = $_;
        if($p->no_targets)
        {
            my $obj = BalanceOfPower::Targets::Fall->select_random_target($self);
            if($obj)
            {
                my $target = BalanceOfPower::Targets::Fall->new(target_obj => $obj, 
                                                                government_id => $obj->government_id, 
                                                                countdown => TIME_FOR_TARGET);
                $p->add_target($target);
            }
        }
        else
        {
            $p->check_targets($self);
            $p->click_targets();
        }
    }
}
sub print_targets
{
    my $self = shift;
    my $player = shift;
    my $mode = shift || 'print';
    my $player_obj = $self->get_player($player);
    return BalanceOfPower::Printer::print($mode, $self, 'print_targets', 
                                   { player => $player,
                                     points => $player_obj->mission_points,
                                     targets => $player_obj->targets,
                                   } );
}

1;
