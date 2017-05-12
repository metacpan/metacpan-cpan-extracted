package BalanceOfPower::Relations::RelPack;
$BalanceOfPower::Relations::RelPack::VERSION = '0.400115';
use strict;
use v5.10;

use Moo;
use Module::Load;

has links => (
    is => 'rw',
    default => sub { [] }
);
has links_grid => (
    is => 'rw',
    default => sub { {} }
);
has distance_cache => (
    is => 'rw',
    default => sub { {} }
);


sub all
{
    my $self = shift;
    return @{$self->links};
}
sub reset
{
    my $self = shift;
    $self->links([]);
    $self->links_grid({});
    $self->distance_cache({});
}

sub exists_link
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    if(exists $self->links_grid->{$node1}->{$node2})
    {
        return $self->links_grid->{$node1}->{$node2} 
    }
    else
    {
        return undef;
    }
}

sub add_link
{
    my $self = shift;
    my $link = shift;
    my $node1 = $link->node1;
    my $node2 = $link->node2;
    if(! $self->exists_link($node1, $node2))
    {
        push @{$self->links}, $link;
        $self->links_grid->{$node1}->{$node2} = $link;
        $self->links_grid->{$node2}->{$node1} = $link;
        return 1;
    }
    else
    {
        return 0;
    }
}
sub update_link
{
    my $self = shift;
    my $link = shift;
    $self->delete_link($link->node1, $link->node2);
    $self->add_link($link);
}
sub delete_references
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    $self->links_grid->{$node1}->{$node2} = undef;
    $self->links_grid->{$node2}->{$node1} = undef;
}
sub delete_references_for_node
{
    my $self = shift;
    my $node1 = shift;
    foreach my $k (%{$self->links_grid->{$node1}})
    {
        if($k)
        {
            $self->links_grid->{$k}->{$node1} = undef;
        }
    }
    $self->links_grid->{$node1} = undef;
}
sub delete_link
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    @{$self->links} = grep { ! $_->involve($node1, $node2) } @{$self->links};
    $self->delete_references($node1, $node2);
}

sub delete_link_for_node
{
    my $self = shift;
    my $n1 = shift;
    @{$self->links} = grep { ! $_->has_node($n1) } @{$self->links};
    $self->delete_references_for_node($n1);
}
sub garbage_collector
{
    my $self = shift;
    my $query = shift;
    my @new = ();
    for(@{$self->links})
    {
        if(! $query->($_))
        {
            push @new, $_;
        }
        else
        {
            $self->delete_references($_->node1, $_->node2);
        }
    }
    @{$self->links} = @new;
}
sub links_for_node
{
    my $self = shift;
    my $node = shift;
    return $self->all() if(! $node);
    my @out = ();
    foreach my $k (keys %{$self->links_grid->{$node}})
    {
        if($k)
        {
            my $r = $self->links_grid->{$node}->{$k};
            push @out, $r if($r);
        }
    }
    return @out;
}
sub links_for_node1
{
    my $self = shift;
    my $node = shift;
    return $self->all() if(! $node);
    my @out = ();
    foreach my $r (@{$self->links})
    {
        if($r->bidirectional)
        {
            return $self->links_for_node($node);
        }
        if($r->node1 eq $node)
        {
            push @out, $r;
        }
    }
    return @out;
}
sub links_for_node2
{
    my $self = shift;
    my $node = shift;
    return $self->all() if(! $node);
    my @out = ();
    foreach my $r (@{$self->links})
    {
        if($r->bidirectional)
        {
            return $self->links_for_node($node);
        }
        if($r->node2 eq $node)
        {
            push @out, $r;
        }
    }
    return @out;
}
sub first_link_for_node
{
    my $self = shift;
    my $node = shift;
    foreach my $r (@{$self->links})
    {
        if($r->has_node($node))
        {
            return $r;
        }
    }
    return undef;
}
sub first_link_for_node1
{
    my $self = shift;
    my $node = shift;
    my @links = $self->links_for_node1($node);
    if(@links)
    {
        return $links[0]
    }
    else
    {
        return undef;
    }
}
sub first_link_for_node2
{
    my $self = shift;
    my $node = shift;
    my @links = $self->links_for_node2($node);
    if(@links)
    {
        return $links[0]
    }
    else
    {
        return undef;
    }
}

sub link_destinations_for_node
{
    my $self = shift;
    my $node1 = shift;
    my @out = ();
    for(keys %{$self->links_grid->{$node1}})
    {
        my $r = $self->links_grid->{$node1}->{$_};
        if($r)
        {
            push @out, $r->destination($node1);
        }
    }
    return @out;
}

