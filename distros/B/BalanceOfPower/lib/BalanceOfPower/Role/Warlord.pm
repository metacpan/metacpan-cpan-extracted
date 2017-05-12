package BalanceOfPower::Role::Warlord;
$BalanceOfPower::Role::Warlord::VERSION = '0.400115';
use strict;
use v5.10;

use Moo::Role;

use Term::ANSIColor;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Printer;
use BalanceOfPower::Relations::Crisis;
use BalanceOfPower::Relations::War;

requires 'empire';
requires 'border_exists';
requires 'get_nation';
requires 'get_hates';
requires 'occupy';
requires 'broadcast_event';
requires 'send_event';
requires 'get_group_borders';
requires 'get_allies';
requires 'supported';
requires 'supporter';
requires 'military_support_garbage_collector';
requires 'random';
requires 'change_diplomacy';
requires 'get_crises';
requires 'delete_crisis';
requires 'discard_war_bonds';
requires 'cash_war_bonds';
requires 'war_busy';

has wars => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { at_war => 'first_link_for_node',
                 add_war => 'add_link',
                 get_wars => 'links_for_node',
                 war_exists => 'exists_link',
                 delete_war_link => 'delete_link',
                 get_attackers => 'links_for_node2'
               }
);

has memorial => (
    is => 'rw',
    default => sub { [] }
);





sub in_military_range
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $hostile = shift || 1;
    if($self->border_exists($nation1, $nation2))
    {
        return { how => 'border', who => undef };
    }
    my @supported = $self->supporter($nation1);
    for(@supported)
    {
        my $nation_supported = $_->destination($nation1);
        my $treaty = $self->exists_treaty_by_type($nation_supported, $nation2, 'no aggression');
        if(! $hostile || ! $treaty)
        {
            if(! $self->war_busy($nation_supported))
            {
                if($nation_supported eq $nation2)
                {
                    return { how => 'supporting', who => undef};
                }
                if($self->border_exists($nation_supported, $nation2))
                {
                    return { how => 'support', who => $nation_supported};
                }
            }
            else
            {
            }
        }
    }
    my @empire = $self->empire($nation1);
    for(@empire)
    {
        my $ally = $_;
        if(! $self->war_busy($ally))
        {
                return { how => 'linked', who => undef } if $ally eq $nation2;
                return { how => 'control', who => $ally } if $self->border_exists($ally, $nation2);
        }
    }
    return 0;
}

sub war_current_year
{
    my $self = shift;
    for($self->wars->all)
    {
        $_->current_year($self->current_year);
    }
}

