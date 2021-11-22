package Data::TableData::Object::Base;

use 5.010001;
use strict;
use warnings;

use Scalar::Util::Numeric qw(isint isfloat);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-11-17'; # DATE
our $DIST = 'Data-TableData-Object'; # DIST
our $VERSION = '0.114'; # VERSION

sub _array_is_numeric {
    my $self = shift;
    for (@{$_[0]}) {
        return 0 if defined($_) && !isint($_) && !isfloat($_);
    }
    return 1;
}

sub _list_is_numeric {
    my $self = shift;
    $self->_array_is_numeric(\@_);
}

sub cols_by_name {
    my $self = shift;
    $self->{cols_by_name};
}

sub cols_by_idx {
    my $self = shift;
    $self->{cols_by_idx};
}

sub col_exists {
    my ($self, $name_or_idx) = @_;
    if ($name_or_idx =~ /\A[0-9][1-9]*\z/) {
        return $name_or_idx <= @{ $self->{cols_by_idx} };
    } else {
        return exists $self->{cols_by_name}{$name_or_idx};
    }
}

sub col_name {
    my ($self, $name_or_idx) = @_;
    if ($name_or_idx =~ /\A[0-9][1-9]*\z/) {
        return $self->{cols_by_idx}[$name_or_idx];
    } else {
        return exists($self->{cols_by_name}{$name_or_idx}) ?
            $name_or_idx : undef;
    }
}

sub col_idx {
    my ($self, $name_or_idx) = @_;
    if ($name_or_idx =~ /\A[0-9][1-9]*\z/) {
        return $name_or_idx < @{ $self->{cols_by_idx} } ? $name_or_idx : undef;
    } else {
        return $self->{cols_by_name}{$name_or_idx};
    }
}

sub col_count {
    my $self = shift;
    scalar @{ $self->{cols_by_idx} };
}

sub col_content {
    my ($self, $name_or_idx) = @_;

    my $col_idx = $self->col_idx($name_or_idx);
    return undef unless defined $col_idx; ## no critic: Subroutines::ProhibitExplicitReturnUndef

    my $row_count = $self->row_count;
    return [] unless $row_count;

    my $col_content = [];
    for my $i (0 .. $row_count-1) {
        my $row = $self->row_as_aos($i);
        $col_content->[$i] = $row->[$col_idx];
    }
    $col_content;
}

