


package DataCube::CubeStore;

use strict;
use warnings;

sub new {
    my($class,%opts) = @_;
    bless {%opts}, ref($class) || $class;
}

sub cube_names {
    my($self) = @_;
    sort keys %{$self->{cubes}};
}

sub fetch {
    my($self,$cube_name) = @_;
    return $self->{cubes}->{$cube_name};
}

sub cubes {
    my($self) = @_;
    return $self->{cubes};
}

sub tables {
    my($self) = @_;
    return $self->{cubes};
}

sub add_cube {
    my($self,$cube) = @_;
    $self->{cubes}->{$cube->{schema}->{name}} = $cube;
    return $self;
}




1;






