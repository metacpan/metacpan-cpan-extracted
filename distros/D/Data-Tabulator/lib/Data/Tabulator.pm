package Data::Tabulator;

use warnings;
use strict;

=head1 NAME

Data::Tabulator - Create a table (two-dimensional array) from a list (one-dimensional array)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    my $table = Data::Tabulator->new([ 'a' .. 'z' ], rows => 6);
    my $rows = $table->rows;
    # Returns a the following two-dimensional array:
    # [ 
    #  [ qw/ a b c d e / ],
    #  [ qw/ f g h i j / ],
    #  [ qw/ k l m n o / ],
    #  [ qw/ p q r s t / ],
    #  [ qw/ u v w x y / ],
    #  [ qw/ z/ ],
    # ]

    my $columns = $table->columns;
    # Returns a the following two-dimensional array:
    # [ 
    #  [ qw/ a f k p u z / ],
    #  [ qw/ b g l q v / ],
    #  [ qw/ c h m r w / ],
    #  [ qw/ d i n s x / ],
    #  [ qw/ e j o t y / ],
    # ]

=head1 DESCRIPTION

Data::Tabulator is a simple and straightforward module for generating a table from an array.
It can properly handle data that is in either row- or column-major order.

=cut

use POSIX qw/ceil/;
use Sub::Exporter -setup => {
	exports => [
        rows => sub { \&_rows },
        columns => sub { \&_columns },
    ],
};

use Scalar::Util qw/blessed/;

use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/_data _row_count _column_count
    _overlap _ready _row_accessor _column_accessor/);
__PACKAGE__->mk_accessors(qw/pad padding row_major column_major/);

sub _rows {
    my $data = shift;
    return __PACKAGE__->new(data => $data, @_)->rows;
}

sub _columns {
    my $data = shift;
    return __PACKAGE__->new(data => $data, @_)->columns;
}

=head1 EXPORTS

=over 4

=item rows( <array>, ... )

=item rows( data => <array>, ... )

Extracts and returns the rows of the array.

A shortcut to ->new, see Data::Tabulator->new for parameter specification and more information.

=item columns( <array>, ... )

=item columns( data => <array>, ... )

Extracts and returns the columns of the array.

A shortcut to ->new, see Data::Tabulator->new for parameter specification and more information.

=back

=head1 METHODS

=over 4

=item Data::Tabulator->new( <array>, ... )

=item Data::Tabulator->new( data => <array>, ... )

The first argument to new may be an array (a list reference).
Alternatively, you can pass in the array via the "data" parameter.

The following parameters are also accepted:

=over 4

data => The array (list reference) to turn into a table.

rows => The number of rows the table should have.

columns => The number of columns the table should have.

pad => A true/false indicator on whether to pad if the array is not long enough. The default is not to pad.

padding => The padding data to use if the array is not long enough (not a full M x N table). The default is undef.

row_major => A true value indicates that the array data is in row-major order. This is the default.

column_major => A true value indicates that the array data is in column-major order.
    
=back

Note: passing in "padding" and not specifying the "pad" option will automatically turn "pad" on.

=cut

sub new {
    my $self = bless {}, shift;
    my $data = shift if ref $_[0] eq "ARRAY";
    local %_ = @_;

    $self->data($data || $_{data});
    $self->_row_count($_{rows} || $_{row_count});
    $self->_column_count($_{columns} || $_{column_count});
    $self->pad($_{pad} || ! exists $_{pad} && exists $_{padding});
    $self->padding($_{padding});
    $self->row_major($_{row_major});
    $self->column_major($_{column_major});
    $self->row_major(1) unless $self->column_major;

    $self->_overlap($_{overlap} || 0);
    $self->_ready(0);

    return $self;
}

sub _minor_accessor($$$$$$$) {
    my ($major_offset, $major_count, $minor_count, $minor_index, $data, $padder, $pad) = @_;

    return () if $minor_index >= $minor_count || $minor_index < 0;
    
    my $no_pad = ! $pad;
    my $data_size = @$data;
    my @minor;
    my $index = $minor_index;

    for (my $major_index = 0; $major_index < $major_count; $major_index++) {
        push(@minor, $index < $data_size ? $data->[$index] : ($no_pad ? () : $padder));
        $index += $major_offset;
    }

    return \@minor;
}

