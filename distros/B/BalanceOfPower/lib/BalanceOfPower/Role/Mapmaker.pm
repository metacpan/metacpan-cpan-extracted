package BalanceOfPower::Role::Mapmaker;
$BalanceOfPower::Role::Mapmaker::VERSION = '0.400115';
use v5.10;
use strict;
use Moo::Role;

use BalanceOfPower::Relations::Border;
use BalanceOfPower::Relations::RelPack;
use BalanceOfPower::Utils qw( as_main_title);


has borders => (
    is => 'ro',
    default => sub { BalanceOfPower::Relations::RelPack->new() },
    handles => { add_border => 'add_link',
                 border_exists => 'exists_link',
                 get_borders => 'links_for_node',
                 near_on_the_map => 'near',
                 distance_on_the_map => 'distance'
               }
);

sub print_borders
{
    my $self = shift;
    my $n = shift;
    return $self->output_borders("BORDERS", $n, 'print');
}
sub html_borders
{
    my $self = shift;
    my $n = shift;
    return $self->output_borders("BORDERS", $n, 'html');
}


sub output_borders
{
    my $self = shift;
    my $title = shift;
    my $n = shift;
    my $mode = shift;
    my $out = "";
    $out .= as_main_title($title, $mode);
    $out .= $self->borders->output_links($n, $mode);
    return $out;
}


sub load_borders
{
    my $self = shift;
    my $bordersfile = shift;
    my $file = shift || $self->data_directory . "/" . $bordersfile;
    open(my $borders, "<", $file) || die $!;;
    for(<$borders>)
    {
        chomp;
        my $border = $_;
        my @nodes = split(/,/, $border);
        if($self->check_nation_name($nodes[0]) && $self->check_nation_name($nodes[1]))
        {
            if($nodes[0] && $nodes[1] && ! $self->border_exists($nodes[0], $nodes[1]))
            {
                my $b = BalanceOfPower::Relations::Border->new(node1 => $nodes[0], node2 => $nodes[1]);
                $self->add_border($b);
            }
        }
        else
        {
            say "WRONG BORDER: $border";
        }
    }
}

sub near_nations
{
    my $self = shift;
    my $nation = shift;
    my $geographical = shift || 0;
    if($geographical)
    {
        return $self->near_on_the_map($nation, $self->nation_names);
    }
    else
    {
        return grep { $self->in_military_range($nation, $_) && $nation ne $_ } @{$self->nation_names};
    }
}
sub print_near_nations
{
    my $self = shift;
    my $nation = shift;
    my $out = "";
    for($self->near_nations($nation))
    {
        $out .= $_ . "\n";
    }
    return $out;
}
sub distance
{
    my $self = shift;
    my $nation1 = shift;
    my $nation2 = shift;
    return $self->distance_on_the_map($nation1, $nation2, $self->nation_names);
}


sub get_group_borders
{
    my $self = shift;
    my $group1 = shift;
    my $group2 = shift;
    my @from = @{ $group1 };
    my @to = @{ $group2 };
    my @out = ();
    foreach my $to_n (@to)
    {
        foreach my $from_n (@from)
        {
            if($self->in_military_range($from_n, $to_n))
            {
                push @out, $to_n;
                last;
            }
        }
    }
    return @out;
}

#cache management


sub print_distance
{
    my $self = shift;
    my $n1 = shift;
    my $n2 = shift;
    return "Distance between $n1 and $n2: " . $self->distance($n1, $n2);
}



1;
