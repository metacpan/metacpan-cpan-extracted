package BalanceOfPower::Role::Diplomat;
$BalanceOfPower::Role::Diplomat::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Constants ':all';

use BalanceOfPower::Relations::Friendship;
use BalanceOfPower::Relations::Treaty;
use BalanceOfPower::Relations::RelPack;
use BalanceOfPower::Utils qw( as_main_title as_html_box br);

has diplomatic_relations => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_diplomacy => 'add_link',
                 _diplomacy_exists => 'exists_link',
                 update_diplomacy => 'update_link',
                 get_diplomatic_relations => 'links_for_node' }
);
has treaties => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_treaty => 'add_link',
                 exists_treaty => 'exists_link',
                 get_treaties_for_nation => 'links_for_node',
                 reset_treaties => 'delete_link_for_node',
                 delete_treaty => 'delete_link', }
);

requires 'random';
requires 'distance';
requires 'border_exists';
requires 'broadcast_event';
requires 'is_under_influence';

sub init_diplomacy
{
    my $self = shift;
    my @nations = @{$self->nation_names};
    foreach my $n1 (@nations)
    {
        foreach my $n2 (@nations)
        {
            if($n1 ne $n2 && ! $self->_diplomacy_exists($n1, $n2))
            {
                my $minimum_friendship = 0;
                my $rel = BalanceOfPower::Relations::Friendship->new( node1 => $n1,
                                                           node2 => $n2,
                                                           factor => $self->calculate_random_friendship($n1, $n2));
                $self->add_diplomacy($rel);
            }
        }
    }
}

#Random friendship is function of the distance
sub calculate_random_friendship
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $distance = $self->distance($nation1, $nation2);
    $distance = 3 if $distance > 3;

    my $middle = 50;

    my $polar_factor = ( 4 - $distance ) * 5;
    my $random_floor = ( ( 3 - $distance ) * 5 ) + 25;

    my $side = $self->random(0, 1, "Side for friendship between $nation1 and $nation2");
    $side = $side == 0 ? -1 : 1;
    my $random_factor = $self->random(0, $random_floor, "Random factor for friendship between $nation1 and $nation2 [floor: $random_floor]");

    my $friendship = $middle + ( $side * ( $polar_factor + $random_factor ) );
    return $friendship;
}