sub create_war
{
    my $self = shift;
    my $attacker = shift || "";
    my $defender = shift || "";

    if(! $self->war_exists($attacker->name, $defender->name))
    {
        $self->broadcast_event({ code => 'crisisescalate', 
                                 text => "CRISIS BETWEEN " . $attacker->name . " AND " . $defender->name . " BECAME WAR", 
                                 involved => [$attacker->name, $defender->name] }, $attacker->name, $defender->name); 
        my @attacker_coalition = $self->empire($attacker->name);
        @attacker_coalition = grep { ! $self->war_busy($_) } @attacker_coalition;
        my @defender_coalition = $self->empire($defender->name);
        @defender_coalition = grep { ! $self->war_busy($_) } @defender_coalition;
    
        #Allies management
        my @attacker_allies = $self->get_allies($attacker->name);
        my @defender_allies = $self->get_allies($defender->name);
        for(@attacker_allies)
        {
            my $ally_name = $_->destination($attacker->name);
            my $ally = $self->get_nation( $ally_name );
            if($ally->good_prey($defender, $self, ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT, 0 ))
            {
                if(! grep { $_ eq $ally_name } @attacker_coalition)
                {
                    push @attacker_coalition, $ally_name;
                    $ally->register_event("JOIN WAR AS ALLY OF " . $attacker->name ." AGAINST " . $defender->name);
                }
            }
        }
        for(@defender_allies)
        {
            my $ally_name = $_->destination($defender->name);
            my $ally = $self->get_nation( $ally_name );
            if($ally->good_prey($attacker, $self, ALLY_CONFLICT_LEVEL_FOR_INVOLVEMENT, 0 ))
            {
                if(! grep { $_ eq $ally_name } @defender_coalition)
                {
                    push @defender_coalition, $ally_name;
                    $ally->register_event("JOIN WAR AS ALLY OF " . $defender->name ." AGAINST " . $attacker->name);
                }
            }
        }

        my @attacker_targets = $self->get_group_borders(\@attacker_coalition, \@defender_coalition);
        my @defender_targets = $self->get_group_borders(\@defender_coalition, \@attacker_coalition);
        my @war_couples;
        my @couples_factions;
        my %used;
        for(@attacker_coalition, @defender_coalition)
        {
            $used{$_} = 0;
        }
        #push @war_couples, [$attacker->name, $defender->name];
        $used{$attacker->name} = 1;
        $used{$defender->name} = 1;
        my $faction = 1;
        my $done = 0;
        my $faction0_done = 0;
        my $faction1_done = 0;
        while(! $done)
        {
            my @potential_attackers;
            if($faction == 0)
            {
                @potential_attackers = grep { $used{$_} == 0 } @attacker_coalition;
            }
            elsif($faction == 1)
            {
                @potential_attackers = grep { $used{$_} == 0 } @defender_coalition;
            }
            if(@potential_attackers == 0)
            {
                if($faction0_done == 1 && $faction == 1 ||
                   $faction1_done == 1 && $faction == 0)
                {
                    $done = 1;
                    last;
                } 
                else
                {
                    if($faction == 0)
                    {
                        $faction0_done = 1;
                        $faction = 1;
                    }
                    else
                    {
                        $faction1_done = 1;
                        $faction = 0;
                    }
                    next;
                }
                
            }
            @potential_attackers = $self->shuffle("War creation. Choosing attackers", @potential_attackers);
            my $attack_now = $potential_attackers[0];
            my $defend_now = undef;
            my $free_level = 0;
            my $searching = 1;
            while($searching)
            {
                my @potential_defenders;
                if($faction == 0)
                {
                    @potential_defenders = grep { ! $self->exists_treaty_by_type($_, $attack_now, 'no aggression') } @defender_coalition;
                    if(@potential_defenders == 0)
                    {
                        @attacker_coalition = grep { ! $attack_now eq $_ } @attacker_coalition;
                        $self->broadcast_event({ code => 'nopartecipatewar',
                                                 text => "NO POSSIBILITY TO PARTECIPATE TO WAR LINKED TO WAR BETWEEN " . $attacker->name . " AND " .$defender->name . " FOR $attack_now", 
                                                 involved => [$attack_now, $attacker->name, $defender->name] }, $attack_now);
                        last;
                    }
                }
                elsif($faction == 1)
                {
                    @potential_defenders = grep { ! $self->exists_treaty_by_type($_, $attack_now, 'no aggression') } @attacker_coalition;
                    if(@potential_defenders == 0)
                    {
                        @defender_coalition = grep { ! $attack_now eq $_ } @defender_coalition;
                        $self->broadcast_event({ code => 'nopartecipatewar',
                                                 text => "NO POSSIBILITY TO PARTECIPATE TO WAR LINKED TO WAR BETWEEN " . $attacker->name . " AND " .$defender->name . " FOR $attack_now", 
                                                 involved => [$attack_now, $attacker->name, $defender->name] }, $attack_now);
                        last;
                    }
                }
                @potential_defenders = grep { $used{$_} <= $free_level } @potential_defenders;
                if(@potential_defenders > 0)
                {
                    @potential_defenders = $self->shuffle("War creation. Choosing defenders", @potential_defenders);
                    $defend_now = $potential_defenders[0];
                    $searching = 0;
                }
                else
                {
                    $free_level++;
                }
            }
            if($defend_now)
            {
                push @war_couples, [$attack_now, $defend_now];
                push @couples_factions, $faction;
                $used{$defend_now} += 1;
            }
            $used{$attack_now} += 1;
            if($faction == 0)
            {
                $faction = 1;
            }
            else
            {
                $faction = 0;
            }
        }
        my %attacker_leaders;
        my $war_id = time;
        my $war = BalanceOfPower::Relations::War->new(node1 => $attacker->name, 
                                                      node2 => $defender->name,
                                                      attack_leader => $attacker->name,
                                                      war_id => $war_id,
                                                      node1_faction => 0,
                                                      node2_faction => 1,
                                                      start_date => $self->current_year,
                                                      log_active => 0,
                                                      );
        $war = $self->war_starting_report($war);
        $self->add_war($war); 
        $attacker_leaders{$defender->name} = $attacker->name;                                              
        $self->broadcast_event({ code => 'warstart', 
                                 text => "WAR BETWEEN " . $attacker->name . " AND " .$defender->name . " STARTED", 
                                 involved => [$attacker->name, $defender->name],
                                 values => [$war_id] }, $attacker->name, $defender->name);
        my $faction_counter = 0;
        foreach my $c (@war_couples)
        {
            my $leader;
            if(exists $attacker_leaders{$c->[1]})
            {
                $leader = $attacker_leaders{$c->[1]}
            }
            else
            {
                $leader = $c->[0];
                $attacker_leaders{$c->[1]} = $c->[0];
            }
            my $faction1;
            my $faction2;
            if($couples_factions[$faction_counter] == 0)
            {
                $faction1 = 0;
                $faction2 = 1;
            }
            else
            {
                $faction1 = 1;
                $faction2 = 0;
            }
            my $node1 = $c->[0];
            my $node2 = $c->[1];
            my $war = BalanceOfPower::Relations::War->new(node1 => $node1, 
                                                          node2 => $node2,
                                                          attack_leader => $leader,
                                                          war_id => $war_id,
                                                          node1_faction => $faction1,
                                                          node2_faction => $faction2,
                                                          start_date => $self->current_year,
                                                          log_active => 0);
            $war = $self->war_starting_report($war);
            $self->add_war($war);                                                  
            $self->broadcast_event( { code => 'warlinkedstart',
                                      text => "WAR BETWEEN " . $node1 . " AND " . $node2 . " STARTED (LINKED TO WAR BETWEEN " . $attacker->name . " AND " .$defender->name . ")",
                                      involved => [$node1, $node2],
                                      values => [$war_id, $attacker->name, $defender->name, $faction1, $faction2] }, $node1, $node2 );
        }
    }
}
sub war_starting_report
{
    my $self = shift;
    my $war = shift;
    my $node1 = $war->node1;
    my $node2 = $war->node2;
    $war->register_event("Starting army for " . $node1 . ": " . $self->get_nation($node1)->army);
    $war->register_event("Progress of " . $node1 . ": " . $self->get_nation($node1)->progress);
    my $sup1 = $self->supported($node1);
    if($sup1)
    {
        $war->register_event("$node1 is supported by " . $sup1->node1 . ": " . $sup1->army);
    }
    $war->register_event("Starting army for " . $node2 . ": " . $self->get_nation($node2)->army);
    $war->register_event("Progress of " . $node2 . ": " . $self->get_nation($node2)->progress);
    my $sup2 = $self->supported($node2);
    if($sup2)
    {
        $war->register_event("$node2 is supported by " . $sup2->node1 . ": " . $sup2->army);
    }
    return $war;
}

