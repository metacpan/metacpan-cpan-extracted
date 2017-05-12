# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Column;

use Carp qw(croak);

sub new
{
    my $class = shift;
    my $self = bless({ @_ }, $class);

    croak "no name" unless $self->{name};

    $self;
}

sub name
{
    my $self = shift;
    my $name = $self->{name};
    return $name;
}

sub align
{
    my $self = shift;
    my $output = $self->{output};

    ' align="right"';
}

sub colgroup_attribute
{
}

sub col_id 
{
    my $self = shift;
    $self->{offset};
}

1;
__END__