sub init_random_alliances
{
    my $self = shift;
    my @nations = @{$self->nation_names};
    for(my $i = 0; $i < STARTING_ALLIANCES; $i++)
    {
        my $n1 = $nations[$self->random(0, $#nations, "Nation1 for random alliance")];
        my $n2 = $nations[$self->random(0, $#nations, "Nation2 for random alliance")];
        if($n1 ne $n2)
        {
            $self->add_alliance($n1, $n2);
            $self->broadcast_event("ALLIANCE BETWEEN $n1 AND $n2 CREATED", $n1, $n2);
        }
    }
}
sub reroll_diplomacy
{
    my $self = shift;
    my $nation = shift;
    my @rels = $self->get_diplomatic_relations($nation);
    for(@rels)
    {
        $_->factor($self->random(0 ,100, "Reroll diplomacy for " . $_->node1 . ", " . $_->node2));
    }
}

sub diplomacy_exists
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    my $r = $self->_diplomacy_exists($n1, $n2);
    if(! defined $r)
    {
        say "ERROR! No diplomacy between $n1, $n2";
    }
    return $r;
}

sub get_hates
{
    my $self = shift;
    my $nation = shift;
    my @hates = $self->diplomatic_relations->query( sub { my $rel = shift; return $rel->status eq 'HATE' });
    my @out = ();
    foreach my $r (@hates)
    {
        if(($nation && $r->has_node($nation)) || (! $nation))
        {
            if(! $self->is_under_influence($r->node1) && ! $self->is_under_influence($r->node2))
            {
                push @out, $r;
            }
        }
    }
    return @out;
}
sub get_nations_with_status
{
    my $self = shift;
    my $nation = shift;
    my $status = shift;
    my @st_array = @{$status};
    my @relations = $self->get_diplomatic_relations($nation);
    my @out = ();
    for(@relations)
    {
        my $r = $_;
        if(grep{ $_ eq $r->status } @st_array)
        {
            push @out, $r->destination($nation);
        }
    }
    return @out;
}

sub get_friends
{
    my $self = shift;
    my $nation = shift;
    return $self->get_nations_with_status($nation, ['FRIENDSHIP', 'ALLIANCE', 'INFLUENCE PRESENT']);
}
sub set_diplomacy
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $new_factor = shift;
    my $r = $self->diplomacy_exists($node1, $node2);
    return undef if(!$r ); #Should never happen
    $r->factor($new_factor);
    return $r;
}
sub copy_diplomacy
{
    my $self = shift;
    my $nation_from = shift;
    my $nation_to = shift;
    my @relations = $self->get_diplomatic_relations($nation_from);
    for(@relations)
    {
        my $r = $_;
        my $other = $r->destination($nation_from);
        if($other ne $nation_to)
        {
            $self->set_diplomacy($nation_to, $other, $r->factor);
        }
    }


}

sub change_diplomacy
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $dipl = shift;
    my $reason = shift;
    my $r = $self->diplomacy_exists($node1, $node2);
    return if(!$r ); #Should never happen
    return if $r->status eq 'ALLIANCE' || $r->status eq 'INFLUENCE PRESENT';
    my $present_status = $r->status;
    $r->change_factor($dipl);
    my $actual_status = $r->status;
    my $trend = $dipl > 0 ? 'up' : 'down';
    if($present_status ne $actual_status)
    {
        my $event_text = "RELATIONS BETWEEN $node1 AND $node2 CHANGED FROM $present_status TO $actual_status";
        if($reason)
        {
            $event_text = $event_text . " " . $reason;
        }
        else
        {
            $reason = "";
        }
        $self->broadcast_event({ code => "relchange",
                                 text => $event_text,
                                 involved => [$node1, $node2],
                                 values => [$trend, $present_status, $actual_status, $reason]},
                                $node1, $node2);
        if($actual_status eq 'HATE')
        {
            $self->diplomatic_breakdown($node1, $node2);
        }
    }
    else
    {
        my $event_text;
        if($dipl > 0)
        {
            $event_text = "RELATIONS BETWEEN $node1 AND $node2 ARE BETTER";
        }
        else
        {
            $event_text = "RELATIONS BETWEEN $node1 AND $node2 ARE WORSE";
        }
        if($reason)
        {
            $event_text = $event_text . " " . $reason;
        }
        $self->broadcast_event({ code => "relchange",
                                 text => $event_text,
                                 involved => [$node1, $node2],
                                 values => [$trend, $actual_status, $actual_status, $reason]},
                                $node1, $node2);
    }
}
sub diplomacy_status
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    my $r = $self->diplomacy_exists($n1, $n2);
    return $r->status;
}

sub diplomatic_breakdown
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    my $treaty = $self->exists_treaty($n1, $n2);
    if($treaty)
    {
        $self->delete_treaty($n1, $n2);
        $self->broadcast_event({ code => lc($treaty->short_tag) . "treatybroken",
                                 text => $treaty->short_tag . " TREATY BETWEEN $n1 AND $n2 BROKEN",
                                 involved => [$n1, $n2] },
                                 $n1, $n2);
    }
    $self->stop_military_support($self->get_nation($n1), $self->get_nation($n2), 1);
    $self->stop_military_support($self->get_nation($n2), $self->get_nation($n1), 1);
}

sub diplomacy_for_node
{
    my $self = shift;
    my $node = shift;
    my %relations;
    foreach my $n (@{$self->nation_names})
    {
        if($n ne $node)
        {
            my $real_r = $self->diplomacy_exists($node, $n);
            $relations{$n} = $real_r->factor;
        }
    }
    return %relations;;
}

sub print_diplomacy
{
    my $self = shift;
    my $n = shift;
    my $mode = shift || "print";
    my $out;
    my @outnodes = sort { $a->factor <=> $b->factor} $self->get_diplomatic_relations($n);
    return BalanceOfPower::Printer::print($mode, $self, 'print_diplomacy', 
                                   { nation => $n,
                                     relationships => \@outnodes,
                                   } );

}