sub _major_accessor($$$$$$$) {
    my ($major_offset, $major_count, $minor_count, $major_index, $data, $padder, $pad) = @_;
    
    return () if $major_index >= $major_count || $major_index < 0;

    my $no_pad = ! $pad;
    my $data_size = @$data;
    my ($start, $end, $padding);

    $start = $major_offset * $major_index;
    $end = $major_offset * $major_index + $minor_count - 1;
    $end = $start if $end < $start;
    if ($end >= $data_size) {
        $padding = ($end - $data_size) + 1;
        $end = $data_size - 1;
    }
    return () if $start >= $data_size;

    return [ @$data[$start .. $end], 
             (!$no_pad) && $padding ? (($padder) x $padding) : () ];
}

#    if ($row_count) {
#        if ($data_size < $row_count) {
#            $row_count = $data_size;
#            $column_count = 1;
#            $column_offset = 0;
#        }
#        else {
#            $column_offset = $row_count - $overlap;
#            $column_count = int ($data_size / $column_offset) 
#                + ($data_size % $column_offset > $overlap ? 1 : 0)
#        }
#    }
#    elsif ($column_count) {
#        if ($data_size < $column_count) {
#            $column_count = $data_size;
#            $row_count = 1;
#            $column_offset = 1;
#        }
#        else {
#            $column_offset = int ($data_size / $column_count) 
#                + ($data_size % $column_count > $overlap ? 1 : 0);
#            $row_count = $column_offset + $overlap;
#        }
#    }

sub _calculate {
    my $self = shift;

    my $data = $self->data;
    my $data_size = @$data;
    my $row_count = $self->_row_count;
    my $column_count = $self->_column_count;
    my $padding = $self->padding;
    my $pad = $self->pad;
    my $row_major = $self->row_major;
    my $column_major = $self->column_major;

    my ($row_offset, $column_offset);

    if ($column_major) {
        if ($row_count) {
            if ($data_size < $row_count) {
                $row_count = $data_size;
                $column_count = 1;
                $column_offset = 0;
            }
            else {
                $column_offset = $row_count;
                $column_count = ceil($data_size / $column_offset);
#               $column_count = int ($data_size / $column_offset) +
#                   ($data_size % $column_offset ? 1 : 0);
            }
        }
        elsif ($column_count) {
            if ($data_size < $column_count) {
                $column_count = $data_size;
                $row_count = 1;
                $column_offset = 1;
            }
            else {
                $column_offset = ceil($data_size / $column_count);
#               $column_offset = int ($data_size / $column_count) +
#                   ($data_size % $column_count ? 1 : 0);
                $row_count = $column_offset;
            }
        }
        else {
            $row_count = $data_size;
            $column_count = 1;
            $column_offset = 0;
        }
        $self->_row_accessor(sub {
            return _minor_accessor($column_offset, $column_count, $row_count, shift, $data, $padding, $pad);
        });
        $self->_column_accessor(sub {
            return _major_accessor($column_offset, $column_count, $row_count, shift, $data, $padding, $pad);
        });
    }
    else { # Assume row major
        if ($column_count) {
            if ($data_size < $column_count) {
                $column_count = $data_size;
                $row_count = 1;
                $row_offset = 0;
            }
            else {
                $row_offset = $column_count;
                $row_count = ceil($data_size / $row_offset);
            }
        }
        elsif ($row_count) {
            if ($data_size < $row_count) {
                $row_count = $data_size;
                $column_count = 1;
                $row_offset = 1;
            }
            else {
                $row_offset = ceil($data_size / $row_count);
                $column_count = $row_offset;
            }
        }
        else {
            $column_count = $data_size;
            $row_count = 1;
            $row_offset = 0;
        }
        $self->_row_accessor(sub {
            return _major_accessor($row_offset, $row_count, $column_count, shift, $data, $padding, $pad);
        });
        $self->_column_accessor(sub {
            return _minor_accessor($row_offset, $row_count, $column_count, shift, $data, $padding, $pad);
        });
    }

    $self->_row_count($row_count);
    $self->_column_count($column_count);
    # $self->_column_offset($column_offset);
    $self->_reset;

    return ($row_count, $column_count);
}

