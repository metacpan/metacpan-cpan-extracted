package BalanceOfPower::Relations::Role::Relation;
$BalanceOfPower::Relations::Role::Relation::VERSION = '0.400115';
use strict;
use Moo::Role;
use HTML::Entities;

has node1 => (
    is => 'ro'
);
has node2 => (
    is => 'ro'
);

sub bidirectional
{
    return 1;
}

sub has_node
{
    my $self = shift;
    my $node = shift;
    return $self->node1 eq $node || $self->node2 eq $node;
}
sub is_between
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";

    return ($self->node1 eq $node1 && $self->node2 eq $node2) ||
           ($self->node1 eq $node2 && $self->node2 eq $node1 && $self->bidirectional);
}
sub involve
{
    my $self = shift;
    my $node1 = shift || "";
    my $node2 = shift || "";

    return ($self->node1 eq $node1 && $self->node2 eq $node2) ||
           ($self->node1 eq $node2 && $self->node2 eq $node1);
}
sub destination
{
    my $self = shift;
    my $node = shift;
    if($self->node1 eq $node)
    {
        return $self->node2;
    }
    elsif($self->node2 eq $node && $self->bidirectional)
    {
        return $self->node1;
    }
    else
    {
        return undef;
    }
}
sub start
{
    my $self = shift;
    my $node = shift;
    if($self->node2 eq $node)
    {
        return $self->node1;
    }
    elsif($self->node1 eq $node && $self->bidirectional)
    {
        return $self->node1;
    }
    else
    {
        return undef;
    }
}
sub output
{
    my $self = shift;
    my $mode = shift;
    if($mode eq 'print')
    {
        return $self->print;
    }
    elsif($mode eq 'html')
    {
        return $self->html;
    }
}


sub print 
{
    my $self = shift;
    my $from = shift;
    if($from && $from eq $self->node1)
    {
        return $from . " -> " . $self->node2;
    }
    elsif($from && $from eq $self->node2 )
    {
        if($self->bidirectional)
        {
            return $self->node2 . " -> " . $self->node1;
        }
        else
        {
            return $self->node1 . " -> " . $self->node2;
        }
    }
    else
    {
        if($self->bidirectional)
        {
            return $self->node1 . " <-> " . $self->node2;
        }
        else
        {
            return $self->node1 . " -> " . $self->node2;
        }
    }
}
sub html
{
    my $self = shift;
    return encode_entities($self->print);
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . $self->node1 . ";" . $self->node2 . "\n";
}
sub load
{
    my $self = shift;
    my $data = shift;
    $data =~ s/^\s+//;
    chomp $data;
    my ($node1, $node2) = split ";", $data;
    return $self->new(node1 => $node1, node2 => $node2);
}
1;
