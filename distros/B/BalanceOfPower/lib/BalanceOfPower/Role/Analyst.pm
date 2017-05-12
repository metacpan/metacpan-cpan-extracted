package BalanceOfPower::Role::Analyst;
$BalanceOfPower::Role::Analyst::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;
use Term::ANSIColor;
use BalanceOfPower::Constants ':all';
use BalanceOfPower::Utils qw( prev_turn as_title as_title as_subtitle compare_turns);
use BalanceOfPower::Printer;

use Data::Dumper;

requires 'diplomacy_exists';
requires 'get_borders';
requires 'supported';
requires 'exists_military_support';
requires 'near_nations';
requires 'routes_for_node';
requires 'get_allies';
requires 'get_crises';
requires 'get_wars';
requires 'print_nation_situation';
requires 'print_nation_statistics_header';
requires 'print_nation_statistics_line';
requires 'get_player';
requires 'print_all_crises';
requires 'get_attackers';

sub print_nation_actual_situation
{
    my $self = shift;
    my $nation = shift;
    my $in_the_middle = shift;
    my $mode = shift || 'print';
    my $attributes_names = ["Size", "Prod.", "Wealth", "W/D", "Growth", "Disor.", "Army", "Prog.", "Pstg."];
    my $attributes = ["production", "wealth", "w/d", "growth", "internal disorder", "army", "progress", "prestige"];

    my $turn;
    if($in_the_middle)
    {
        $turn = prev_turn($self->current_year);
    }
    else
    {
        $turn = $self->current_year;
    }
    my $nation_obj = $self->get_nation($nation);
    my $under_influence = $self->is_under_influence($nation);
    my @influence = $self->has_influence($nation);
    my @ndata = $self->get_nation_statistics_line($nation, $turn, $attributes);
    my @routes = $self->routes_for_node($nation);
    my @treaties = $self->get_treaties_for_nation($nation);
    my @supports = $self->supports($nation);
    my @rebel_supports = $self->rebel_supports($nation);
    my $first_row_height;
    if(@treaties > @supports + @rebel_supports)
    {
        $first_row_height = @treaties;
    }
    else
    {
        $first_row_height = @supports + @rebel_supports;
    }
    my @crises = $self->get_crises($nation);
    my @wars = $self->get_wars($nation);
    my $second_row_height;
    if(@crises > @wars)
    {
        $second_row_height = @crises;
    }
    else
    {
        $second_row_height = @wars;
    }
    my $latest_order = $self->get_statistics_value($turn, $nation, 'order') ? $self->get_statistics_value($turn, $nation, 'order') : 'NONE';
    return BalanceOfPower::Printer::print($mode, $self, 'print_actual_nation_situation', 
                                   { nation => $nation_obj,
                                     under_influence => $under_influence,
                                     influence => \@influence,
                                     attributes => $attributes_names,
                                     nationstats => \@ndata,
                                     traderoutes => \@routes,
                                     treaties => \@treaties,
                                     supports => \@supports,
                                     rebel_supports => \@rebel_supports,
                                     first_row_height => $first_row_height,
                                     crises => \@crises,
                                     wars => \@wars,
                                     second_row_height => $second_row_height,
                                     latest_order => $latest_order,
                                   } );
}

sub print_borders_analysis
{
    my $self = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my @borders = $self->near_nations($nation, 1);
    my %data;

    foreach my $b (@borders)
    {
        my $rel = $self->diplomacy_exists($nation, $b);
        $data{$b}->{'relation'} = $rel;

        my $supps = $self->supported($b);
        if($supps)
        {
            my $supporter = $supps->start($b);
            $data{$b}->{'support'}->{nation} = $supporter;
            my $sup_rel = $self->diplomacy_exists($nation, $supporter);
            $data{$b}->{'support'}->{relation} = $sup_rel;
        }
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_borders_analysis', 
                                   { nation => $nation,
                                     borders => \%data } );

}
sub print_near_analysis
{
    my $self = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my @data = ();
    my @near = $self->near_nations($nation, 0);
    foreach my $b (@near)
    {
        my $rel = $self->diplomacy_exists($nation, $b);
        my $reason = $self->in_military_range($nation, $b);
        push @data, { nation => $b,
                      relation => $rel,
                      how => $reason->{'how'},
                      who => $reason->{'who'} };
    }
    BalanceOfPower::Printer::print($mode, $self, 'print_near_analysis', 
                                           { nation => $nation,
                                             near => \@data } );
}
sub print_hotspots
{
     my $self = shift;
     my $mode = shift || 'print';
     my $out = "";
     $out .= $self->print_all_crises(undef, 1, $mode);
     $out .= $self->print_wars(undef, $mode);
     return $out;
}

