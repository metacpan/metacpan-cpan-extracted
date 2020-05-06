package DBIx::UpdateTable::FromHoH;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-06'; # DATE
our $DIST = 'DBIx-UpdateTable-FromHoH'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       update_table_from_hoh
               );

our %SPEC;

sub _eq {
    my ($v1, $v2) = @_;
    my $v1_def = defined $v1;
    my $v2_def = defined $v2;
    return 1 if !$v1_def && !$v2_def;
    return 0 if $v1_def xor $v2_def;
    $v1 eq $v2;
}

$SPEC{update_table_from_hoh} = {
    v => 1.1,
    summary => 'Update database table from hash-of-hash',
    description => <<'_',

Given a table `t1` like this:

    id    col1    col2    col3
    --    ----    ----    ----
    1     a       b       foo
    2     c       c       bar
    3     g       h       qux

this code:

    my $res = update_table_from_hoh(
        dbh => $dbh,
        table => 't1',
        key_column => 'id',
        hoh => {
            1 => {col1=>'a', col2=>'b'},
            2 => {col1=>'c', col2=>'d'},
            4 => {col1=>'e', col2=>'f'},
        },
    );

will perform these SQL queries:

    UPDATE TABLE t1 SET col2='d' WHERE id='2';
    INSERT INTO t1 (id,col1,col2) VALUES (4,'e','f');
    DELETE FROM t1 WHERE id='3';

to make table `t1` become like this:

    id    col1    col2    col3
    --    ----    ----    ----
    1     a       b       foo
    2     c       d       bar
    4     e       f       qux

_
    args => {
        dbh => {
            schema => ['obj*'],
            req => 1,
        },
        table => {
            schema => 'str*',
            req => 1,
        },
        hoh => {
            schema => 'hoh*',
            req => 1,
        },
        key_column => {
            schema => 'str*',
            req => 1,
        },
        data_columns => {
            schema => ['array*', of=>'str*'],
        },
        use_tx => {
            schema => 'bool*',
            default => 1,
        },
        extra_insert_columns => {
            schema => ['hos*'], # XXX or code
        },
        extra_update_columns => {
            schema => ['hos*'], # XXX or code
        },
    },
};
sub update_table_from_hoh {
    my %args = @_;

    my $dbh = $args{dbh};
    my $table = $args{table};
    my $hoh = $args{hoh};
    my $key_column = $args{key_column};
    my $data_columns = $args{data_columns};
    my $use_tx = $args{use_tx} // 1;

    unless ($data_columns) {
        my %columns;
        for my $key (keys %$hoh) {
            my $row = $hoh->{$key};
            $columns{ $_ }++ for keys %$row;
        }
        $data_columns = [sort keys %columns];
    }

    my @columns = @$data_columns;
    push @columns, $key_column unless grep { $_ eq $key_column } @columns;
    my $columns_str = join(",", @columns);

    $dbh->begin_work if $use_tx;

    my $hoh_table = {};
  GET_ROWS: {
        my $sth = $dbh->prepare("SELECT $columns_str FROM $table");
        $sth->execute;
        while (my $row = $sth->fetchrow_hashref) {
            $hoh_table->{ $row->{$key_column} } = $row;
        }
    }
    my $num_rows_unchanged = keys %$hoh_table;

    my $num_rows_deleted = 0;
  DELETE: {
        for my $key (sort keys %$hoh_table) {
            unless (exists $hoh->{$key}) {
                $dbh->do("DELETE FROM $table WHERE $key_column=?", {}, $key);
                $num_rows_deleted++;
                $num_rows_unchanged--;
            }
        }
    }

    my $num_rows_updated = 0;
  UPDATE: {
        for my $key (sort keys %$hoh) {
            next unless exists $hoh_table->{$key};
            my @update_columns;
            my @values;
            for my $column (@columns) {
                next if $column eq $key_column;
                unless (_eq($hoh_table->{$key}{$column}, $hoh->{$key}{$column})) {
                    push @update_columns, $column;
                    push @values, $hoh->{$key}{$column};
                }
            }
            next unless @update_columns;

            for my $column (keys %{ $args{extra_update_columns} // {}}) {
                next if grep { $column eq $_ } @columns;
                push @update_columns, $column;
                push @values, $args{extra_update_columns}{$column};
            }

            $dbh->do("UPDATE $table SET ".
                         join(",", map {"$_=?"} @update_columns).
                         " WHERE $key_column=?",
                     {},
                     @values, $key);
            $num_rows_updated++;
            $num_rows_unchanged--;
        }
    }

    my $num_rows_inserted = 0;
  INSERT: {
        my @insert_columns = @columns;
        my @extra_insert_columns = keys %{ $args{extra_insert_columns} // {} };
        for my $column (@extra_insert_columns) { push @insert_columns, $column unless grep { $_ eq $column } @insert_columns }

        my $insert_columns_str = join(",", @insert_columns);
        my $placeholders_str = join(",", map {"?"} @insert_columns);
        for my $key (sort keys %$hoh) {
            unless (exists $hoh_table->{$key}) {
                my @values;
                for my $column (@insert_columns) {
                    if ($column eq $key_column) {
                        push @values, $key;
                    } elsif (grep { $column eq $_ } @extra_insert_columns) {
                        push @values, $args{extra_insert_columns}{$column};
                    } else {
                        push @values, $hoh->{$key}{$column};
                    }
                }
                $dbh->do("INSERT INTO $table ($insert_columns_str) VALUES ($placeholders_str)", {}, @values);
                $num_rows_inserted++;
            }
        }
    }

    $dbh->commit if $use_tx;

    [$num_rows_deleted || $num_rows_inserted || $num_rows_updated ? 200 : 304,
     "OK",
     {
         num_rows_deleted   => $num_rows_deleted,
         num_rows_inserted  => $num_rows_inserted,
         num_rows_updated   => $num_rows_updated,
         num_rows_unchanged => $num_rows_unchanged,
     }];
}

1;
# ABSTRACT: Update database table from hash-of-hash

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::UpdateTable::FromHoH - Update database table from hash-of-hash

=head1 VERSION

This document describes version 0.002 of DBIx::UpdateTable::FromHoH (from Perl distribution DBIx-UpdateTable-FromHoH), released on 2020-05-06.

=head1 DESCRIPTION

Currently only tested on SQLite.

=head1 FUNCTIONS


=head2 update_table_from_hoh

Usage:

 update_table_from_hoh(%args) -> [status, msg, payload, meta]

Update database table from hash-of-hash.

Given a table C<t1> like this:

 id    col1    col2    col3
 --    ----    ----    ----
 1     a       b       foo
 2     c       c       bar
 3     g       h       qux

this code:

 my $res = update_table_from_hoh(
     dbh => $dbh,
     table => 't1',
     key_column => 'id',
     hoh => {
         1 => {col1=>'a', col2=>'b'},
         2 => {col1=>'c', col2=>'d'},
         4 => {col1=>'e', col2=>'f'},
     },
 );

will perform these SQL queries:

 UPDATE TABLE t1 SET col2='d' WHERE id='2';
 INSERT INTO t1 (id,col1,col2) VALUES (4,'e','f');
 DELETE FROM t1 WHERE id='3';

to make table C<t1> become like this:

 id    col1    col2    col3
 --    ----    ----    ----
 1     a       b       foo
 2     c       d       bar
 4     e       f       qux

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<data_columns> => I<array[str]>

=item * B<dbh>* => I<obj>

=item * B<extra_insert_columns> => I<hos>

=item * B<extra_update_columns> => I<hos>

=item * B<hoh>* => I<hoh>

=item * B<key_column>* => I<str>

=item * B<table>* => I<str>

=item * B<use_tx> => I<bool> (default: 1)


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-UpdateTable-FromHoH>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-UpdateTable-FromHoH>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-UpdateTable-FromHoH>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBIx::UpdateHoH::FromTable>

L<DBIx::Compare> to compare database contents.

L<diffdb> from L<App::diffdb> which can compare two database (schema as well as
content) and display the result as the familiar colored unified-style diff.

L<DBIx::Diff::Schema>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
