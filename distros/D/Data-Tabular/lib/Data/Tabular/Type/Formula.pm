use strict;

package 
    Data::Tabular::Type::Formula;

use base 'Data::Tabular::Type';

sub data
{
    my $self = shift;

    $self->{data};
}

1;