=item $table->data

=item $table->data( <array> )

Return a reference to the underlying array of the table.

Alternatively, make $table use the specified <array>.

When setting $table->data, make sure you're passing in a list reference.

=cut

sub data {
    my $self = shift;
    if (@_) {
        $self->_data(shift);
        $self->_reset;
    }
    return $self->_data;
}

=item $table->width

Return the width of the table (the number of columns).

=cut

sub width {
    my $self = shift;
    $self->_calculate unless $self->_ready;
    return ($self->_column_count)
}

=item $table->height

Return the height of the table (the number of rows).

=cut

sub height {
    my $self = shift;
    $self->_calculate unless $self->_ready;
    return ($self->_row_count)
}

=item $table->dimensions

=item $table->geometry

Return the width and height of the table.

In scalar context, this will return a two-element array.

    my ($width, $height) = $table->geometry;
    my $geometry = $table->geometry;
    $width = $geometry->[0];
    $height = $geometry->[1];

=cut

sub dimensions {
    my $self = shift;
    return wantarray ? ($self->width, $self->height) : [$self->width, $self->height];
}
*geometry = \&dimensions;

=item $table->pad( <indicator> )

Toggle padding on/off.

=item $table->padding( <padding> )

Set the padding data to use.

=item $table->row_major

Return true if the data for $table is in row-major order.

=item $table->column_major

Return true if the data for $table is in column-major order.

=item $table->rows

Return an array of rows in the table.

=item $table->rows( <count> )

Set the number of rows in the table to <count>. This is equivalent to passing in row_count to the new method.
As a side effect, this will change the number of columns in table.

Does not return anything.

=cut

sub rows {
    my $self = shift;
    if (@_) {
        return _rows(@_) unless blessed $self;
        $self->_row_count(shift);
        $self->_reset;
    }
    else {
        $self->_calculate unless $self->_ready;

        my $row_count = $self->_row_count;

        return [ map { $self->row($_) } (0 .. $row_count - 1) ];
    }
}

=item $table->columns

Return an array of columns in the table.

=item $table->columns( <count> )

Set the number of columns in the table to <count>. This is equivalent to passing in column_count to the new method.
As a side effect, this will change the number of rows in table.

Does not return anything.

=cut

sub columns {
    my $self = shift;
    if (@_) {
        return _columns(@_) unless blessed $self;
        $self->_column_count(shift);
        $self->_reset;
    }
    else {
        $self->_calculate unless $self->_ready;

        my $column_count = $self->_column_count;

        return [ map { $self->column($_) } (0 .. $column_count - 1) ];
    }
}

sub _reset {
    my $self = shift;
    $self->_ready(0);
}

=item $table->row( <i> )

Return row <i>

<i> should be a number from 0 to $tables->rows - 1

=cut

sub row {
    my $self = shift;
    my $row = shift;

    $self->_calculate unless $self->_ready;

    return $self->_row_accessor->($row);
}

=item $table->column( <j> )

Return column <j>

<j> should be a number from 0 to $tables->columns - 1

=cut

sub column {
    my $self = shift;
    my $column = shift;

    $self->_calculate unless $self->_ready;

    return $self->_column_accessor->($column);
}

=item $table->as_string( [<row-separator>], [<column-separator>] )

Return the table as a simple string.

By default, rows are separated by "\n" and columns are separated by " ".

=cut

sub as_string {
    my $self = shift;
    my $row_separator = shift;
    my $column_separator = shift;
    $row_separator = "\n" unless defined $row_separator;
    $column_separator = " " unless defined $column_separator;
    return join $row_separator, map { join $column_separator, @$_ } @{ $self->rows };
}

=back

=head1 SEE ALSO

Data::Tabulate, Data::Table 

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-tabulate at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Tabulator>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Tabulator

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Tabulator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Tabulator>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Tabulator>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Tabulator>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::Tabulator
