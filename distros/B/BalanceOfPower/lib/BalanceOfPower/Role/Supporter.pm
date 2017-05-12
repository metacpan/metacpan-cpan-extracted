package BalanceOfPower::Role::Supporter;
$BalanceOfPower::Role::Supporter::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;

use BalanceOfPower::Relations::MilitarySupport;
use BalanceOfPower::Constants ':all';

requires 'get_nation';
requires 'war_report';
requires 'civil_war_report';

has military_supports => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_military_support => 'add_link',
                 delete_military_support => 'delete_link',
                 exists_military_support => 'exists_link',
                 already_in_military_support => 'first_link_for_node',
                 supports => 'links_for_node',
                 supporter => 'links_for_node1',
                 supported => 'first_link_for_node2',
                 reset_supports => 'delete_link_for_node'
               }
);
has rebel_military_supports => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_rebel_military_support => 'add_link',
                 delete_rebel_military_support => 'delete_link',
                 exists_rebel_military_support => 'exists_link',
                 rebel_supports => 'links_for_node',
                 rebel_supporter => 'links_for_node1',
                 rebel_supported => 'first_link_for_node2',
                 reset_rebel_supports => 'delete_link_for_node'
               }
);

sub start_military_support
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    return 0 if($nation1->army < ARMY_FOR_SUPPORT);
    my $precedent_sup = $self->exists_military_support($nation1->name, $nation2->name);
    if($precedent_sup)
    {
        $precedent_sup->casualities(-1 * ARMY_FOR_SUPPORT);
        $self->broadcast_event( { code => 'supincreased',
                                text => "MILITARY SUPPORT TO " . $nation2->name . " INCREASED BY " . $nation1->name, 
                                involved => [$nation1->name, $nation2->name] },
                                $nation1->name, $nation2->name);
        $self->change_diplomacy($nation1->name, $nation2->name, DIPLOMACY_FACTOR_INCREASING_SUPPORT, "INCREASED MILITARY SUPPORT FROM " . $nation1->name);
        return 1;
    }
    if($self->supported($nation2->name))
    {
        $self->broadcast_event( { code => 'supfailed',
                                  text => $nation2->name . " ALREADY SUPPORTED. MILITARY SUPPORT IMPOSSIBLE FOR " . $nation1->name, 
                                  involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
        return 0;
    }
    my $supported = $self->supported($nation1->name);
    if($supported)
    {
            $self->stop_military_support($self->get_nation($supported->node1), $self->get_nation($supported->node2));
    }
    $nation1->add_army(-1 * ARMY_FOR_SUPPORT);
    $self->add_military_support(
        BalanceOfPower::Relations::MilitarySupport->new(
            node1 => $nation1->name,
            node2 => $nation2->name,
            army => ARMY_FOR_SUPPORT));
    $self->broadcast_event({ code => 'supstarted',
                             text => "MILITARY SUPPORT TO " . $nation2->name . " STARTED BY " . $nation1->name, 
                             involved => [$nation1->name, $nation2->name] },                                
                             $nation1->name, $nation2->name);
    $self->war_report($nation1->name . " started military support for " . $nation2->name, $nation2->name);
    $self->civil_war_report($nation1->name . " started military support for " . $nation2->name, $nation2->name);
    $self->change_diplomacy($nation1->name, $nation2->name, DIPLOMACY_FACTOR_STARTING_SUPPORT, "STARTED MILITARY SUPPORT FROM ".$nation1->name);
}
sub start_rebel_military_support
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    return 0 if($nation1->army < REBEL_ARMY_FOR_SUPPORT);
    my $precedent_sup = $self->exists_rebel_military_support($nation1->name, $nation2->name);
    if($precedent_sup)
    {
        $precedent_sup->casualities(-1 * ARMY_FOR_SUPPORT);
        $self->broadcast_event({ code => 'rebsupincreased' ,
                                 text => "REBEL MILITARY SUPPORT AGAINST " . $nation2->name . " INCREASED BY " . $nation1->name, 
                                 involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
        $self->change_diplomacy($nation1->name, $nation2->name, DIPLOMACY_FACTOR_INCREASING_REBEL_SUPPORT, "INCREASED REBEL MILITARY SUPPORT FROM " . $nation1->name);
        return 1;
    }
    if($self->rebel_supported($nation2->name))
    {
        $self->broadcast_event({ code => 'rebsupfailed',
                                 text => "REBELS IN " . $nation2->name . " ALREADY SUPPORTED. REBEL MILITARY SUPPORT IMPOSSIBILE FOR " . $nation1->name, 
                                 involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
        return 0;
    }
    $nation1->add_army(-1 * ARMY_FOR_SUPPORT);
    $self->add_rebel_military_support(
        BalanceOfPower::Relations::MilitarySupport->new(
            node1 => $nation1->name,
            node2 => $nation2->name,
            army => ARMY_FOR_SUPPORT));
    $self->broadcast_event({ code => 'rebsupstarted',
                             text => "REBEL MILITARY SUPPORT AGAINST " . $nation2->name . " STARTED BY " . $nation1->name, 
                             involved => [$nation1->name, $nation2->name] }, $nation1->name, $nation2->name);
    $self->civil_war_report($nation1->name . " started rebel military support in " . $nation2->name, $nation2->name);
    $self->change_diplomacy($nation1->name, $nation2->name, DIPLOMACY_FACTOR_STARTING_REBEL_SUPPORT, "STARTED REBEL MILITARY SUPPORT FROM " . $nation1->name);
}
sub stop_military_support
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $avoid_diplomacy = shift;
    my $milsup = $self->exists_military_support($node1->name, $node2->name);
    return if (! $milsup);
    $self->delete_military_support($node1->name, $node2->name);
    $node1->add_army($milsup->army);
    $self->broadcast_event( { code => 'supstopped',
                              text => "MILITARY SUPPORT FOR " . $node2->name . " STOPPED BY " . $node1->name, 
                              involved => [$node1->name, $node2->name] }, $node1->name, $node2->name);
    $self->war_report($node1->name . " stopped military support for " . $node2->name, $node2->name);
    $self->civil_war_report($node1->name . " stopped military support for " . $node2->name, $node2->name);
    if(! $avoid_diplomacy)
    {
        $self->change_diplomacy($node1->name, $node2->name, -1 * DIPLOMACY_FACTOR_BREAKING_SUPPORT, "STOPPED MILITARY SUPPORT FROM " . $node1->name);
    }
}
sub stop_rebel_military_support
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $milsup = $self->exists_rebel_military_support($node1->name, $node2->name);
    return if (! $milsup);
    $self->delete_rebel_military_support($node1->name, $node2->name);
    $node1->add_army($milsup->army);
    $self->civil_war_report($node1->name . " stopped rebel military support in " . $node2->name, $node2->name);
    $self->broadcast_event({ code => 'rebsupstopped',
                             text => "REBEL MILITARY SUPPORT AGAINST " . $node2->name . " STOPPED BY " . $node1->name, 
                             involved => [$node1->name, $node2->name] }, $node1->name, $node2->name);
}
sub military_support_garbage_collector
{
    my $self = shift;
    $self->military_supports->garbage_collector(sub { my $rel = shift; return $rel->army <= 0 });
}
sub rebel_military_support_garbage_collector
{
    my $self = shift;
    for($self->rebel_military_supports->all)
    {
        say $_->node1 . " => " . $_->node2;
        if(! $self->at_civil_war($_->node2))
        {
            $self->stop_rebel_military_support($self->get_nation($_->node1), $self->get_nation($_->node2));
        }
    }
    $self->rebel_military_supports->garbage_collector(sub { my $rel = shift; return $rel->army <= 0 });
}

sub print_military_supports
{
    my $self = shift;
    my $n = shift;
    my $mode = shift || 'print';
    return $self->print_supports($n, "MILITARY SUPPORTS", 0, $mode);
}
sub print_rebel_military_supports
{
    my $self = shift;
    my $n = shift;
    my $mode = shift || 'print';
    return $self->print_supports($n, "REBEL MILITARY SUPPORTS", 1, $mode);
}


sub print_supports
{
    my $self = shift;
    my $n = shift;
    my $title = shift || "MILITARY SUPPORTS";
    my $rebel = shift;
    my $mode = shift || 'print';
    my @sups;
    if($rebel)
    {
        @sups = $self->rebel_military_supports->links_for_node($n);
    }
    else
    {
        @sups = $self->military_supports->links_for_node($n);
    }
    return BalanceOfPower::Printer::print($mode, $self, 'print_supports', 
                                   {   title => $title,
                                       supports => \@sups,
                                   } );

}
1;
