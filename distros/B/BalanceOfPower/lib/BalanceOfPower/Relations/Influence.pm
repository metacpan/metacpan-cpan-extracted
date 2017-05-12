package BalanceOfPower::Relations::Influence;
$BalanceOfPower::Relations::Influence::VERSION = '0.400115';
use strict;
use v5.10;

use Moo;
use BalanceOfPower::Constants ':all';


with 'BalanceOfPower::Relations::Role::Relation';

# Status:
#   0: occupy
#   1: dominate
#   2: control

has status => (
    is => 'rw',
    default => -1
);
has next => (
    is => 'rw',
    default => -1
);
has clock => (
    is => 'rw',
    default => 0
);
sub bidirectional
{
    return 0;
}
sub status_label
{
    my $self = shift;
    if($self->status == 0)
    {
        return 'occupy';
    }
    elsif($self->status == 1)
    {
        return 'dominate';
    }
    elsif($self->status == 2)
    {
        return 'control';
    }
    else
    {
        return undef;
    }
}
sub get_loot_quote
{
    my $self = shift;
    if($self->status == 0)
    {
        return OCCUPATION_LOOT_BY_TYPE
    }
    elsif($self->status == 1)
    {
        return DOMINATION_LOOT_BY_TYPE;
    }
    elsif($self->status == 2)
    {
        return CONTROL_LOOT_BY_TYPE;
    }
    else
    {
        return undef;
    }
}
sub click
{
    my $self = shift;
    $self->clock($self->clock + 1);
    if($self->status == 0 && $self->clock >= OCCUPATION_CLOCK_LIMIT)
    {
        return $self->change_to_next();
    }
    elsif($self->status == 1 && $self->clock >= DOMINATION_CLOCK_LIMIT)
    {
        return $self->change_to_next();
    }
    else
    {
        return $self->status;
    }
}
sub change_to_next
{
    my $self = shift;
    $self->status($self->next);
    $self->clock(0);
    return $self->status_label;
}
sub print
{
    my $self = shift;
    return $self->node1 . " " . $self->status_label . " " . $self->node2;
}
sub actual_influence
{
    my $self = shift;
    if(($self->status == 1 && $self->next != -1) ||
        $_->status > 1)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . join(";", $self->node1, $self->node2, $self->status, $self->next, $self->clock) . "\n";
}
sub load
{
    my $self = shift;
    my $data = shift;
    $data =~ s/^\s+//;
    chomp $data;
    my ($node1, $node2, $status, $next, $clock) = split ";", $data;
    return $self->new(node1 => $node1, node2 => $node2, status => $status, next => $next, clock => $clock);
}


1;
