package DBIx::PivotQuery;
use strict;
use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
use Carp 'croak';
use vars '$VERSION';
$VERSION = '0.01';

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(pivot_by pivot_list pivot_sql);

=head1 NAME

DBIx::PivotQuery - create pivot tables from queries

=head1 SYNOPSIS

  use DBIx::PivotQuery 'pivot_by';
  my $rows = pivot_by(
      dbh       => $dbh,
      columns   => ['month'],
      rows      => ['region'],
      aggregate => ['sum(amount) as amount'],
      sql => <<'SQL');
    select
        month(date) as report_month
      , region
      , amount
    from mytable
  SQL

The above code returns a data structure roughly like

  # [
  #   ['region','1','2',...,'11','12'],
  #   ['East',   0,  0 ,..., 10, 20 ],
  #   ['North',  0,  1 ,..., 10, 20 ],
  #   ['South',  0,  3 ,..., 10, 5  ],
  #   ['West',   0,  6 ,..., 8,  20 ],
  # ]

=head1 FUNCTIONS

# This should maybe return a duck-type statement handle so that people
# can fetch row-by-row to their hearts content
# row-by-row still means we need to know all values for the column key :-/

=head2 C<< pivot_by >>

    my $l = pivot_by(
        dbh     => $test_dbh,
        rows    => ['region'],
        columns => ['date'],
        aggregate => ['sum(amount) as amount'],
        placeholder_values => [],
        subtotals => 1,
        sql => <<'SQL',
      select
          region
        , "date"
        , amount
        , customer
      from mytable
    SQL
    );

Transforms the SQL given and returns an AoA pivot table according to
C<rows>, C<columns> and C<aggregate>.

The last word (<c>\w+</c>) of each element of C<aggregate> will be used as the
aggregate column name unless C<aggregate_columns> is given.

Supplying C<undef> for a column name in C<rows> will create an empty cell
in that place. This is convenient when creating subtotals.

=head3 Options

=over 4

=item B<headers>

  headers => 1,

Whether to include the headers as the first row

=back

Subtotals are calculated by repeatedly running the query. For optimization, you
could first select the relevant (aggregated)
rows into a temporary table and then create the subtotals from that temporary
table if query performance is an issue:

  select foo, sum(bar) as bar, baz
    into #tmp_query
    from mytable
   where year = ?

   select foo, bar, baz from #tmp_query

=cut

sub pivot_by( %options ) {
    croak "Need an SQL string in option 'sql'"
        unless $options{sql};
    croak "Need a database handle in option 'dbh'"
        unless $options{dbh};
    $options{ placeholder_values } ||= [];
    $options{ rows } ||= [];

    if( $options{ subtotals } and ! ref $options{ subtotals }) {
        $options{ subtotals } = [@{ $options{rows}}];
    };

    my $subtotals = delete $options{ subtotals };

    my $result = simple_pivot_by( %options );

    if( $subtotals ) {
        for my $i ( reverse 0..$#$subtotals ) {
            $subtotals->[$i] = undef;
            my $s = simple_pivot_by(
                %options,
                rows    => $subtotals,
                headers => 0
            );

            # Now splice our subtotals into the list
            # Wherever the subtotals key changes, insert the subtotal
            my $p = $options{ headers } ? 1 : 0;
            my $last;
            while( @$s and $p < @$result ) {
                my $curr = join "\0", @{ $result->[$p] }[0..$i-1];
                $last ||= $curr;
                if( $last ne $curr ) {
                    splice @$result, $p, 0, shift @$s;
                    $p++;
                    $last = join "\0", @{ $result->[$p] }[0..$i-1];
                };
                $p++;
            };

            # Whatever remains will just be appended
            push @$result, @$s;
        };
    };

    $result;
}

sub simple_pivot_by( %options ) {
    my $sql = pivot_sql( %options );
    my $sth = $options{ dbh }->prepare( $sql );
    $sth->execute( @{$options{ placeholder_values }} );
    my $rows = $sth->fetchall_arrayref({});
    my @aggregate_columns;
    if( exists $options{ aggregate_columns }) {
        @aggregate_columns = @{ $options{ aggregate_columns }};
    } else {
        @aggregate_columns = map {/(\w+)\w*$/ ? $1 : $_ } @{ $options{ aggregate }};
    };
    pivot_list( %options, aggregate => \@aggregate_columns, list => $rows );
}

# Takes an AoA and derives the total order from it if possible
# Returns the total order of the keys. Not every key is expected to be available
# in every row
sub partial_order( $comparator, $keygen, @list ) {
    my %sort;
    my %keys;

    for my $row (@list) {
        my $last_key;
        for my $col (@$row) {
        # This approach doesn't have the transitive property
        # We need to place items in arrays resp. on a float lattice
        # $sort{ $item } = (max( $sort_after($item ) - min( $sort_before($item)) / 2
            my $key = $keygen->( $col );
            $keys{ $key } = 1;
            if( defined $last_key ) {
                for my $cmp (["$last_key\0$key",-1],
                             ["$key\0$last_key",1],
                            ) {
                    my ($k,$v) = @$cmp;
                    $sort{$k} = $v;
                }
            } else {
                $last_key = $key;
            };
        }
    }

    sort { $sort{ $a } <=> $sort{$b} } keys %keys;
}