sub print_civil_war_report
{
    my $self = shift;
    my $nation = shift;
    if (! $self->at_civil_war($nation))
    {
        return "$nation is not fightinh civil war";
    }
    my $out = "";
    my $nation_obj = $self->get_nation($nation);
    $out .= "Rebel provinces: " . $nation_obj->rebel_provinces . "/" . PRODUCTION_UNITS->[$nation_obj->size] . "\n";
    $out .= "Army: " . $nation_obj->army . "\n";
    my $sup = $self->supported($nation);
    my $rebsup = $self->rebel_supported($nation);
    $out .= "Support: " . $sup->print . "\n" if($sup);
    $out .= "Rebel support: " . $rebsup->print . "\n" if ($rebsup);
    return $out;
}

sub print_war_history
{
    my $self = shift;
    my $mode = shift || 'print';
    my %wars;
    my @war_names;
    foreach my $w (@{$self->memorial})
    {
        if(exists $wars{$w->war_id})
        {
           push @{$wars{$w->war_id}}, $w;
        }
        else
        {
           $wars{$w->war_id} =  [ $w ];
           push @war_names, { name => $w->war_id,
                              start => $w->start_date  };
        }
    }
    sub comp
    {
        compare_turns($a->{start}, $b->{start});
    }
    @war_names = sort comp @war_names;
    return BalanceOfPower::Printer::print($mode, $self, 'print_war_history', 
                                   { wars => \%wars,
                                     war_names => \@war_names } );
}
sub print_civil_war_history
{
    my $self = shift;
    my $mode = shift || 'print';
    my %civil_wars;
    my @civil_war_names;
    foreach my $w (@{$self->civil_memorial})
    {
        my $name = $w->name . " - " . $w->start_date;
        $civil_wars{$name} =  $w;
        push @civil_war_names, { name => $name,
                                 start => $w->start_date  };
    }
    sub civil_comp
    {
        compare_turns($a->{start}, $b->{start});
    }
    @civil_war_names = sort civil_comp @civil_war_names;
    return BalanceOfPower::Printer::print($mode, $self, 'print_civil_war_history', 
                                   { civil_wars => \%civil_wars,
                                     civil_war_names => \@civil_war_names } );
}
sub print_treaties_table
{
    my $self = shift;
    my $out = sprintf "%-20s %-6s %-5s %-5s %-5s", "Nation", "LIMIT", "ALL", "NAG", "COM";
    $out .= "\n";
    my @nations = @{$self->nation_names};
    for(@nations)
    {
        my $n = $_;
        my $limit = $self->get_nation($n)->treaty_limit;
        my $alls = $self->get_treaties_for_nation_by_type($n, 'alliance');
        my $coms = $self->get_treaties_for_nation_by_type($n, 'commercial');
        my $nags = $self->get_treaties_for_nation_by_type($n, 'no aggression');
        $out .= sprintf "%-20s %-6s %-5s %-5s %-5s", $n, $limit, $alls, $nags, $coms;
        $out .= "\n";
    }
    return $out;
}
sub player_stocks_status
{
    my $self = shift;
    my $player = shift;
    my $player_obj = $self->get_player($player);
    my $stock_value = 0;
    my %market_data = ();
    foreach my $nation(keys %{$player_obj->wallet})
    {
        if( $player_obj->stocks($nation) > 0 || $player_obj->influence($nation) > 0)
        {
            $market_data{$nation} = { 'stocks' => $player_obj->wallet->{$nation}->{stocks},
                                      'value'  => $self->get_statistics_value(prev_turn($self->current_year), $nation, "w/d"),
                                      'prev_value' => $self->get_statistics_value(prev_turn(prev_turn($self->current_year)), $nation, "w/d"),
                                      'influence' => $player_obj->wallet->{$nation}->{influence},
                                      'war_bonds' => $player_obj->wallet->{$nation}->{'war_bonds'},
                                    };
            $stock_value += $player_obj->wallet->{$nation}->{stocks} * $self->get_statistics_value(prev_turn($self->current_year), $nation, "w/d");
        }
    }
    my $total_value = $stock_value + $player_obj->money;
    return { market_data => \%market_data,
             stock_value => $stock_value,
             money => $player_obj->money,
             total_value => $total_value,
             points => $player_obj->mission_points };
}