sub army_for_war
{
    my $self = shift;
    my $nation = shift;
    my $supported = $self->supported($nation->name);
    my $army = $nation->army;
    if($supported)
    {
        $army += $supported->army;
    }
    return $army;
}

sub damage_from_battle
{
    my $self = shift;
    my $nation = shift;
    my $damage = shift;
    my $attacker = shift;
    my $supported = $self->supported($nation->name);
    if($supported && $self->exists_treaty_by_type($attacker->name, $supported->node1, 'no aggression'))
    {
        $supported = undef;
    }
    my $flip = 0;
    my $army_damage = 0;
    while($damage > 0)
    {
        if($flip == 0)
        {
            if($supported && $supported->army > 0)
            {
                $supported->casualities(1);
                $damage--;
            }
            $flip = 1;
        }
        else
        {
            $army_damage++;
            $damage--;
            $flip = 0;
        }
    }
    $nation->add_army(-1 * $army_damage);
    if($supported)
    {
        if($supported->army <= 0)
        {
            $self->broadcast_event({ code => 'supdestroyed',
                                     text => "MILITARY SUPPORT TO " . $supported->node2 . " BY " . $supported->node1 . " DESTROYED", 
                                     involved => [$supported->node1, $supported->node2] }, $supported->node1, $supported->node2);
            $self->war_report("Military support to ". $supported->node2 . " by " . $supported->node1 . " destroyed", $supported->node2);
        }
    }
    $self->military_support_garbage_collector();
}