sub diplomatic_pressure
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my @friends = $self->get_friends($nation1);
    $self->change_diplomacy($nation1, $nation2, DIPLOMATIC_PRESSURE_FACTOR, "DIPLOMATIC PRESSURE OF $nation1 ON $nation2");
    $self->broadcast_event({ code => 'pressure',
                             text => "DIPLOMATIC PRESSURE OF $nation1 ON $nation2",
                             involved =>  [$nation1, $nation2] }, $nation1, $nation2);
    for(@friends)
    {
        my $f = $_;
        $self->change_diplomacy($f, $nation2, DIPLOMATIC_PRESSURE_FACTOR, "DIPLOMATIC PRESSURE OF $nation1 ON $nation2");
    }
}


#Functions to manage relationships as crises
sub add_crisis
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $rel = $self->diplomacy_exists($nation1, $nation2);
    if($rel->get_crisis_level == 0)
    {
        $rel->escalate_crisis();
    }
}
sub delete_crisis
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $rel = $self->diplomacy_exists($nation1, $nation2);
    $rel->crisis_level(0);
}
sub crisis_exists
{
    my $self = shift;
    my $nation1 = shift || "";
    my $nation2 = shift || "";
    my $rel =  $self->diplomacy_exists($nation1, $nation2);
    if(! $rel)
    {
        say "ERROR: no diplomacy between $nation1, $nation2";
        return undef;
    }
    if($rel->get_crisis_level > 0)
    {
        return $rel;
    }
    else
    {
        return undef;
    }
}
sub get_crises
{
    my $self = shift;
    my $nation = shift;
    my @crises = $self->get_diplomatic_relations($nation);
    @crises = grep { $_->get_crisis_level > 0 } @crises;
    return @crises;
}
sub get_all_crises
{
    my $self = shift;
    my @rels = $self->diplomatic_relations->all();
    return grep { $_->is_crisis() } @rels;
}
sub reset_crises
{
    my $self = shift;
    my $nation = shift;
    my @rels = $self->get_diplomatic_relations($nation);
    for(@rels)
    {
        $_->crisis_level(0);
    }
}

#Functions to manage treaties
sub create_treaty
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $type = shift;
    $self->add_treaty(BalanceOfPower::Relations::Treaty->new(
                        node1 => $nation1,
                        node2 => $nation2,
                        type => $type ));
}
sub exists_treaty_by_type
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    my $type = shift;
    my $rel = $self->exists_treaty($nation1, $nation2);
    if( $rel && ($rel->type eq $type || $rel->type eq 'alliance')) #Alliance means both treaties are active
    {
        return $rel;
    }
    else
    {
        return undef;
    }
}
sub get_treaties_for_nation_by_type
{
    my $self = shift;
    my $nation = shift;
    my $type = shift;
    my @treaties = $self->get_treaties_for_nation($nation);
    return grep { $_->type eq $type } @treaties;
}

#Functions to manage alliances
sub add_alliance
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    $self->create_treaty($nation1, $nation2, 'alliance');
    $self->set_diplomacy($nation1, $nation2, ALLIANCE_FRIENDSHIP_FACTOR);
}
sub print_allies
{
    my $self = shift;
    my $nation = shift;
    my $mode = shift;
    return $self->print_treaties($nation, "ALLIANCES", 'alliance', $mode);
}
sub print_treaties
{
    my $self = shift;
    my $nation = shift;
    my $title = shift || "TREATIES";
    my $treaty = shift || undef;
    my $mode = shift || 'print';
    my @treaties = $self->treaties->all();
    my @to_print;
    for(@treaties)
    {
        if((($treaty && $_->type eq $treaty) || ! $treaty) &&
          (($nation && $_->involve($nation)) || ! $nation))  
        {
            push @to_print, $_;
        }
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_treaties', 
                                   { title => $title,
                                     treaties => \@to_print,
                                   } );
}

sub exists_alliance
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    return $self->exists_treaty_by_type($nation1, $nation2, 'alliance');
}

sub get_allies
{
    my $self = shift;
    my $nation = shift;
    return $self->get_treaties_for_nation_by_type($nation, 'alliance');
}


1;
