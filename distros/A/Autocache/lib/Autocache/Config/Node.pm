package Autocache::Config::Node;

use strict;
use warnings;

use Autocache::Logger qw(get_logger);

sub new
{
    my ($class,$name) = @_;
    my $self = { name => $name, value => undef, child => {} };
    return bless $self, $class;
}

sub name
{
    my ($self) = @_;
    return $self->{name};
}

sub value
{
    my ($self,$value) = @_;
    my $rv;
    if( $value )
    {
        $rv = $self->{value};
        $self->{value} = $value;;
    }
    else
    {
        $rv = $self->{value};
    }
    return $rv;
}

sub children_names
{
    my ($self) = @_;
    return keys %{$self->{child}};
}

sub children
{
    my ($self) = @_;
    return values %{$self->{child}};
}

sub add_child
{
    my ($self,$node) = @_;
    return $self->{child}{$node->name} = $node;
}

sub remove_child
{
    my ($self,$node_or_name) = @_;
    $node_or_name = $node_or_name->name
        if blessed $node_or_name;
    return delete $self->{child}{$node_or_name};
}

sub get_node
{
    my ($self,$path) = @_;
    get_logger()->debug( "get_node: $path" );
    my ($name,$rest) = split /\./, $path, 2;

    my $node = $self->{child}{$name};

    unless( $node )
    {
        $node = __PACKAGE__->new( $name );
        $self->{child}{$name} = $node;
    }

    return ( defined $rest ) ?
        $node->get_node( $rest ) : $node;
}

sub node_exists
{
    my ($self,$path) = @_;
    get_logger()->debug( "node_exists: $path" );
    my ($name,$rest) = split /\./, $path, 2;

    return undef unless exists $self->{child}{$name};

    my $node = $self->{child}{$name};

    return ( defined $rest ) ?
        $node->node_exists( $rest ) : $node;
}

sub to_hash
{
    my ($self) = @_;

    my @children = $self->children;
    if( scalar @children )
    {
        my %hash;
        foreach my $child ( $self->children )
        {
            $hash{$child->name} = $child->to_hash;
        }
        $hash{_value} = $self->value;
        return \%hash;
    }
    else
    {
        return $self->value;
    }
}

1;