sub fight_wars
{
    my $self = shift;
    my %losers;
    my %war_bonds_issued = ();
    foreach my $w ($self->wars->all())
    {
        if(! exists $war_bonds_issued{$w->node1})
        {
            $self->issue_war_bonds($w->node1);
            $war_bonds_issued{$w->node1} = 1;
        }
        if(! exists $war_bonds_issued{$w->node2})
        {
            $self->issue_war_bonds($w->node2);
            $war_bonds_issued{$w->node2} = 1;
        }

        #As Risiko
        $self->broadcast_event({ code => 'wargoon',
                                 text => "WAR BETWEEN " . $w->node1 . " AND " . $w->node2 . " GO ON",
                                 involved => [$w->node1, $w->node2],
                                 values => [$w->war_id] }, $w->node1, $w->node2);
        my $attacker = $self->get_nation($w->node1);
        my $defender = $self->get_nation($w->node2);
        my $attacker_army = $self->army_for_war($attacker);
        my $defender_army = $self->army_for_war($defender);
        my $attack = $attacker_army >= ARMY_FOR_BATTLE ? ARMY_FOR_BATTLE : $attacker_army;
        my $defence = $defender_army >= ARMY_FOR_BATTLE ? ARMY_FOR_BATTLE : $defender_army;
        my $attacker_damage = 0;
        my $defender_damage = 0;
        my $counter = $attack < $defence ? $attack : $defence;
        my $progress_delta = $attacker->progress - $defender->progress;
        my $attacker_progress_bonus;
        my $defender_progress_bonus;
        if($progress_delta > 0)
        {
            $attacker_progress_bonus = $progress_delta * PROGRESS_BATTLE_FACTOR;
            $defender_progress_bonus = 0;
        }
        else
        {
            $attacker_progress_bonus = 0;
            $defender_progress_bonus = $progress_delta * PROGRESS_BATTLE_FACTOR * -1;
        }
        for(my $i = 0; $i < $counter; $i++)
        {
            my $att = int(($self->random(1, 60, "War risiko: throw for attacker " . $attacker->name) + $attacker_progress_bonus) / 10) + 1;
            my $def = int(($self->random(1, 60, "War risiko: throw for defender " . $defender->name) + $defender_progress_bonus) / 10) + 1;

            if($att > $def)
            {
                $defender_damage++;
            }
            else
            {
                $attacker_damage++;
            }
        }
        if(my $sup = $self->supported($attacker->name))
        {
            my $supporter_n = $sup->start($attacker->name);
            if(! $self->exists_treaty_by_type($defender->name, $supporter_n, 'no aggression'))
            {
                $self->change_diplomacy($defender->name, $supporter_n, -1 * DIPLOMACY_MALUS_FOR_SUPPORT, "WAR WITH " . $attacker->name);
            }
        }
        if(my $sup = $self->supported($defender->name))
        {
            my $supporter_n = $sup->start($defender->name);
            if(! $self->exists_treaty_by_type($attacker->name, $supporter_n, 'no aggression'))
            {
                $self->change_diplomacy($attacker->name, $supporter_n, -1 * DIPLOMACY_MALUS_FOR_SUPPORT, "WAR WITH " . $defender->name);
            }
        }

        $self->damage_from_battle($attacker, $attacker_damage, $defender);
        $self->damage_from_battle($defender, $defender_damage, $attacker);
        $attacker->register_event("CASUALITIES IN WAR WITH " . $defender->name . ": $attacker_damage");
        $defender->register_event("CASUALITIES IN WAR WITH " . $attacker->name . ": $defender_damage");
        if($attacker->army == 0)
        {
            $losers{$attacker->name} = 1;
        }
        elsif($defender->army == 0)
        {
            $losers{$defender->name} = 1;
        }
    }
    for(keys %losers)
    {
        $self->lose_war($_);
    }
}