# Pivots an AoH (no AoA support yet!?)
# The list must already be sorted by @rows, @columns
# At least one line must contain all column values (!)

=head2 C<< pivot_list >>

  my $l = pivot_list(
      list      => @AoH,
      columns   => ['date'],
      rows      => ['region'],
      aggregate => ['amount'],
  );

The rows of C<@$l> are then plain arrays not hashes.
The first row of C<@$l> will contain the column titles.

The column titles are built from joining the pivot column values by C<$;> .

=over 4

=item B<headers>

  headers => 1,

Whether to include the headers as the first row

=back

=cut

sub pivot_list( %options ) {
    my @rows;
    my %colnum;
    my %rownum;

    if( ! exists $options{ headers }) {
        $options{ headers } = 1;
    };

    my @key_cols   = @{ $options{ columns }   || [] };
    my @key_rows   = @{ $options{ rows }      || [] };
    my @aggregates = @{ $options{ aggregate } || [] };
    my @colhead;

    # Now we need to determine the numbers for all the columns
    if( $options{ sort_columns } ) {
        # If we have a user-supplied sorting function, use that:
        @colnum{ sort( sub { $options{ sort_columns }->($a,$b) }, keys %colnum )}
            = (@key_rows)..((@key_rows)+(keys %colnum)-1);
        for( keys %colnum ) {
            $colhead[ $colnum{ $_ }] = $_;
        };
    } else {
        # We assume that the first row contains all columns in order.
        # Following lines may skip values or have additional columns which
        # will be appended. This could be smarter by introducing a partial
        # order in the hope that everything will work out in the end.
        my $col = @key_rows;
        for my $cell (@{ $options{ list }}) {
            my $colkey = join $;, @{ $cell }{ @key_cols };
            if( ! exists $colnum{ $colkey }) {
                $colnum{ $colkey } ||= $col++;
                push @colhead, $colkey;
            };
        };
    }

    my @effective_key_rows = grep { defined $_ } @key_rows; # remove placeholders

    if( ! @colhead) {
        @colhead = $aggregates[0];
    };

    my $last_row;
    my @row;
    for my $cell (@{ $options{ list }}) {
        my $colkey = join $;, @{ $cell }{ @key_cols };
        my $rowkey = join $;, @{ $cell }{ @effective_key_rows };

        if( defined $last_row and $rowkey ne $last_row ) {
            push @rows, [splice @row, 0];
        };

        # We should have %row instead, but how to name the
        # columns and rows that are values now?!
        # prefix "pivot_" ?
        # Allow the user to supply names?
        # Expect the user to rename the keys?
        if( ! @row ) {
            @row = map { defined $_ ? $cell->{$_} : undef } @key_rows;
        };

        my %cellv = %$cell;
        @cellv{ @aggregates } = @{$cell}{@aggregates};
        #$row[ $colnum{ $colkey }] = \%cellv;
        $row[ $colnum{ $colkey }] = $cell->{ $aggregates[0] };
        $last_row = $rowkey;
    };
    if(@row) {
        push @rows, \@row;
    };

    unshift @rows, [ @key_rows, @colhead ]
        if $options{ headers };

    \@rows
}

=head2 C<< pivot_sql >>

  pivot_sql(
      columns => ['date'],
      rows    => ['region'],
      aggregate => ['sum(amount) as amount'],
      sql => <<'SQL' );
    select
        "date"
      , region
      , amount
    from mytable
  SQL

Creates SQL around a subselect that aggregates the given
columns.

The SQL created by the call above would be

    select "region"
         , "date"
         , sum(amount) as amount
    from (
        select
            "date"
          , region
          , amount
        from mytable
    ) foo
    group by "region, "date"
    order by "region", "date"

Note that the values in the C<columns> and C<rows> options will be automatically
enclosed in double quotes.

This function is convenient if you want to ccreate ad-hoc pivot queries instead
of setting up the appropriate views in the database.

If you want to produce subtotals, this function can be called
with the elements removed successively from C<$options{rows}> or
C<$options{columns}> for computing row or column totals.

=cut

sub pivot_sql( %options ) {
    my @columns = (grep { defined $_ } @{ $options{ rows } || [] }, @{ $options{ columns } || []});
    my $qcolumns = join "\n  , ", @columns, @{ $options{ aggregate }};
    my $keycolumns = join "\n       , ", @columns;
    my $clauses = '';
    if($keycolumns) {
    $clauses = join "\n",
                 "group by $keycolumns",
                 "order by $keycolumns",
    };

    return <<SQL
select
    $qcolumns
  from (
$options{sql}
) foo
$clauses
SQL
}
1;

=head1 Unsupported features

Currently only one aggregate value is allowed.

Row aggregates ("totals") are not supported yet. Row aggregates will
mean heavy rewriting of the SQL to wrap the aggregate function over the column
names of the query.

=head1 SEE ALSO

L<DBI>

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/DBIx-PivotQuery>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-PivotQuery>
or via mail to L<dbix-pivotquery-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2017 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
