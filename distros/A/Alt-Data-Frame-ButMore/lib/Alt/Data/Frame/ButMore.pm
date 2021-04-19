package Alt::Data::Frame::ButMore;

# ABSTRACT: Alternative implementation of Data::Frame with more features

use strict;
use warnings;

our $VERSION = '0.0056'; # VERSION

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alt::Data::Frame::ButMore - Alternative implementation of Data::Frame with more features

=head1 VERSION

version 0.0056

=head1 STATUS

This library is currently experimental.

=head1 SYNOPSIS

    use Alt::Data::Frame::ButMore;
    use Data::Frame;
    use PDL;

    my $df = Data::Frame->new(
            columns => [
                z => pdl(1, 2, 3, 4),
                y => ( sequence(4) >= 2 ) ,
                x => [ qw/foo bar baz quux/ ],
            ] );
    say $df;
    # ---------------
    #     z  y  x
    # ---------------
    #  0  1  0  foo
    #  1  2  0  bar
    #  2  3  1  baz
    #  3  4  1  quux
    # ---------------

    say $df->at(0);         # [1 2 3 4]
    say $df->at(0)->length; # 4
    say $df->at('x');       # [1 2 3 4]

    say $df->select_rows( 3,1 );
    # ---------------
    #     z  y  x
    # ---------------
    #  3  4  1  quux
    #  1  2  0  bar
    # ---------------

    $df->slice( [0,1], ['z', 'y'] ) .= pdl( 4,3,2,1 );
    say $df;
    # ---------------
    #     z  y  x
    # ---------------
    #  0  4  2  foo
    #  1  3  1  bar
    #  2  3  1  baz
    #  3  4  1  quux
    # ---------------

=head1 DESCRIPTION

It's been too long I cannot reach ZMUGHAL.
So here I release my L<Alt> implenmentation.

This implements a data frame container that uses L<PDL> for individual columns.
As such, it supports marking missing values (C<BAD> values).

=head2 Document Conventions

Function signatures in docs of this library follow the
L<Function::Parameters> conventions, for example,

    myfunc(Type1 $positional_parameter, Type2 :$named_parameter)

=head1 CONSTRUCTION

    new( (ArrayRef | HashRef) :$columns,
         ArrayRef :$row_names=undef )

Creates a new C<Data::Frame> when passed the following options as a
specification of the columns to add:

=over 4

=item * columns => ArrayRef $columns_array

When C<columns> is passed an C<ArrayRef> of pairs of the form

    $columns_array = [
        column_name_z => $column_01_data, # first column data
        column_name_y => $column_02_data, # second column data
        column_name_x => $column_03_data, # third column data
    ]

then the column data is added to the data frame in the order that the pairs
appear in the C<ArrayRef>.

=item * columns => HashRef $columns_hash

    $columns_hash = {
        column_name_z => $column_03_data, # third column data
        column_name_y => $column_02_data, # second column data
        column_name_x => $column_01_data, # first column data
    }

then the column data is added to the data frame by the order of the keys in the
C<HashRef> (sorted with a stringwise C<cmp>).

=item * row_names => ArrayRef $row_names

=back

=head1 METHODS / BASIC

=head2 string

    string() # returns Str

Returns a string representation of the C<Data::Frame>.

=head2 ncol / length / number_of_columns

These methods are same,

    # returns Int
    ncol()
    length()
    number_of_columns() # returns Int

Returns the count of the number of columns in the C<Data::Frame>.

=head2 nrow / number_of_rows

These methods are same,

    # returns Int
    nrow()
    number_of_rows() # returns Int

Returns the count of the number of rows in the C<Data::Frame>.

=head2 dims

    dims()

Returns the dimensions of the data frame object, in an array of
C<($nrow, $ncol)>.

=head2 shape

    shape()

Similar to C<dims> but returns a piddle.

=head2 at

    my $column_piddle = $df->at($column_indexer);
    my $cell_value = $df->at($row_indexer, $column_indexer);

If only one argument is given, it would treat the argument as column
indexer to get the column.
If two arguments are given, it would treat the arguments for row
indexer and column indexer respectively to get the cell value.

If a given argument is non-indexer, it would try guessing whether the
argument is numeric or not, and coerce it by either C<indexer_s()> or
C<indexer_i()>.

=head2 exists

    exists($col_name)

Returns true if there exists a column named C<$col_name> in the data frame
object, false otherwise.

=head2 delete

    delete($col_name)

In-place delete column given by C<$col_name>.

=head2 rename

    rename($hashref_or_coderef)

In-place rename columns.

It can take either,

=over 4

=item *

A hashref of key mappings.

If a keys does not exist in the mappings, it would not be renamed.

=item *

A coderef which transforms each key.

=back

    $df->rename( { $from_key => $to_key, ... } );
    $df->rename( sub { $_[0] . 'foo' } );