sub _select {
    my ($self, $_as, $cols0, $excl_cols, $func_filter_row, $sorts) = @_;

    # determine result's columns & spec
    my $spec;
    my %newcols_to_origcols;
    my @cols0; # original column names but with '*' expanded
    my @newcols;
    if ($cols0) {
        $spec = {fields=>{}};
        my $i = 0;
        for my $col0 (@$cols0) {
            my @add;
            if ($col0 eq '*') {
                @add = @{ $self->{cols_by_idx} };
            } else {
                die "Column '$col0' does not exist" unless $self->col_exists($col0);
                @add = ($col0);
            }

            for my $add (@add) {
                next if $excl_cols && (grep {$add eq $_} @$excl_cols);
                push @cols0, $add;
                my $j = 1;
                my $col = $add;
                while (defined $newcols_to_origcols{$col}) {
                    $j++;
                    $col = "${add}_$j";
                }
                $newcols_to_origcols{$col} = $add;
                push @newcols, $col;

                $spec->{fields}{$col} = {
                    %{$self->{spec}{fields}{$add} // {}},
                    pos=>$i,
                };
                $i++;
            }
        }
        $cols0 = \@cols0;
    } else {
        # XXX excl_cols is not being observed
        $spec = $self->{spec};
        $cols0 = $self->{cols_by_idx};
        @newcols = @{ $self->{cols_by_idx} };
        for (@newcols) { $newcols_to_origcols{$_} = $_ }
    }

    my $rows = [];

    # filter rows
    for my $row (@{ $self->rows_as_aohos }) {
        next unless !$func_filter_row || $func_filter_row->($self, $row);
        push @$rows, $row;
    }

    # sort rows
    if ($sorts && @$sorts) {
        # determine whether each column mentioned in $sorts is numeric, to
        # decide whether to use <=> or cmp.
        my %col_is_numeric;
        for my $sortcol (@$sorts) {
            my ($reverse, $col) = $sortcol =~ /\A(-?)(.+)/
                or die "Invalid sort column specification '$sortcol'";
            next if defined $col_is_numeric{$col};
            my $sch = $self->{spec}{fields}{$col}{schema};
            if ($sch) {
                require Data::Sah::Util::Type;
                $col_is_numeric{$col} = Data::Sah::Util::Type::is_numeric($sch);
            } else {
                my $col_name = $self->col_name($col);
                defined($col_name) or die "Unknown sort column '$col'";
                $col_is_numeric{$col} = $self->_array_is_numeric(
                    [map {$_->{$col_name}} @$rows]);
            }
        }

        $rows = [sort {
            for my $sortcol (@$sorts) {
                my ($reverse, $col) = $sortcol =~ /\A(-?)(.+)/;
                my $name = $self->col_name($col);
                my $cmp = ($reverse ? -1:1) *
                    ($col_is_numeric{$col} ?
                     ($a->{$name} <=> $b->{$name}) :
                     ($a->{$name} cmp $b->{$name}));
                return $cmp if $cmp;
            }
            0;
        } @$rows];
    } # sort rows

    # select columns & convert back to aoaos if that's the requested form
    {
        my $rows2 = [];
        for my $row0 (@$rows) {
            my $row;
            if ($_as eq 'aoaos') {
                $row = [];
                for my $i (0..$#{$cols0}) {
                    $row->[$i] = $row0->{$cols0->[$i]};
                }
            } else {
                $row = {};
                for my $i (0..$#newcols) {
                    $row->{$newcols[$i]} =
                        $row0->{$newcols_to_origcols{$newcols[$i]}};
                }
            }
            push @$rows2, $row;
        }
        $rows = $rows2;
    }

    # return result as object
    if ($_as eq 'aoaos') {
        require Data::TableData::Object::aoaos;
        return Data::TableData::Object::aoaos->new($rows, $spec);
    } else {
        require Data::TableData::Object::aohos;
        return Data::TableData::Object::aohos->new($rows, $spec);
    }
}

sub select_as_aoaos {
    my ($self, $cols, $excl_cols, $func_filter_row, $sorts) = @_;
    $self->_select('aoaos', $cols, $excl_cols, $func_filter_row, $sorts);
}

sub select_as_aohos {
    my ($self, $cols, $excl_cols, $func_filter_row, $sorts) = @_;
    $self->_select('aohos', $cols, $excl_cols, $func_filter_row, $sorts);
}

sub uniq_col_names { die "Must be implemented by subclass" }

sub const_col_names { die "Must be implemented by subclass" }

sub del_col { die "Must be implemented by subclass" }

sub rename_col { die "Must be implemented by subclass" }

sub switch_cols { die "Must be implemented by subclass" }

1;
# ABSTRACT: Base class for Data::TableData::Object::*

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableData::Object::Base - Base class for Data::TableData::Object::*

=head1 VERSION

This document describes version 0.114 of Data::TableData::Object::Base (from Perl distribution Data-TableData-Object), released on 2021-11-17.

=head1 METHODS

=head2 new($data[ , $spec]) => obj

Constructor. C<$spec> is optional, a specification hash as described by
L<TableDef>.

=head2 $td->cols_by_name => hash

Return the columns as a hash with name as keys and index as values.

Example:

 {name=>0, gender=>1, age=>2}

=head2 $td->cols_by_idx => array

Return the columns as an array where the element will correspond to the column's
position.

Example:

 ["name", "gender", "age"]

=head2 $td->row_count() => int

Return the number of rows.

See also: C<col_count()>.

=head2 $td->col_count() => int

Return the number of columns.

See also: C<row_count()>.

=head2 $td->col_exists($name_or_idx) => bool

Check whether a column exists. Column can be referred to using its name or
index/position (0, 1, ...).

=head2 $td->col_content($name_or_idx) => aos

Get the content of a column as an array of strings. Return undef if column is
unknown. For example, given this table data:

 | name  | age |
 |-------+-----|
 | andi  | 25  |
 | budi  | 29  |
 | cinta | 17  |

then C<< $td->col_content('name') >> or C<< $td->col_content(0) >> will be:

 ['andi', 'budi', 'cinta']

=head2 $td->col_name($idx) => str

Return the name of column referred to by its index/position. Undef if column is
unknown.

See also: C<col_idx()>.

=head2 $td->col_idx($name) => int

Return the index/position of column referred to by its name. Undef if column is
unknown.

See also: C<col_name()>.

=head2 $td->row($idx) => s/aos/hos

Get a specific row (C<$idx> is 0 to mean first row, 1 for second, ...).

=head2 $td->row_as_aos($idx) => aos

Get a specific row (C<$idx> is 0 to mean first row, 1 for second, ...) as aos.

=head2 $td->row_as_hos($idx) => hos

Get a specific row (C<$idx> is 0 to mean first row, 1 for second, ...) as hos.

=head2 $td->rows() => array

Return rows as array(ref). Each element (row) can either be a scalar (in the
case of hash or aos table data) or aos (in the case of aoaos table data) or hos
(in the case of aohos table data).

This is appropriate if you only want the rows and do not care about the fom of
the row, for example if you want to output some of the rows or shuffle them.

See also: C<rows_as_aoaos()> and C<rows_as_aohos()>.

=head2 $td->rows_as_aoaos() => aoaos

Return rows as array of array-of-scalars.

See also: C<rows()> and C<rows_as_aohos()>.

=head2 $td->rows_as_aohos() => aohos

Return rows as array of hash-of-scalars.

See also: C<rows()> and C<rows_as_aoaos()>.

=head2 $td->select_as_aoaos([ \@cols[ , $func_filter_row[ , \@sorts] ] ]) => aoaos

Like C<rows_as_aoaos()>, but allow selecting columns, filtering rows, sorting.

C<\@cols> is an optional array of column specification to return in the
resultset. Currently only column names are allowed. You can mention the same
column name more than once.

C<$func_filter_row> is an optional coderef that will be passed C<< ($td,
$row_as_hos) >> and should return true/false depending on whether the row should
be included in the resultset. If unspecified, all rows will be returned.

C<\@sorts> is an optional array of column specification for sorting. For each
specification, you can use COLUMN_NAME or -COLUMN_NAME (note the dash prefix) to
express descending order instead of the default ascending. If unspecified, no
sorting will be performed.

See also: C<select_as_aohos()>.

=head2 $td->select_as_aohos([ \@cols[ , $func_filter_row[ , \@sorts ] ] ]) => aohos

Like C<select_as_aoaos()>, but will return aohos (array of hashes-of-scalars)
instead of aoaos (array of arrays-of-scalars).

See also: C<select_as_aoaos()>.

=head2 $td->uniq_col_names => list

Return a list of names of columns that are unique. A unique column exists in all
rows and has a defined and unique value across all rows. Example:

 my $td = table([
     {a=>1, b=>2, c=>undef, d=>1},
     {      b=>2, c=>3,     d=>2},
     {a=>1, b=>3, c=>4,     d=>3},
 ]); # -> ('d')

In the above example, C<a> does not exist in the second hash, <b> is not unique,
and C<c> has an undef value in the the first hash.

=head2 $td->const_col_names => list

Return a list of names of columns that are constant. A constant column ehas a
defined single value for all rows (a column that contains all undef's counts).
Example:

 my $td = table([
     {a=>1, b=>2, c=>undef, d=>2},
     {      b=>2, c=>undef, d=>2},
     {a=>2, b=>3, c=>undef, d=>2},
 ]); # -> ('c', 'd')

In the above example, C<a> does not exist in the second hash, <b> has two
different values.

=head2 $td->del_col($name_or_idx) => str

Delete a single column. Will die if the underlying form does not support column
deletion (e.g. aos and hash).

Will modify data. Will also adjust column positions. And will also modify spec,
if spec was given.

Return the deleted column name.

If column is unknown, will simply return undef.

=head2 $td->rename_col($old_name_or_idx, $new_name)

Rename a column to a new name. Will die if the underlying form does not support
column rename (e.g. aos and hash).

Die if column is unknown. Die if new column name is a number, or an existing
column name. Will simply return if new column name is the same as old name.

Might modify data (e.g. in aohos). Will modify spec, if spec was given.

=head2 $td->switch_cols($name_or_idx1, $name_or_idx2)

Switch two columns. Will die if the underlying form does not support column
rename (e.g. aos and hash).

Die if either column is unknown. Will simply return if both are the same column.

Might modify data (e.g. in aohos). Will modify spec, if spec was given.

=head2 $td->add_col($name [ , $idx [ , $spec [ , \@data ] ] ])

Add a column named C<$name>. If C<$idx> is specified, will set the position of
the new column (and existing columns will shift to the right at that position).
If C<$idx> is not specified, will put the new column at the end.

C<@data> is the value of the new column for each row. If not specified, the new
column will be set to C<undef>.

Does not make sense for table form which can only have a fixed number of
columns, e.g. aos, or hash.

=head2 $td->set_col_value($name_or_idx, $value_sub)

Set value of (all rows of) a column. C<$value_sub> is a coderef which will be
given hash arguments containing these keys: C<table> (the
Data::TableData::Object instance), C<row_idx> (row number, 0-based), C<col_name>
(column name), C<col_idx> (column index, 0-based), C<value> (current value).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-TableData-Object>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-Object>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-TableData-Object>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
