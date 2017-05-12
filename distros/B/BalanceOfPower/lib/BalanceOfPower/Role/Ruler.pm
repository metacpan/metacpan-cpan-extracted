package BalanceOfPower::Role::Ruler;
$BalanceOfPower::Role::Ruler::VERSION = '0.400115';
use strict;
use Moo::Role;

use BalanceOfPower::Constants ':all';

use BalanceOfPower::Relations::Influence;

requires 'broadcast_event';
requires 'get_nation';

has influences => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { reset_influences => 'delete_link_for_node',
                 add_influence => 'add_link' }
);
sub influences_garbage_collector
{
    my $self = shift;
    $self->influences->garbage_collector(sub { my $rel = shift; return $rel->status == -1 });
}
sub is_under_influence
{
    my $self = shift;
    my $nation = shift;
    my @rels = $self->influences->query(
        sub {
            my $rel = shift;
            return 0 if($rel->node2 ne $nation);
            return $rel->actual_influence()
        }, $nation);
    if(@rels > 0)
    {
        return $rels[0]->start($nation);
    }
    else
    {
        return undef;
    }
}
sub print_nation_situation
{
    my $self = shift;
    my $nation = shift;
    my $domination = $self->is_under_influence($nation);
    return "$nation is under control of $domination" if $domination;
    my @influence = $self->has_influence($nation);
    if(@influence > 0)
    {
        my $out = "";
        for(@influence)
        {
            $out .= "$nation has influence on $_\n";
        }
        return $out;
    }
    else
    {
        return "$nation is free";
    }

}
sub has_influence
{
    my $self = shift;
    my $nation = shift;
    my @influences = $self->influences->query(
                        sub {
                            my $rel = shift;
                            return 0 if($rel->node1 ne $nation);
                            return $rel->actual_influence()
                        }, $nation);
    my @out = ();
    for(@influences)
    {
        push @out, $_->destination($nation);
    }
    return @out;
}
sub empire
{
    my $self = shift;
    my $n = shift;
    if(my $domination = $self->is_under_influence($n))
    {
        my $dominator = $domination;
        my @allies = $self->has_influence($dominator);
        push @allies, $dominator;
        return @allies;
    }
    else
    {
        my @allies = $self->has_influence($n);
        push @allies, $n;
        return @allies;
    }
}
sub occupy
{
    my $self = shift;
    my $nation = shift;
    my $occupiers = shift;
    my $leader = shift;
    my $internal_disorder = shift || 0;
    $self->get_nation($nation)->occupation($self);
    my $occupied_progress = $self->get_nation($nation)->progress;

    my @occupiers_array = @{$occupiers};
    my $real_leader = $self->is_under_influence($leader);
    if($real_leader)
    {
        @occupiers_array = grep { $_ ne $real_leader } @occupiers_array;
        push @occupiers_array, $real_leader;
        $leader = $real_leader;
    }
    foreach my $c (@occupiers_array)
    {
        if($c eq $leader)
        {
            $self->add_influence(BalanceOfPower::Relations::Influence->new( node1 => $c,
                                                                       node2 => $nation,
                                                                       status => 0,
                                                                       next => $internal_disorder ? 2 : 1,
                                                                       clock => 0 ));
            $self->set_diplomacy($nation, $c, DOMINION_DIPLOMACY);
            $self->copy_diplomacy($c, $nation);
            if($self->get_nation($c)->progress < $occupied_progress)
            {
                $self->get_nation($c)->progress($occupied_progress);
                $self->broadcast_event({ code => 'acquireprogress',
                                         text => "$c ACQUIRES PROGRESS FROM $nation: $occupied_progress", 
                                         involved => [$c, $nation],
                                         values => [$occupied_progress] }, $c, $nation);
            }
        }
        else
        {
            $self->add_influence(BalanceOfPower::Relations::Influence->new( node1 => $c,
                                                                       node2 => $nation,
                                                                       status => 0,
                                                                       clock => 0 ));
            $self->set_diplomacy($nation, $c, DIPLOMACY_AFTER_OCCUPATION);
            $self->get_nation($c)->grow();
        }
        $self->broadcast_event({code => 'occupy',
                                text => "$c OCCUPIES $nation", 
                                involved => [$c, $nation] }, $c, $nation );
    }
}
sub situation_clock
{
    my $self = shift;
    foreach my $i ($self->influences->all())
    {
        my $old_status = $i->status_label;
        my $new_status = $i->click();    
        if($new_status && $old_status ne $new_status)
        {
            if($new_status eq 'dominate')
            {
                $self->broadcast_event({ code => 'dominate',
                                         text => $i->node1 . " DOMINATES " . $i->node2, 
                                         involved => [$i->node1, $i->node2] }, $i->node1, $i->node2);
            }
            elsif($new_status eq 'control')
            {
                $self->broadcast_event({ code => 'control',
                                         text => $i->node1 . " CONTROLS " . $i->node2, 
                                         involved => [$i->node1, $i->node2] }, $i->node1, $i->node2);
            }
        }
    }
    $self->influences_garbage_collector();
}

sub print_influences
{
    my $self = shift;
    my $n = shift;
    my $mode = shift || 'print';
    my @inf = $self->influences->links_for_node($n);
    @inf = sort { lc($a->node1) cmp lc($b->node1) } @inf;
    return BalanceOfPower::Printer::print($mode, $self, 'print_influences', 
                                          { influences => \@inf } );
}

1;