=head2 set

    set(Indexer $col_name, ColumnLike $data)

Sets data to column. If C<$col_name> does not exist, it would add a new column.

=head2 isempty

    isempty()

Returns true if the data frame has no rows.

=head2 names / col_names / column_names

These methods are same

    # returns ArrayRef
    names()
    names( $new_column_names )
    names( @new_column_names )

    col_names()
    col_names( $new_column_names )
    col_names( @new_column_names )

    column_names()
    column_names( $new_column_names )
    column_names( @new_column_names )

Returns an C<ArrayRef> of the names of the columns.

If passed a list of arguments C<@new_column_names>, then the columns will be
renamed to the elements of C<@new_column_names>. The length of the argument
must match the number of columns in the C<Data::Frame>.

=head2 row_names

    # returns a PDL::SV
    row_names()
    row_names( Array @new_row_names )
    row_names( ArrayRef $new_row_names )
    row_names( PDL $new_row_names )

Returns an C<PDL::SV> of the names of the rows.

If passed a argument, then the rows will be renamed. The length of the argument
must match the number of rows in the C<Data::Frame>.

=head2 column

    column( Str $column_name )

Returns the column with the name C<$column_name>.

=head2 nth_column

    number_of_rows(Int $n) # returns a column

Returns column number C<$n>. Supports negative indices (e.g., $n = -1 returns
the last column).

=head2 add_columns

    add_columns( Array @column_pairlist )

Adds all the columns in C<@column_pairlist> to the C<Data::Frame>.

=head2 add_column

    add_column(Str $name, $data)

Adds a single column to the C<Data::Frame> with the name C<$name> and data
C<$data>.

=head2 copy / clone

These methods are same,

    copy()
    clone()

Make a deep copy of this data frame object.

=head2 summary

    summary($percentiles=[0.25, 0.75])

Generate descriptive statistics that summarize the central tendency,
dispersion and shape of a dataset’s distribution, excluding C<BAD> values.

Analyzes numeric datetime columns only. For other column types like
C<PDL::SV> and C<PDL::Factor> gets only good value count.
Returns a data frame of the summarized statistics.

Parameters:

=over 4

=item *

$percentiles

The percentiles to include in the output. All should fall between 0 and 1.
The default is C<[.25, .75]>, which returns the 25th, 50th, and 75th
percentiles (median is always automatically included).

=back

=head1 METHODS / SELECTING AND INDEXING

=head2 select_columns

    select_columns($indexer)

Returns a new data frame object which has the columns selected by C<$indexer>.

If a given argument is non-indexer, it would coerce it by C<indexer_s()>.

=head2 select_rows

    select_rows( Indexer $indexer)

    # below types would be coerced to Indexer
    select_rows( Array @which )
    select_rows( ArrayRef $which )
    select_rows( Piddle $which )

The argument C<$indexer> is an "Indexer", as defined in L<Data::Frame::Types>.
C<select_rows> returns a new C<Data::Frame> that contains rows that match
the indices specified by C<$indexer>.

This C<Data::Frame> supports PDL's data flow, meaning that changes to the
values in the child data frame columns will appear in the parent data frame.

If no indices are given, a C<Data::Frame> with no rows is returned.

=head2 head

    head( Int $n=6 )

If $n ≥ 0, returns a new C<Data::Frame> with the first $n rows of the
C<Data::Frame>.

If $n < 0, returns a new C<Data::Frame> with all but the last -$n rows of the
C<Data::Frame>.

See also: R's L<head|https://stat.ethz.ch/R-manual/R-devel/library/utils/html/head.html> function.

=head2 tail

    tail( Int $n=6 )

If $n ≥ 0, returns a new C<Data::Frame> with the last $n rows of the
C<Data::Frame>.

If $n < 0, returns a new C<Data::Frame> with all but the first -$n rows of the
C<Data::Frame>.

See also: R's L<tail|https://stat.ethz.ch/R-manual/R-devel/library/utils/html/head.html> function.

=head2 slice

    my $subset1 = $df->slice($row_indexer, $column_indexer);

    # Note that below two cases are different.
    my $subset2 = $df->slice($column_indexer);
    my $subset3 = $df->slice($row_indexer, undef);

Returns a new dataframe object which is a slice of the raw data frame.

This method returns an lvalue which allows PDL-like C<.=> assignment for
changing a subset of the raw data frame. For example,

    $df->slice($row_indexer, $column_indexer) .= $another_df;
    $df->slice($row_indexer, $column_indexer) .= $piddle;

If a given argument is non-indexer, it would try guessing if the argument
is numeric or not, and coerce it by either C<indexer_s()> or C<indexer_i()>.

=head2 sample

    sample($n)

Get a random sample of rows from the data frame object, as a new data frame.

    my $sample_df = $df->sample(100);