sub print_stocks
{
    my $self = shift;
    my $player = shift;
    my $mode = shift || 'print';
    return BalanceOfPower::Printer::print($mode, $self, 'print_stocks', $self->player_stocks_status($player));
}
sub print_all_stocks
{
    my $self = shift;
    my $mode = shift || 'print';
    my %data = ();
    my @names;
    for(@{$self->players})
    {
        my $p = $_;
        push @names, $p->name;
        $data{$p->name} = $self->player_stocks_status($p->name);
    }
    @names = sort { $data{$b}->{total_value} <=> $data{$a}->{total_value} } @names;

    return BalanceOfPower::Printer::print($mode, $self, 'print_ranking', 
                                            { players_data => \%data,
                                              players => \@names });
}
sub print_market
{
    my $self = shift;
    my $mode = shift || 'print';
    my @ordered = $self->order_statistics(prev_turn($self->current_year), 'w/d');
    my %data = ();
    my @nations = ();
    foreach my $stats (@ordered)
    {
        my $nation = $self->get_nation($stats->{nation});
        push @nations, $stats->{nation};
        my $status = "";
        if($self->at_war($nation->name))
        {
            $status = "WAR";
        }
        elsif($self->at_civil_war($nation->name))
        {
            $status = "CIVILW";
        }
        $data{$nation->name} = {  stocks => $nation->available_stocks,
                                  wd => $stats->{value},
                                  status => $status };
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_market', 
                                          { market_data => \%data,
                                            nations => \@nations } );
}

sub wars_info
{
    my $self = shift;
my %grouped_wars;
    foreach my $w ($self->wars->all())
    {
        if(! exists $grouped_wars{$w->war_id})
        {
            $grouped_wars{$w->war_id} = [];
        }
        push @{$grouped_wars{$w->war_id}}, $w; 
    }
    my @wars;
    foreach my $k (keys %grouped_wars)
    {
        my %war;
        $war{'name'} = $k;
        $war{'conflicts'} = [];
        foreach my $w ( @{$grouped_wars{$k}})
        {
            my %subwar;
            $subwar{'node1'} = $w->node1;
            $subwar{'node2'} = $w->node2;
            my $nation1 = $self->get_nation($w->node1);
            my $nation2 = $self->get_nation($w->node2);
            $subwar{'army1'} = $nation1->army;
            $subwar{'army2'} = $nation2->army;
            $subwar{'node1_faction'} = $w->node1_faction;
            $subwar{'node2_faction'} = $w->node2_faction;
            push @{$war{'conflicts'}}, \%subwar;
        }
        push @wars, \%war;
    }
    return @wars;
}

sub armies_on_territory
{
    my $self = shift;
    my $nation = shift;
    my @conflicts = $self->get_attackers($nation);
    my @attackers = ();
    for(@conflicts)
    {
        push @attackers, $_->node1;
    }
    my $supporter;
    my $supps = $self->supported($nation);
    if($supps)
    {
        $supporter = $supps->start($nation);
    }
    return { invaders => \@attackers,
             supporter => $supporter,
           }  
}

sub print_wars
{
    my $self = shift;
    my $nation = shift;
    my $mode = shift || 'print';
    my @wars = $self->wars_info();
    my @civil_wars;
    foreach my $n (@{$self->nation_names})
    {
        if($self->at_civil_war($n))
        {
            push @civil_wars, $n;
        }
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_wars', 
                                   { wars => \@wars,
                                     civil_wars => \@civil_wars } );
}
1;
