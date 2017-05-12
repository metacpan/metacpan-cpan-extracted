# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Row::Group;

use base 'Data::Tabular::Row';

sub group
{
    my $self = shift;
    $self->{group};
}

sub table
{
    my $self = shift;
    $self->{table};
}

sub get_column
{
    my $self = shift;
    my $column_name = shift;
    ref($self) . ' '. __PACKAGE__ . '::get_column ('. $column_name. ')';
}

1;
__END__

