# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Row::Titles;

use base 'Data::Tabular::Row';

sub get_column
{
    my $self = shift;
    my $key = shift || die 'need column name';

    my $output = $self->output;

    Data::Tabular::Type->new(
	data => $output->title($key),
	format => $output->format('_title', $key),
    );
}

1;
__END__

