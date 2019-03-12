[![Build Status](https://travis-ci.org/stphnlyd/p5-Data-Frame.svg?branch=master)](https://travis-ci.org/stphnlyd/p5-Data-Frame)

# NAME

Alt::Data::Frame::ButMore - Alternative implementation of Data::Frame with more features

# VERSION

version 0.0041

# STATUS

This library is current experimental.

# SYNOPSIS

```perl
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

say $df->at(0);
# [1 2 3 4]

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
```

# DESCRIPTION

It's been too long I cannot reach ZMUGHAL.
So here I release my [Alt](https://metacpan.org/pod/Alt) implenmentation.

This implements a data frame container that uses [PDL](https://metacpan.org/pod/PDL) for individual columns.
As such, it supports marking missing values (`BAD` values).

# CONSTRUCTION

```
new( (ArrayRef | HashRef) :$columns,
     ArrayRef :$row_names=undef )
```

Creates a new `Data::Frame` when passed the following options as a
specification of the columns to add:

- columns => ArrayRef $columns\_array

    When `columns` is passed an `ArrayRef` of pairs of the form

    ```perl
    $columns_array = [
        column_name_z => $column_01_data, # first column data
        column_name_y => $column_02_data, # second column data
        column_name_x => $column_03_data, # third column data
    ]
    ```

    then the column data is added to the data frame in the order that the pairs
    appear in the `ArrayRef`.

- columns => HashRef $columns\_hash

    ```perl
    $columns_hash = {
        column_name_z => $column_03_data, # third column data
        column_name_y => $column_02_data, # second column data
        column_name_x => $column_01_data, # first column data
    }
    ```

    then the column data is added to the data frame by the order of the keys in the
    `HashRef` (sorted with a stringwise `cmp`).

- row\_names => ArrayRef $row\_names

# METHODS

## string

```
string() # returns Str
```

Returns a string representation of the `Data::Frame`.

## number\_of\_columns

```
number_of_columns() # returns Int
```

Returns the count of the number of columns in the `Data::Frame`.

## ncol

```
ncol()
```

This is same as `number_of_columns`.

## length

```
length()
```

This is same as `number_of_columns`.

## number\_of\_rows

```
number_of_rows() # returns Int
```

Returns the count of the number of rows in the `Data::Frame`.

## nrow

```
nrow()
```

This is same as `number_of_rows`.

## dims

```
dims()
```

Returns the dimensions of the data frame object, in an array of `($nrow, $ncol)`.

## shape

```
shape()
```

Similar to `dims` but returns a piddle.

## at

```perl
my $column_piddle = $df->at($column_indexer);
my $cell_value = $df->at($row_indexer, $column_indexer);
```

If only one argument is given, it would treat the argument as column
indexer to get the column.
If two arguments are given, it would treat the arguments for row
indexer and column indexer respectively to get the cell value.

If a given argument is non-indexer, it would try guessing whether the
argument is numeric or not, and coerce it by either `indexer_s()` or
`indexer_i()`.

## exists

```
exists($col_name)
```

Returns true if there exists a column named `$col_name` in the data frame
object, false otherwise.

## delete

```
delete($col_name)
```

In-place delete column given by `$col_name`.

## rename

```
rename($hashref_or_coderef)
```

In-place rename columns.

## select\_columns

```
select_columns($indexer)
```

Returns a new data frame object which has the columns selected by `$indexer`.

If a given argument is non-indexer, it would coerce it by `indexer_s()`.

## set

```
set(Indexer $col_name, ColumnLike $data)
```

Sets data to column. If `$col_name` does not exist, it would add a new column.

## isempty

```
isempty()
```

Returns true if the data frame has no rows.

## nth\_columm

```
number_of_rows(Int $n) # returns a column
```

Returns column number `$n`. Supports negative indices (e.g., $n = -1 returns
the last column).

## column\_names

```
column_names() # returns an ArrayRef

column_names( @new_column_names ) # returns an ArrayRef
```

Returns an `ArrayRef` of the names of the columns.

If passed a list of arguments `@new_column_names`, then the columns will be
renamed to the elements of `@new_column_names`. The length of the argument
must match the number of columns in the `Data::Frame`.

## col\_names

```
col_names($new_names)
```

This is same as `column_names`.

## names

```
names($new_names)
```

This is same as `column_names`.

## row\_names

```
row_names() # returns a PDL

row_names( Array @new_row_names ) # returns a PDL

row_names( ArrayRef $new_row_names ) # returns a PDL

row_names( PDL $new_row_names ) # returns a PDL
```

Returns an `ArrayRef` of the names of the columns.

If passed a argument, then the rows will be renamed. The length of the argument
must match the number of rows in the `Data::Frame`.

## column

```
column( Str $column_name )
```

Returns the column with the name `$column_name`.

## add\_columns

```
add_columns( Array @column_pairlist )
```

Adds all the columns in `@column_pairlist` to the `Data::Frame`.

## add\_column

```
add_column(Str $name, $data)
```

Adds a single column to the `Data::Frame` with the name `$name` and data
`$data`.

## select\_rows

```
select_rows( Indexer $indexer)

# below types would be coerced to Indexer
select_rows( Array @which )
select_rows( ArrayRef $which )
select_rows( Piddle $which )
```

The argument `$indexer` is an "Indexer", as defined in [Data::Frame::Types](https://metacpan.org/pod/Data::Frame::Types).
`select_rows` returns a new `Data::Frame` that contains rows that match
the indices specified by `$indexer`.

This `Data::Frame` supports PDL's data flow, meaning that changes to the
values in the child data frame columns will appear in the parent data frame.

If no indices are given, a `Data::Frame` with no rows is returned.

## sample

```
sample($n)
```

Get a random sample of rows from the data frame object, as a new data frame.

```perl
my $sample_df = $df->sample(100);
```

## merge

```
merge($df)
```

## cbind

```
cbind($df)
```

This is same as `merge()`.

## append

```
append($df)
```

## rbind

```
rbind($df)
```

This is same as `append()`.

## transform

```
transform($func)
```

Apply a function to columns of the data frame, and returns a new data
frame object.

`$func` can be one of the following,

- A function coderef. It would be applied to all columns.
- A hashref of `{ $column_name => $coderef, ... }`. It allows to apply

    the function to the specified columns. The raw data frame's columns not 
    existing in the hashref be retained unchanged. Hashref keys not yet
    existing in the raw data frame can be used for creating new columns.

- An arrayref like `[ $column_name => $coderef, ... ]`. In this mode

    it's similar as the hasref above, but newly added columns would be in order.

In any of the forms of `$func` above, if a new column data is calculated
to be `undef`, or in the mappings like hashref or arrayref `$coderef` is
an explicit `undef`, then the column would be removed from the result
data frame.

Here are some examples,

- Operate on all data of the data frame,

    ```perl
    my $df_new = $df->transform(
            sub {
                my ($col, $df) = @_;
                $col * 2;
            } );
    ```

- Change some of the existing columns,

    ```perl
    my $df_new = $df->transform( {
            foo => sub {
                my ($col, $df) = @_;
                $col * 2;
            },
            bar => sub {
                my ($col, $df) = @_;
                $col * 3;
            } );
    ```

- Add a new column from existing data,

    ```perl
    # Equivalent to: 
    # do { my $x = $mtcars->copy;
    #      $x->set('kpg', $mtcars->at('mpg') * 1.609); $x; };
    my $mtcars_new = $mtcars->transform(
            kpg => sub { 
                my ($col, $df) = @_;    # $col is undef in this case
                $df->at('mpg') * 1.609,
            } );
    ```

## split

```
split(ColumnLike $factor)
```

Splits the data in into groups defined by `$factor`.
In a scalar context it returns a hashref mapping value to data frame.
In a list context it returns an assosiative array, which is ordered by
values in `$factor`.

Note that `$factor` does not necessarily to be PDL::Factor.

## slice

```perl
my $subset1 = $df->slice($row_indexer, $column_indexer);

# Note that below two cases are different.
my $subset2 = $df->slice($column_indexer);
my $subset3 = $df->slice($row_indexer, undef);
```

Returns a new dataframe object which is a slice of the raw data frame.

This method returns an lvalue which allows PDL-like `.=` assignment for
changing a subset of the raw data frame. For example,

```
$df->slice($row_indexer, $column_indexer) .= $another_df;
$df->slice($row_indexer, $column_indexer) .= $piddle;
```

If a given argument is non-indexer, it would try guessing if the argument
is numeric or not, and coerce it by either `indexer_s()` or `indexer_i()`.

## assign

```
assign( (DataFrame|Piddle) $x )
```

Assign another data frame or a piddle to this data frame for in-place change.

`$x` can be,

> \*A data frame object having the same dimensions and column names as `$self`.
> \*A piddle having the same number of elements as `$self`.

This method is internally used by the `.=` operation, below are same,

```
$df->assign($x);
$df .= $x;
```

## is\_numeric\_column

```
is_numeric_column($column_name_or_idx)
```

## sort

```
sort($by_columns, $ascending=true)
```

Sort rows for given columns.
Returns a new data frame.

```perl
my $df_sorted1 = $df->sort( [qw(a b)], true );
my $df_sorted2 = $df->sort( [qw(a b)], [1, 0] );
my $df_sorted3 = $df->sort( [qw(a b)], pdl([1, 0]) );
```

## sorti

Similar as this class's `sort()` method but returns a piddle for row indices.

## uniq

```
uniq()
```

Returns a new data frame, which has the unique rows. The row names
are from the first occurrance of each unique row in the raw data frame.

## id

```
id()
```

Compute a unique numeric id for each unique row in a data frame.

## copy

```
copy()
```

Make a deep copy of this data frame object.

## clone

```
clone()
```

This is same as `copy()`.

## which

```
which(:$bad_to_val=undef, :$ignore_both_bad=true)
```

Returns a pdl of `[[col_idx, row_idx], ...]`, like the output of
["whichND" in PDL::Primitive](https://metacpan.org/pod/PDL::Primitive#whichND).

# MISCELLANEOUS FEATURES

## SERIALIZATION

See [Data::Frame::IO::CSV](https://metacpan.org/pod/Data::Frame::IO::CSV)

## SYNTAX SUGAR

See [Data::Frame::Partial::Sugar](https://metacpan.org/pod/Data::Frame::Partial::Sugar)

## TIDY EVALUATION

This feature is somewhat similar to R's tidy evaluation.

See [Data::Frame::Partial::Eval](https://metacpan.org/pod/Data::Frame::Partial::Eval).

# VARIABLES

# doubleformat

This is used when stringifying the data frame. Default is `'%.8g'`.

# TOLERANCE\_REL

This is the relative tolerance used when comparing numerical values of two
data frames.
Default is `undef`, which means no tolerance at all. You can set it like,

```
$Data::Frame::TOLERANCE_REL = 1e-8;
```

# SEE ALSO

- [Alt](https://metacpan.org/pod/Alt)
- [Data::Frame::Examples](https://metacpan.org/pod/Data::Frame::Examples)
- [PDL](https://metacpan.org/pod/PDL)
- [R manual: data.frame](https://stat.ethz.ch/R-manual/R-devel/library/base/html/data.frame.html).
- [Statistics::NiceR](https://metacpan.org/pod/Statistics::NiceR)

# AUTHORS

- Zakariyya Mughal <zmughal@cpan.org>
- Stephan Loyd <sloyd@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
