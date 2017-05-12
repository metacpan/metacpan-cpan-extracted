package BalanceOfPower::Role::Shopper;
$BalanceOfPower::Role::Shopper::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn );
use BalanceOfPower::Printer;

use Data::Dumper;

requires 'order_statistics';
requires 'get_statistics_value';


my @products = ( 'goods', 'luxury', 'arms', 'tech', 'culture' );
my %dependencies = ( 'goods' => 'p/d',
                     'luxury' => 'w/d', 
                     'arms' => 'army',
                     'tech' => 'progress',
                     'culture' => 'prestige' );

sub get_stat_for_price
{
    my $self = shift;
    my $y = shift;
    my $type = shift;
    my $nation = shift; #Max value if null
    my $turn = $type eq 'goods' || $type eq 'prestige' ? $y : prev_turn($y);
    if(! $nation)
    {
        my @stat_values = $self->order_statistics($turn, $dependencies{$type});
        if(@stat_values == 0)
        {
            return 0;
        }
        else
        {
            return $stat_values[0]->{'value'};
        }
    }
    else
    {
        return $self->get_statistics_value($turn, $nation, $dependencies{$type});
    }
}

sub calculate_price
{
    my $self = shift;
    my $y = shift;
    my $type = shift;
    my $nation = shift;

    #Price formula is MaxPrice - (( MaxPrice - MinPrice) / MaxValue) * Value
    #MaxPrice and MinPrice are constant

    my $min_price = PRICE_RANGES->{$type}->[0];
    my $max_price = PRICE_RANGES->{$type}->[1];

    my $max_value = $self->get_stat_for_price($y, $type);
    return SHOP_PRICE_FACTOR if($max_value == 0);

    my $value =  $self->get_stat_for_price($y, $type, $nation);

    return int(((($max_price - (($max_price - $min_price) / $max_value) * $value))* SHOP_PRICE_FACTOR)*100)/100;
}
    
sub get_all_nation_prices
{
    my $self = shift;
    my $nation = shift;
    my $year = shift;
    my %data = ();
    foreach my $p (@products)
    {
        my $price = $self->calculate_price($year, $p, $nation);
        my $stat = $self->get_stat_for_price($year, $p, $nation);
        $data{$p} = { price => $price, stat => $stat };
    }
    return %data;
}

sub print_nation_shop_prices
{
    my $self = shift;
    my $y = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my %data = $self->get_all_nation_prices($nation, $y);
    $data{nation} = $nation;
    return BalanceOfPower::Printer::print($mode, $self, 'print_shop_prices', \%data); 
}

sub print_all_nations_prices
{
    my $self = shift;
    my $y = shift;
    my $mode = shift || 'print';
    my @nations = @{$self->nation_names};
    my %data = ();
    foreach my $n (@nations)
    {
        my %prices = $self->get_all_nation_prices($n, $y); 
        $data{$n} = \%prices;
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_all_shop_prices', 
                                                { prices => \%data,
                                                  names => \@nations }); 
}



sub do_transaction
{
    my $self = shift;
    my $player = shift;
    my $action = shift;
    my $q = shift;
    my $what = shift;
    my $flags = shift;
    if(! grep {$_ eq $what} @products)
    {
        return -10;
    }
    if($player->get_friendship($player->position) < FRIENDSHIP_LIMIT_TO_SHOP)
    {
        return -14;
    }
    my $price = $self->calculate_price($self->current_year, $what, $player->position);
    my $stat = $self->get_stat_for_price($self->current_year, $what, $player->position);
    my $cost = $price * $q;
    if($action eq 'buy')
    {   
        if($cost > $player->money)
        {
            return -11;
        }
        if($q > $player->cargo_free_space)
        {
            return -12;
        }
        $player->add_money(-1 * $cost);
        $player->add_cargo($what, $q, $cost, $stat);
    }
    elsif($action eq 'sell')
    {
        my $have = $player->get_cargo($what);
        if($have < $q)
        {
            return -13;
        }
        if(exists $flags->{'bm'})
        {
            $cost = $cost + (BLACK_MARKET_PERCENT_SELLING_BONUS * $cost) / 100;
            $player->add_money($cost);
            $player->add_cargo($what, -1 * $q, $cost, $stat);
            $player->add_friendship($player->position, BLACK_MARKET_FRIENDSHIP_MALUS);
        }
        else
        {
            $player->add_money($cost);
            $player->add_cargo($what, -1 * $q, $cost, $stat);
        }
    }
    return (1, $cost);
}