sub lose_war
{
    my $self = shift;
    my $loser = shift;
    my $internal_disorder = shift;
    $internal_disorder ||= 0;
    my @wars = $self->get_wars($loser);
    my $retreat_penality = 0;
    my @conquerors = ();
    my $conquerors_leader = "";
    my $occupied = 0;
    foreach my $w (@wars)
    {
        my $other;
        my $winner_role;
        if($w->node1 eq $loser)
        {
            #Loser is the attacker
            $retreat_penality = 1;
            $other = $w->node2;
            $winner_role = "[DEFENDER]";
            $self->send_event("RETREAT FROM " . $other, $loser);
        }
        elsif($w->node2 eq $loser)
        {
            #Loser is the defender
            $other = $w->node1;
            push @conquerors, $w->node1;
            $self->delete_crisis($loser, $other);
            $conquerors_leader = $w->attack_leader;
            $winner_role = "[ATTACKER]";
            $self->get_nation($loser)->internal_disorder(AFTER_CONQUERED_INTERNAL_DISORDER);
        }
        my $ending_line = "WAR BETWEEN $other AND $loser WON BY $other $winner_role";

        $self->broadcast_event({ code => 'warend',
                                 text => $ending_line, 
                                 involved => [$other, $loser],
                                 values => [$w->war_id, $winner_role] }, $other, $loser);
        my $history_line = "";
        $self->cash_war_bonds($other);
        $self->discard_war_bonds($loser);
        $history_line .= "$other $winner_role won the war";
        $self->delete_war($other, $loser, $history_line);
    }
    if(@conquerors > 0)
    {
        $occupied = 1;
        $self->occupy($loser, \@conquerors, $conquerors_leader, $internal_disorder);  
    }
    return $occupied;
}

sub delete_war
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $ending_line = shift;
    my $war = $self->war_exists($nation1, $nation2);
    $war->end_date($self->current_year);
    $war->register_event($ending_line);
    push @{$self->memorial}, $war;
    $self->delete_war_link($nation1, $nation2);
}



sub dump_memorial
{
    my $self = shift;
    my $io = shift;
    my $indent = shift;
    foreach my $w (@{$self->memorial})
    {
        print {$io} $w->dump($io, $indent);
    }
}
sub load_memorial
{
    my $self = shift;
    my $data = shift;
    
    $data .= "EOF";
    my $war_data = "";
    my @memorial;
    my @lines = split "\n", $data;
    foreach my $l (@lines)
    {
        if($l !~ /^\s/)
        {
            if($war_data)
            {
                push @memorial, BalanceOfPower::Relations::War->load($war_data);
                $war_data = $l . "\n";
            }
            else
            {
                $war_data = $l . "\n";
            }
        }
        else
        {
            $war_data .= $l . "\n";
        }
    }
    return \@memorial;
}


1;
