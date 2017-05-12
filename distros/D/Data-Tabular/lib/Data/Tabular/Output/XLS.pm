# Copyright (C) 2003-2007, G. Allen Morris III, all rights reserved

use strict;

package Data::Tabular::Output::XLS;

our @CARP_NOT = qw (Data::Tabular Data::Tabular::Output);
use Carp qw (croak);

use base qw(Data::Tabular::Output);

sub new
{
    my $class = shift;
    my $args = { @_ };

    my $self = bless {}, $class;

    my $arg_list = {
        table => {required => 1},
        output => {},
        workbook => {required => 1},
	worksheet => {required => 1},
	row_offset => {},
	column_offset => {},
    };
    for my $arg (keys %$arg_list) {
        $self->{$arg} = $args->{$arg};
        croak "Need $arg" if $arg_list->{$arg}->{required} && !defined($self->{$arg});
	delete $args->{$arg};
    }

    if (my @x_list = keys %$args) {
        die 'Unknows arguments: ' . join(' ', sort @x_list);
    }

    $self->_render;

    $self;
}

sub workbook
{
    my $self = shift;
    $self->{workbook};
}

sub worksheet
{
    my $self = shift;
    $self->{worksheet};
}

sub row_offset
{
    my $self = shift;
    $self->{row_offset};
}

sub col_offset
{
    my $self = shift;
    $self->{col_offset};
}

sub _get_col_id
{
    my $self = shift;

    $self->output->col_id(shift);
}

sub _render
{
    my $self = shift;

    my $workbook = $self->workbook || croak 'need a workbook';
    my $worksheet = $self->worksheet || croak 'need a worksheet';

    my $row_offset = $self->row_offset;
    my $col_offset = $self->col_offset;

    my $pin_title = $self->output->test_xls_attribute('pin_title');

    my $format_default = $workbook->addformat(
	align => 'left',
	size => 8,
    );

    my $formats = {
        'right' => $workbook->addformat(
	    align => 'right',
	    text_wrap => 1,
	    bold => 1,
	),
	'left' => $workbook->addformat(
	    align => 'left',
	    text_wrap => 1,
	    bold => 1,
	),
    };

    my $output = $self->output;

    for my $column ($self->columns()) {
        my $col = $column->col_id;
	my $align = $column->align || undef;

	my $type = $self->output->type($column->name);
        my $width = undef;
	if ($type eq 'number') {
	    $align ||= 'right';
	} elsif ($type eq 'time') {
	    $width = 22;
	    $align ||= 'right';
	} elsif ($type eq 'date') {
	    $width = 12;
	    $align ||= 'right';
	}
        
	$worksheet->set_column($col, $col, undef, $formats->{$align});
    }

    my $types = {
        default => {
	    align => 'left',
	    size => 8,
	},
	month => {
	    num_format => 'mm/yyyy',
	    align => 'right',
	    size => 8,
	},
	time => {
	    num_format => 'mm/dd/yyyy hh:mm:ss am/pm',
	    align => 'right',
	    size => 8,
	},
	date => {
	    num_format => 'mm/dd/yyyy',
	    align => 'right',
	    size => 8,
	},
	dollar => {
	    num_format => '$#,##0.00_);[Red]($#,##0.00)',
	    align => 'right',
	    size => 8,
	},
	percent => {
	    num_format => '0.0%',
	    align => 'right',
	    size => 8,
	},
	number => {
	    num_format => '#,##0',
	    align => 'right',
	    size => 8,
	},
	text => {
	    align => 'left',
	    size => 8,
	},
    };
    for my $type (keys %{$types}) {
       $formats->{$type} =  $workbook->addformat(%{$types->{$type}});
       $formats->{$type . '_hdr'} =  $workbook->addformat(%{$types->{$type}}, bold => 1, text_wrap => 0);
    }
    $formats->{'title_right'} =  $workbook->addformat(align => 'right', size => 8, bold => 1, text_wrap => 1);
    $formats->{'title_left'} =  $workbook->addformat(align => 'left', size => 8, bold => 1, text_wrap => 1);
    $formats->{'title_center'} =  $workbook->addformat(align => 'center', size => 8, bold => 1, text_wrap => 1);
    $formats->{'averages_right'} =  $workbook->addformat(align => 'right', size => 8, bold => 1, text_wrap => 0);
    $formats->{'averages_left'} =  $workbook->addformat(align => 'left', size => 8, bold => 1, text_wrap => 0);
    $formats->{'averages_center'} =  $workbook->addformat(align => 'center', size => 8, bold => 1, text_wrap => 0);

    my $title_pinned = 0;

    for my $row ($self->rows()) {
        if ($row->is_title) {
	    if ($pin_title) {
	        next if $title_pinned;
		$title_pinned = 1;
	    }
	}
	for my $cell ($row->cells()) {
	    my ($y, $x) = ($cell->row_id, $cell->col_id);
	    my $data = $cell->data;
	    my $formula = '';
	    my $value = 'asdf';
	    eval {
		if (ref $data) {
		    $worksheet->write($y, $x, $data->string);
		} else {
		    $worksheet->write($y, $x, $data);
		}
	    };
	    if ($@) {
		die "$formula " . $@;
	    }
	}
    }
}