sub query
{
    my $self = shift;
    my $query = shift;
    my $node1 = shift;
    my @out = ();
    for(@{$self->links})
    {
        if($query->($_))
        {
            if($node1)
            {
                if($_->has_node($node1))
                {
                    push @out, $_;
                }
            }
            else
            {
                push @out, $_;
            }
        }
    }
    return @out;
}
sub output_links
{
    my $self = shift;
    my $n = shift;
    my $mode = shift || 'print';
    if($mode eq 'print')
    {
        return $self->print_links($n);
    }
    elsif($mode eq 'html')
    {
        return $self->html_links($n);
    }
}

sub print_links
{
    my $self = shift;
    my $n = shift;
    my $out = "";
    foreach my $b (@{$self->links})
    {
        if($n)
        {
            if($b->has_node($n))
            {
                $out .= $b->print($n) . "\n";
            }
        }
        else
        {
            $out .= $b->print($n) . "\n";
        }
    }
    return $out;
}
sub html_links
{
    my $self = shift;
    my $n = shift;
    my $out = "";
    foreach my $b (@{$self->links})
    {
        if($n)
        {
            if($b->has_node($n))
            {
                $out .= $b->html($n) . "<br />";
            }
        }
        else
        {
            $out .= $b->html($n) . "<br />";
        }
    }
    return "<p>$out</p>";
}

#BFS implementation
sub distance
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    my $nodes_list = shift;
    my %nodes = $self->get_cached_nodes($node1, $nodes_list);
    my $log;
    if($nodes{$node2}->{distance} != -1)
    {
        return $nodes{$node2}->{distance};
    }
    if(my $cached_distance = $self->get_cached_distance($node2, $node1))
    {
      $nodes{$node2}->{distance} = $cached_distance;
      $self->distance_cache->{$node1}->{nodes} = \%nodes;
      return $cached_distance;
    }

    my @queue = ( $node1 );
    if(exists $self->distance_cache->{$node1}->{queue})
    {
        @queue = @{$self->distance_cache->{$node1}->{queue}};
    }
    while(@queue)
    {
        
        my $n = shift @queue;
        foreach my $near ($self->near($n, $nodes_list))
        {
            if($nodes{$near}->{distance} == -1)
            {
                my $d = $nodes{$n}->{distance} + 1;
                $nodes{$near}->{distance} = $nodes{$n}->{distance} + 1;
                push @queue, $near;
            }
        }
        if($nodes{$node2}->{distance} != -1)
        {
            $self->distance_cache->{$node1}->{nodes} = \%nodes;
            $self->distance_cache->{$node1}->{queue} = \@queue;
            return $nodes{$node2}->{distance};
        }
    }
    $nodes{$node2}->{distance} = 100;
    $self->distance_cache->{$node1}->{nodes} = \%nodes;
    $self->distance_cache->{$node1}->{queue} = \@queue;
    return 100;
}
sub get_cached_distance
{
    my $self = shift;
    my $node1 = shift;
    my $node2 = shift;
    if(exists $self->distance_cache->{$node1} &&
       exists $self->distance_cache->{$node1}->{$node2} &&
       $self->distance_cache->{$node1}->{$node2} != -1)
    {
        return $self->distance_cache->{$node1}->{$node2};
    }
    else
    {
        return undef;
    }
}
sub get_cached_nodes
{
    my $self = shift;
    my $node1 = shift;
    my $nodes_list = shift;
    my %nodes = ();
    if(exists $self->distance_cache->{$node1})
    {
        %nodes = %{$self->distance_cache->{$node1}->{nodes}};
    }
    else
    {
        foreach(@{$nodes_list})
        {
            $nodes{$_}->{distance} = -1;
        }
        $nodes{$node1}->{distance} = 0;
    }
    return %nodes;
}
sub near
{
    my $self = shift;
    my $node = shift;
    my $nodes = shift;
    return grep { $self->exists_link($node, $_) && $node ne $_ } @{$nodes};
}
sub dump
{
    my $self = shift;
    my $io = shift;
    my $indent = shift || "";
    foreach my $l (@{$self->links})
    {
        $l->dump($io, $indent);
    }
}
sub load_pack
{
    my $self = shift;
    my $class = shift;
    my $data = shift;
    $data .= "EOF\n";
    my @lines = split "\n", $data;
    load $class;
    my $rel_data = "";
    foreach my $l (@lines)
    {
        if($l !~ /^\s/)
        {
            if($rel_data)
            {
                my $rel = $class->load($rel_data);
                $self->add_link($rel);
            }
            $rel_data = $l . "\n";
        }
        else
        {
            $rel_data .= $l . "\n";
        }
    }
}

1;
