# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;
package
    Data::Tabular::Row::Totals;

use base 'Data::Tabular::Row::Function';

sub get_column
{
    my $self = shift;
    my $column_name = shift;
    my $ret;
    my $reg = qr|^$column_name$|;

    if ($column_name eq '_description') {
        $ret = Data::Tabular::Type::Text->new(
            data => $self->{text},
            type => 'description',
	);
    } elsif (grep(m|$reg|, @{$self->sum_list})) {
        $ret = $self->table->column_sum($column_name);
    } elsif (grep(m|$reg|, @{$self->{extra}->{headers} || []})) {
die;
	$ret = "extra($column_name)";
    } elsif ($column_name eq '_filler') {
        $ret = undef;
        $ret = Data::Tabular::Type::Text->new(
            data => '',
            type => 'filler',
	);
    } else {
        $ret = 'N/A('. $column_name . ')';
    }
    $ret;
}

1;
__END__