1;
__END__

=head1 NAME

Data::Tabular::Output::XLS

=head1 SYNOPSIS

This object is used by Data::Tabular to render a table.

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=over 4

=item new

Normally this object is constructed by the Data::Tabular::html method.

It requires 4 arguments: a table, an output object, a workbook object
and a worksheet object.

The workbook should be a part of the worksheet.

=back

=head1 METHODS

=over 4

=item workbook

  return the workbook

=item worksheet

  return the worksheet

=item col_offset

  return the column offset

=item row_offset

  return the row offset

=back

=head1 AUTHOR

"G. Allen Morris III" <gam3@gam3.net>

=head1 SEE ALSO

L<Spreadsheet::WriteExcel>

=cut

my $cell_type = $type;
    if ($row->hdr) {
	$cell_type .= '_hdr';
    }
    if ($row->type eq 'title') {
	$cell_type = $cell->title_format;
    } elsif ($row->type eq 'averages') {
	$type = 'text';
	$cell_type = 'averages_right';
    } elsif ($row->type eq 'header') {
    } elsif ($row->type eq 'totals') {
	if (ref($cell_data)) {
	    $type = 'formula';
	    $cell_type = $self->output->type($cell->name);
	}
    } else {
	$type = $self->output->type($cell->name);
    }
next unless $cell_data;
    my $format = undef;

    if (ref($cell_data)) {
# FIXME
	$type = 'formula';
    }

    if ($type eq 'date') {
	if ($cell_data) {
	    $worksheet->write_date_time($y, $x, $cell_data, $formats->{'date'});
	    $worksheet->set_column($x, $x, 20);
	}
    } elsif ($type eq 'time') {
	if ($cell_data) {
	    $worksheet->write_date_time($y, $x, $cell_data, $formats->{'time'});
	    $worksheet->set_column($x, $x, 23);
	}
    } elsif ($type eq 'month') {
	my $date_data = $cell_data;
	if ($cell_data) {
	    $worksheet->write_number($y, $x, $cell_data, $formats->{$cell_type});
	}
    } elsif ($type eq 'text') {
	$worksheet->write_string($y, $x, $cell_data, $formats->{$cell_type});
    } elsif ($type eq 'dollar') {
	$worksheet->write_number($y, $x, $cell_data, $formats->{'dollar'});
    } elsif ($type eq 'number') {
	$worksheet->write_number($y, $x, $cell_data, $formats->{$cell_type});
    } elsif ($type eq 'percent') {
	$worksheet->write_number($y, $x, $cell_data, $formats->{$cell_type});
    } elsif ($type eq 'formula') {
	my $formula = '=';
	if ($cell_data->{type} eq 'sum') {
	    if (!defined $cell_data->{rows}) {
		$formula .= join('+', map({ my $x = $self->_get_col_id($_); chr(0x41+$x) . ($cell->row_id+1); } @{$cell_data->{columns}}));
	    } else {
		$formula .= join('+', map({ chr(0x41+$cell->col_id) . $_; } @{$cell_data->{rows}}));
	    }
	} elsif ($cell_data->{type} eq 'average' || $cell_data->{type} eq 'avg') {
	    $formula .= '(';
	    if (!defined $cell_data->{rows}) {
		$formula .= join('+', map({ my $x = $self->_get_col_id($_); chr(0x41+$x) . ($cell->row_id+1); } @{$cell_data->{columns}}));
	    } else {
		$formula .= join('+', map({ chr(0x41+$cell->col_id) . $_; } @{$cell_data->{rows}}));
	    }
	    $formula .= ')';
	    $formula .= "/" . scalar(@{$cell_data->{rows} || $cell_data->{columns}});
	} else {
	    warn $cell_data->{type};
	}

	$formula = '';
	$formula .= '';
	my $value = $cell_data->{html};
