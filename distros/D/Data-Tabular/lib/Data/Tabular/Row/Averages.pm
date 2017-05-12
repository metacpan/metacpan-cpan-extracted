# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Row::Averages;

use base 'Data::Tabular::Row::Function';

use Carp qw(croak carp);

sub get_column
{
    my $self = shift;
    my $column_name = shift;
    my $ret;
    my $reg = qr|^$column_name$|;

    if ($column_name eq '_description') {
	$ret = Data::Tabular::Type::Number->new(
	    data => $self->{text},
	    type => 'description',
	);
    } elsif (grep(m|$reg|, @{$self->sum_list})) {
        $ret = $self->table->column_average($column_name);
    } elsif (grep(m|$reg|, @{$self->{extra}->{headers} || []})) {
die 'extra';
	$ret = "extra($column_name)";
    } elsif ($column_name eq '_filler') {
	$ret = Data::Tabular::Type::Number->new(
	    data => '',
	    type => 'filler',
	);
    } else {
        $ret = 'N/A('. $column_name . ')';
    }

    return $ret;
}

1;
__END__