=head2 which

    which(:$bad_to_val=undef, :$ignore_both_bad=true)

Returns a pdl of C<[[col_idx, row_idx], ...]>, like the output of
L<PDL::Primitive/whichND>.

=head1 METHODS / MERGE

=head2 merge / cbind

These methods are same,

    merge($df)
    cbind($df)

=head2 append / rbind

These methods are same,

    append($df)
    rbind($df)

=head1 METHODS / TRANSFORMATION AND GROUPING

=head2 transform

    transform($func)

Apply a function to columns of the data frame, and returns a new data
frame object.

C<$func> can be one of the following,

=over 4

=item *

A function coderef.

It would be applied to all columns.

=item *

A hashref of C<< { $column_name =E<gt> $coderef, ... } >>

It allows to apply the function to the specified columns. The raw data
frame's columns not existing in the hashref be retained unchanged. Hashref
keys not yet existing in the raw data frame can be used for creating new
columns.

=item *

An arrayref like C<< [ $column_name =E<gt> $coderef, ... ] >>

In this mode it's similar as the hasref above, but newly added columns
would be in order.

=back

In any of the forms of C<$func> above, if a new column data is calculated
to be C<undef>, or in the mappings like hashref or arrayref C<$coderef> is
an explicit C<undef>, then the column would be removed from the result
data frame.

Here are some examples,

=over 4

=item Operate on all data of the data frame,

    my $df_new = $df->transform(
            sub {
                my ($col, $df) = @_;
                $col * 2;
            } );

=item Change some of the existing columns,

    my $df_new = $df->transform( {
            foo => sub {
                my ($col, $df) = @_;
                $col * 2;
            },
            bar => sub {
                my ($col, $df) = @_;
                $col * 3;
            } );

=item Add a new column from existing data,

    # Equivalent to: 
    # do { my $x = $mtcars->copy;
    #      $x->set('kpg', $mtcars->at('mpg') * 1.609); $x; };
    my $mtcars_new = $mtcars->transform(
            kpg => sub { 
                my ($col, $df) = @_;    # $col is undef in this case
                $df->at('mpg') * 1.609,
            } );

=back

=head2 split

    split(ColumnLike $factor)

Splits the data in into groups defined by C<$factor>.
In a scalar context it returns a hashref mapping value to data frame.
In a list context it returns an assosiative array, which is ordered by
values in C<$factor>.

Note that C<$factor> does not necessarily to be PDL::Factor.

=head2 sort

    sort($by_columns, $ascending=true)

Sort rows for given columns.
Returns a new data frame.

    my $df_sorted1 = $df->sort( [qw(a b)], true );
    my $df_sorted2 = $df->sort( [qw(a b)], [1, 0] );
    my $df_sorted3 = $df->sort( [qw(a b)], pdl([1, 0]) );

=head2 sorti

Similar as this class's C<sort()> method but returns a piddle for row indices.

=head2 uniq

    uniq()

Returns a new data frame, which has the unique rows. The row names
are from the first occurrance of each unique row in the raw data frame.

=head2 id

    id()

Compute a unique numeric id for each unique row in a data frame.

=head1 METHODS / OTHERS

=head2 assign

    assign( (DataFrame|Piddle) $x )

Assign another data frame or a piddle to this data frame for in-place change.

C<$x> can be,

=over 4

=item *

A data frame object having the same dimensions and column names as C<$self>.

=item *

A piddle having the same number of elements as C<$self>.

=back

This method is internally used by the C<.=> operation, below are same,

    $df->assign($x);
    $df .= $x;

=head2 is_numeric_column

    is_numeric_column($column_name_or_idx)

=head2 drop_bad

    drop_bad(:$how='any')

Returns a new data frame with rows with BAD values dropped.

=head1 MISCELLANEOUS FEATURES

=head2 Serialization

See L<Data::Frame::IO::CSV>

=head2 Syntax Sugar

See L<Data::Frame::Partial::Sugar>

=head2 Tidy Evaluation

This feature is somewhat similar to R's tidy evaluation.

See L<Data::Frame::Partial::Eval>.

=head1 VARIABLES

=head2 doubleformat

This is used when stringifying the data frame. Default is C<'%.8g'>.

=head2 TOLERANCE_REL

This is the relative tolerance used when comparing numerical values of two
data frames.
Default is C<undef>, which means no tolerance at all. You can set it like,

    $Data::Frame::TOLERANCE_REL = 1e-8;

=head1 SEE ALSO

=over 4

=item * L<Data::Frame::Examples>

=item * L<Alt>

=item * L<PDL>

=item * L<R manual: data.frame|https://stat.ethz.ch/R-manual/R-devel/library/base/html/data.frame.html>.

=item * L<Statistics::NiceR>

=back

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2020 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

