package BalanceOfPower::Relations::War;
$BalanceOfPower::Relations::War::VERSION = '0.400115';
use strict;
use v5.10;

use Moo;
use BalanceOfPower::Utils qw( from_to_turns as_html_evidenced );
use Term::ANSIColor;
use HTML::Entities;

with 'BalanceOfPower::Relations::Role::Relation';
with 'BalanceOfPower::Role::Reporter';

has attack_leader => (
    is => 'rw',
    default => ""
);
has war_id => (
    is => 'rw',
    default => ""
);
has name => (
    is => 'rw',
    default => "WAR"
);
has node1_faction => (
    is => 'rw',
    default => ""
);
has node2_faction => (
    is => 'rw',
    default => ""
);
has start_date => (
    is => 'ro',
    default => ""
);
has end_date => (
    is => 'rw',
    default => ""
);
has current_year => (
    is => 'rw',
    default => ""
);


sub bidirectional
{
    return 0;
}

sub print
{
    my $self = shift;
    my $army_node1 = shift;
    my $army_node2 = shift;
    return $self->output($army_node1, $army_node2, 'print');
}
sub html
{
    my $self = shift;
    my $army_node1 = shift;
    my $army_node2 = shift;
    return $self->output($army_node1, $army_node2, 'html');
}



sub output 
{
    my $self = shift;
    my $army_node1 = shift;
    my $army_node2 = shift;
    my $mode = shift;
    my $army_node1_label = $army_node1 ? "[".$army_node1."] " : "";
    my $army_node2_label = $army_node2 ? " [".$army_node2."]" : "";
    my $node1 = $army_node1_label . $self->node1;
    my $node2 = $self->node2 . $army_node2_label;
    if($mode eq 'print')
    {
        if($self->node1_faction == 0)
        {
            $node1 = color("bold") . $node1 . color("reset");
        }
        else
        {
            $node2 = color("bold") . $node2 . color("reset");
        }
        return  $node1 . " -> " . $node2;
    }
    elsif($mode eq 'html')
    {
        if($self->node1_faction == 0)
        {
            $node1 = as_html_evidenced($node1);
        }
        else
        {
            $node2 = as_html_evidenced($node2);
        }
        return  $node1 . " -&gt; " . $node2;
    }
        
    
    
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    print {$io} $indent . join(";", $self->node1, $self->node2, $self->attack_leader,
                                    $self->war_id, $self->name, $self->node1_faction, $self->node2_faction, 
                                    $self->start_date, $self->end_date, $self->current_year ). "\n";
    if($self->events)
    {    
        $self->dump_events($io, $indent . " ");
    }
}
sub load
{
    my $self = shift;
    my $data = shift;
    my $war_line = ( split /\n/, $data )[0];
    $war_line =~ s/^\s+//;
    chomp $war_line;
    my ($node1, $node2, $attack_leader, $war_id, $name, $node1_faction, $node2_faction, $start_date, $end_date, $current_year) = split ";", $war_line;
    $data =~ s/^.*?\n//;
    my $events = $self->load_events($data);
    return $self->new(node1 => $node1, node2 => $node2, 
                         attack_leader => $attack_leader, 
                         war_id => $war_id, name => $name, 
                         node1_faction => $node1_faction, node2_faction => $node2_faction, 
                         start_date => $start_date, end_date => $end_date, current_year => $current_year,
                         events => $events);
}



1;
