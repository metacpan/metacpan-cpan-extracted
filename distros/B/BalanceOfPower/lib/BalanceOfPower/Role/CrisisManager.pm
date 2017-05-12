package BalanceOfPower::Role::CrisisManager;
$BalanceOfPower::Role::CrisisManager::VERSION = '0.400115';
use strict;
use v5.10;
use Moo::Role;
use Template;
use Term::ANSIColor;

use BalanceOfPower::Constants ':all';
use BalanceOfPower::Printer;

requires 'get_all_crises';
requires 'get_hates';
requires 'crisis_exists';
requires 'war_exists';
requires 'broadcast_event';
requires 'add_crisis';

sub crisis_generator
{
    my $self = shift;
    my @crises = $self->get_all_crises();
    my @hates = ();
    foreach my $h  ($self->get_hates())
    {
        push @hates, $h
            if(! $self->crisis_exists($h->node1, $h->node2))
    }
    my $crises_to_use = \@crises;
    my $hates_to_use = \@hates;
    for(my $i = 0; $i < CRISIS_GENERATION_TRIES; $i++)
    {
        ($hates_to_use, $crises_to_use) = $self->crisis_generator_round($hates_to_use, $crises_to_use);
    }

}

sub crisis_generator_round
{
    my $self = shift;
    my $hates_to_use = shift || [] ;
    my $crises_to_use = shift || [];
    my @hates = $self->shuffle("Crisis generation: choosing hate", @{ $hates_to_use });
    my @crises = $self->shuffle("Crisis generation: choosing crisis", @{ $crises_to_use});
    my @original_hates = @hates;
    my @original_crises = @crises;
                     
    my $picked_hate = undef; 
    my $picked_crisis = undef;
    if(@hates)
    {
        $picked_hate = shift @hates;
    }
    if(@crises)
    {
        $picked_crisis = shift @crises;
    }
   

    my $action = $self->random(0, CRISIS_GENERATOR_NOACTION_TOKENS + 3, "Crisis action choose");
    if($action == 0) #NEW CRISIS
    {
        return (\@original_hates, \@original_crises) if ! $picked_hate; 
        if(! $self->war_exists($picked_hate->node1, $picked_hate->node2))
        {
            $self->create_or_escalate_crisis($picked_hate->node1, $picked_hate->node2);
            return (\@hates, \@original_crises);
        }
    }
    elsif($action == 1) #ESCALATE
    {
        return (\@original_hates, \@original_crises) if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->create_or_escalate_crisis($picked_crisis->node1, $picked_crisis->node2);
        }
        return (\@original_hates, \@crises);
    }
    elsif($action == 2) #COOL DOWN
    {
        return (\@original_hates, \@original_crises) if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->cool_down($picked_crisis->node1, $picked_crisis->node2);
        }
        return (\@original_hates, \@crises);
    }
    elsif($action == 3) #ELIMINATE
    {
        return (\@original_hates, \@original_crises) if ! $picked_crisis; 
        if(! $self->war_exists($picked_crisis->node1, $picked_crisis->node2))
        {
            $self->delete_crisis($picked_crisis->node1, $picked_crisis->node2);
        }
        return (\@original_hates, \@crises);
    }
    else
    {
        return (\@original_hates, \@original_crises);
    }
}
sub create_or_escalate_crisis
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";
    if(my $crisis = $self->crisis_exists($node1, $node2))
    {
        if(! $crisis->is_max_crisis)
        {
            $crisis->escalate_crisis();
            my $event = { code => 'crisisup',
                          text => "CRISIS BETWEEN $node1 AND $node2 ESCALATES",
                          involved => [$node1, $node2],
                          values => [ $crisis->get_crisis_level() ]
                        };
            $self->broadcast_event($event, $node1, $node2);
        }
    }
    else
    {
        $self->add_crisis($node1, $node2);
        $self->broadcast_event( { code => 'crisisstart',
                                text => "CRISIS BETWEEN $node1 AND $node2 STARTED", 
                                involved => [$node1, $node2] }, $node1, $node2);
    }
}
sub cool_down
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    if(my $crisis = $self->crisis_exists($node1, $node2))
    {
        $crisis->cooldown_crisis();
        if(! $crisis->is_crisis())
        {
            my $event = { code => 'crisisend', 
                          text => "CRISIS BETWEEN $node1 AND $node2 ENDED",
                          involved => [$node1, $node2] };
            $self->broadcast_event($event, $node1, $node2);
        }
        else
        {
            $self->broadcast_event({ code => 'crisisdown',
                                     text => "CRISIS BETWEEN $node1 AND $node2 COOLED DOWN",
                                     involved => [$node1, $node2],
                                     values => [ $crisis->get_crisis_level() ]
                                   }, $node1, $node2);
        }
    }
}

sub print_all_crises
{
    my $self = shift;
    my $n = shift;
    my $level = shift || 0;
    my $mode = shift || 'print';
    my @crises;
    my @war_signal;
    foreach my $b ($self->get_all_crises())
    {
        if(( ($n && $b->involve($n) || ! $n)) &&
          ( $b->get_crisis_level > $level))
        {
            push @crises, $b;
            if($self->war_exists($b->node1, $b->node2))
            {
                push @war_signal, 1;
            }
            else
            {
                push @war_signal, 0;
            }
        }
    }
    my %nation_codes = reverse %{$self->nation_codes};
    return BalanceOfPower::Printer::print($mode, $self, 'print_all_crises',
                                          { crises => \@crises,
                                            wars => \@war_signal,
                                            nation_codes => \%nation_codes,
                                           });
}
1;

