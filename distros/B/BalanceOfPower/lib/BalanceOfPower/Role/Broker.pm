package BalanceOfPower::Role::Broker;
$BalanceOfPower::Role::Broker::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn );

requires 'get_player';
requires 'get_nation';
requires 'get_statistics_value';

sub manage_stock
{
    my $self = shift;
    my $command = shift;
    my $player = shift;
    my $nation = shift;
    my $q = shift;
    if($command eq 'buy')
    {
        return $self->buy_stock($player, $nation, $q);
    }
    elsif($command eq 'sell')
    {
        return $self->sell_stock($player, $nation, $q);
    }
}

sub buy_stock
{
    my $self = shift;
    my $player = shift;
    my $nation = shift;
    my $q = shift;
    my $dry_run = shift || 0;
    my $player_obj = $self->get_player($player);
    my $nation_obj = $self->get_nation($nation);
    if($nation_obj->available_stocks < $q)
    {
        $player_obj->register_event("STOCKS IN QUANTITY $q FOR $nation NOT AVAILABLE")
            if(! $dry_run);
        return { status => -11 };
    }
    if($q > MAX_BUY_STOCK)
    {
        return { status => -15 };
    }
    if($self->at_civil_war($nation))
    {
        $player_obj->register_event("NO STOCK TRANSATION WITH $nation. $nation IS IN CIVIL WAR")
            if(! $dry_run);
        return { status => -14 };
    }
    return { status => 1,
             command => "buy $q $nation" } if $dry_run;
    my $unit_cost = $self->get_statistics_value(prev_turn($self->current_year), $nation, 'w/d');
    my $global_cost = $unit_cost * $q;
    my $influence = $q * STOCK_INFLUENCE_FACTOR;
    if($player_obj->money < $global_cost)
    {
        $player_obj->register_event("NOT ENOUGH MONEY TO BUY STOCKS OF $nation FOR $global_cost")
            if(! $dry_run);
        return { status => -12 };
    }
    $player_obj->add_money(-1 * $global_cost);
    $player_obj->add_stocks($q, $nation);
    $player_obj->add_influence($influence, $nation);
    $nation_obj->get_stocks($q);

    $player_obj->register_event("BOUGHT $q STOCKS OF $nation. COST: $global_cost ($unit_cost)");
    return { status => 1 };
}
sub sell_stock
{
    my $self = shift;
    my $player = shift;
    my $nation = shift;
    my $q = shift;
    my $dry_run = shift || 0;
    my $player_obj = $self->get_player($player);
    my $nation_obj = $self->get_nation($nation);
    if($player_obj->stocks($nation) < $q)
    {
        $player_obj->register_event("THERE AREN'T $q STOCKS OF $nation TO SELL")
            if(! $dry_run);
        return { status => -13 };
    }
    if($self->at_civil_war($nation))
    {
        $player_obj->register_event("NO STOCK TRANSATION WITH $nation. $nation IS IN CIVIL WAR")
            if(! $dry_run);
        return { status => -14 };
    }
    return { status => 1,
             command => "sell $q $nation" } if $dry_run;
    my $unit_cost = $self->get_statistics_value(prev_turn($self->current_year), $nation, 'w/d');
    my $global_cost = $unit_cost * $q;
    $player_obj->add_money($global_cost);
    $player_obj->add_stocks(-1 * $q, $nation);
    $nation_obj->get_stocks(-1 * $q);
    $player_obj->register_event("SOLD $q STOCKS OF $nation. COST: $global_cost ($unit_cost)");
    return { status => 1 };
}
sub issue_war_bonds
{
    my $self = shift;
    my $n = shift;
    for(@{$self->players})
    {
        $_->issue_war_bonds($n);
    }
}
sub discard_war_bonds
{
    my $self = shift;
    my $nation = shift;
    for(@{$self->players})
    {
        $_->discard_war_bonds($nation);
    }
}
sub empty_stocks
{
    my $self = shift;
    my $nation = shift;
    for(@{$self->players})
    {
        $_->empty_stocks($nation);
    }
}
sub cash_war_bonds
{
    my $self = shift;
    my $nation = shift;
    for(@{$self->players})
    {
        $_->cash_war_bonds($nation);
    }
}
sub execute_stock_orders
{
    my $self = shift;
    my $dry_run = shift || 0;
    my %orders;
    my @acting_players;
    foreach my $player (@{$self->players})
    {
        my @p_orders = @{$player->stock_orders};
        if(@p_orders)
        {  
            say "Player " . $player->name . " has stock orders" if($dry_run);
            $orders{$player->name} = \@p_orders;
            push @acting_players, $player->name;
        }
        $player->empty_stock_orders();
    }
    say "===" if($dry_run);
    while(@acting_players)
    {
        @acting_players = $self->shuffle("Choosing player to execute stock action", @acting_players);
        my $chosen_player = $acting_players[0];
        say "Chosen player is $chosen_player" if($dry_run);
        my $order = shift @{$orders{$chosen_player}};
        say "Order is $order" if($dry_run);
        $order =~ /^(.*)\s(\d)\s(.*)$/;
        my $command = $1;
        my $q = $2;
        my $nation = $3;
        $self->manage_stock($command, $chosen_player, $nation, $q) if (! $dry_run);
        if(! @{$orders{$chosen_player}})
        {
            @acting_players = grep { $_ ne $chosen_player } @acting_players;
        }
        say "---" if($dry_run);
    }
}
sub print_stock_events
{
    my $self = shift;
    my $player = shift;
    my $player_obj = $self->get_player($player);
    my $y = shift;
    my $title = shift;
    my $backlog = shift;
    my $mode = shift;
    return $player_obj->print_turn_events($y, $title, $backlog, $mode);
}

1;
