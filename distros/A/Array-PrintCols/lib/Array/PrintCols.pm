# Array::PrintCols.pm
#
#    Copyright (C) 1996-2014  Alan K. Stebbens <aks@stebbens.org>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Author: Alan K. Stebbens <aks@stebbens.org>
#

package Array::PrintCols;

$VERSION = '2.6';

require 5.001;

use Exporter; 
@ISA = (Exporter);
@EXPORT = qw( print_cols format_cols );

use Carp;

sub min(@);
sub max(@);

$PreSorted = 1;			# if set, do not need to sort

# If users need to, they can set this variable externally:
#
# $Array::PrintCols::PreSorted = 0;
#
#
# format_cols \@array [, $col_width [, $total_width [, $indent ] ] ]
#
# or
#
# format_cols \@array [, -$columns [, $total_width, [, $indent ] ] ]
#
# or
#
# format_cols \%hash [, -$columns [, $total_width, [, $indent ] ] ]
#
#
# This used to be "print_cols", which always sent everything to STDOUT.
# Now, the work is done in "format_cols", which returns a string result.
# Thanks to Gisle Aas <aas@bergen.sn.no> for the suggestion)
#
# Routine to format an array of values in alphabetically vertically 
# sorted columns. 

sub format_cols($;@) {
    my($array)       = shift;
    $array = $$array if ref($array) eq 'REF';
    $array = [sort(keys(%$array))] if ref($array) eq 'HASH';
    ref($array) eq 'ARRAY' or croak "arg 1 must be an ARRAY, HASH, or ARRAYREF\n";
    my($col_width)   = shift || 0;
    my($total_width) = shift || $ENV{'COLUMNS'} || 80;
    my($indent)      = shift || 0;

    my($key,$max_len,$cols,$fmt,$col,$rows,$row);

    my $o = '';		# start of the output

    # calculate the maximum item length
    $max_len = max (map length, @$array) + 1;

    # Calculate maximum possible # of columns
    $cols = max 1, int(($total_width - $indent) / $max_len);

    # Now adjust the $cols based on $col_width
    if ($col_width < 0) {		# given as -$columns?
	if (-$col_width <= $cols) {	# is the value possible?
	    $cols = -$col_width;	# yes, set # of columns
	}
	# calculate the new maximum column width
	$col_width = min $max_len, int(($total_width - $indent) / $cols);
    } elsif ($col_width >= 0) {		# $col_width given?
	# get maximum of $max_len, $col_width
	$col_width = max $col_width, $max_len, 1;
	$cols = max 1, int(($total_width - $indent) / $col_width);
    }

    $rows = int(($#$array + $cols) / $cols);
    $fmt = sprintf("%%-%ds ",$col_width - 1);

    $array = [sort @$array] unless $PreSorted;	# sort if necessary
    for ($row = 0; $row < $rows; $row++) {
	$o .= ' ' x $indent if $indent > 0;
	for ($col = $row; $col <= $#$array; $col += $rows) {
	    $o .= sprintf $fmt,$array->[$col];
	}
	$o .= "\n";
    }
    $o;
}

# print_cols -- just print the results of format_cols.

sub print_cols($;@) { 
   my $aref = shift;
   print format_cols($aref,@_);
}

sub min(@) { 
    my($min) = shift;
    local($_);
    foreach (@_) { $min = $_ if $min > $_; }
    $min;
}

sub max(@) {
    my($max) = shift;
    local($_);
    foreach (@_) { $max = $_ if $max < $_; }
    $max;
}

1;

__END__

=head1 NAME

Array::PrintCols - Print or format array elements in vertically sorted columns.

=head1 SYNOPSIS

C<use Array::PrintCols;>

C<print_cols \@I<array>;>

C<print_cols \@I<array>, $I<colspec>;>

C<print_cols \@I<array>, $I<colspec>, $I<total_width>;>

C<print_cols \@I<array>, $I<colspec>, $I<total_width>, $I<indent>;>

	     \@I<array> may also be an ARRAYREF, HASH, or HASHREF.

$I<output> = C<format_cols> <same arguments as C<print_cols>>;


C<$Array::PrintCols::PreSorted = 0;>

=head1 DESCRIPTION

This module exports two subroutine names: C<print_cols> and
C<format_cols>.

The C<print_cols> subroutine prints the items of C<@I<array>> in
multiple, alphabetically & vertically sorted columns.  In the case
of the first argument being a HASH or HASHREF, only the keys of
the hash are considered.

One, two, or three optional arguments may be given to
C<print_cols> to control the width and number of the columns, the
total width of the output, and indentation.  Reasonable defaults
apply in the absence of the optional arguments (or when given as
the empty string or zero).  Generally, the minimum width column is
used when possible.

If C<$I<colspec>> is given as a non-negative number, it is treated
as the minimum width of the column; the actual width will be the
maximum of this value and the lengths of all array items.

If C<$I<colspec>> is given as a negative number, its absolute
value value is used to determine the total number of columns.
However, it cannot exceed the total number of columns possible
based on the maximum length of all the array elements.

If a third argument is supplied, it is used as the total width of
the output.  The default for this value is the value of the
environment variable C<$ENV{'COLUMNS'}>, if defined, or 80.

If the fourth argument is given, it is used as the indent for all
lines printed, which subtracts from the total width of the output.
This value defaults to zero (ie: no indention of the output).

The variable C<$Array::PrintCols::PreSorted> controls whether or
not the C<print_cols> subroutine will expect its array argument to
already be sorted.  If this variable is nil or zero, C<print_cols>
will cause print out a sorted I<copy> of the input array.

The routine C<format_cols> is called exactly like C<print_cols>
but returns the formatted result as a string, rather than printing
it.  C<print_cols> actually invokes C<format_cols>, which does 
the real work.

=head1 EXAMPLES

    use Array::PrintCols;

    @commands = sort qw( use list put get set quit help server );

    # print in three columns with an indention of 1.
    print_cols \@commands, -3, 0, 1;

    # print the formatted result data to the result file
    print RESULTFILE format_cols(\@result_data);

=head1 REPOSITORY

L<https://github.com/aks/array-printcols>

=head1 AUTHOR

Copyright (C) 1996-2014  Alan K. Stebbens <aks@stebbens.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 BUGS

Perl will not default intervening empty arguments; instead, use zero or the
empty-string ('').
