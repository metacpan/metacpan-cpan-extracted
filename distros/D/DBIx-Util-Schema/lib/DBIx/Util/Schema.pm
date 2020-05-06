package DBIx::Util::Schema;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-06'; # DATE
our $DIST = 'DBIx-Util-Schema'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use List::Util qw(first);

use Exporter 'import';
our @EXPORT_OK = qw(
                             table_exists
                             has_table
                             has_all_tables
                             has_any_table

                             column_exists
                             has_column
                             has_all_columns
                             has_any_column

                             list_tables
                             list_columns
                             list_indexes
               );

# TODO:
#                              primary_key_columns
#                              has_primary_key
#                              has_index_on (has_index?)
#                              has_unique_index_on
#                              has_a_unique_index
#
#                              has_foreign_key
#
#                              is_null_column
#                              is_not_null_column
#                              is_unique_column

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utility routines related to database schema',
};

our %arg0_dbh = (
    dbh => {
        schema => ['obj*'],
        summary => 'DBI database handle',
        req => 1,
        pos => 0,
    },
);

our %arg1_table = (
    table => {
        schema => ['str*'],
        summary => 'Table name',
        req => 1,
        pos => 1,
    },
);

our %arg1rest_tables = (
    tables => {
        schema => ['array*', of=>'str*'],
        summary => 'Table names',
        req => 1,
        pos => 1,
        slurpy => 1,
    },
);

our %arg2_column = (
    column => {
        schema => ['str*'],
        summary => 'Table column name',
        req => 1,
        pos => 2,
    },
);

our %arg2rest_columns = (
    columns => {
        schema => ['array*', of=>'str*'],
        summary => 'Table column names',
        req => 1,
        pos => 2,
        slurpy => 1,
    },
);

$SPEC{has_table} = {
    v => 1.1,
    summary => 'Check whether database has a certain table',
    args => {
        %arg0_dbh,
        %arg1_table,
    },
    args_as => "array",
    result_naked => 1,
};
sub has_table {
    my ($dbh, $table) = @_;
    my $sth;
    if ($table =~ /(.+)\.(.+)/) {
        $sth = $dbh->table_info(undef, $1, $2, undef);
    } else {
        $sth = $dbh->table_info(undef, undef, $table, undef);
    }

    $sth->fetchrow_hashref ? 1:0;
}

# alias for has_table
$SPEC{table_exists} = { %{$SPEC{has_table}}, summary=>'Alias for has_table()' };
*table_exists = \&has_table;

$SPEC{has_all_tables} = {
    v => 1.1,
    summary => 'Check whether database has all specified tables',
    args => {
        %arg0_dbh,
        %arg1rest_tables,
    },
    args_as => "array",
    result_naked => 1,
};
sub has_all_tables {
    my ($dbh, @tables) = @_;
    my $sth;
    for my $table (@tables) {
        if ($table =~ /(.+)\.(.+)/) {
            $sth = $dbh->table_info(undef, $1, $2, undef);
        } else {
            $sth = $dbh->table_info(undef, undef, $table, undef);
        }
        return 0 unless $sth->fetchrow_hashref;
    }
    1;
}

$SPEC{has_any_table} = {
    v => 1.1,
    summary => 'Check whether database has at least one of specified tables',
    args => {
        %arg0_dbh,
        %arg1rest_tables,
    },
    args_as => "array",
    result_naked => 1,
};
sub has_any_table {
    my ($dbh, @tables) = @_;
    my $sth;
    for my $table (@tables) {
        if ($table =~ /(.+)\.(.+)/) {
            $sth = $dbh->table_info(undef, $1, $2, undef);
        } else {
            $sth = $dbh->table_info(undef, undef, $table, undef);
        }
        return 1 if $sth->fetchrow_hashref;
    }
    @tables ? 0 : 1;
}

$SPEC{has_column} = {
    v => 1.1,
    summary => 'Check whether a table has a specified column',
    args => {
        %arg0_dbh,
        %arg1_table,
        %arg2_column,
    },
    args_as => "array",
    result_naked => 1,
};
sub has_column {
    my ($dbh, $table, $column) = @_;
    return 0 unless has_table($dbh, $table);
    my @columns = list_columns($dbh, $table);
    (grep {$_->{COLUMN_NAME} eq $column} @columns) ? 1:0;
}

# alias for has_column
$SPEC{column_exists} = { %{$SPEC{has_column}}, summary=>'Alias for has_column()' };
*column_exists = \&has_column;

$SPEC{has_all_columns} = {
    v => 1.1,
    summary => 'Check whether a table has all specified columns',
    args => {
        %arg0_dbh,
        %arg1_table,
        %arg2rest_columns,
    },
    args_as => "array",
    result_naked => 1,
};
sub has_all_columns {
    my ($dbh, $table, @columns) = @_;
    return 0 unless has_table($dbh, $table);
    my @all_columns = list_columns($dbh, $table);
    for my $column (@columns) {
        unless (grep {$_->{COLUMN_NAME} eq $column} @all_columns) { return 0 }
    }
    1;
}

$SPEC{has_any_column} = {
    v => 1.1,
    summary => 'Check whether a table has at least one of specified columns',
    args => {
        %arg0_dbh,
        %arg1_table,
        %arg2rest_columns,
    },
    args_as => "array",
    result_naked => 1,
};
sub has_any_column {
    my ($dbh, $table, @columns) = @_;
    return 0 unless has_table($dbh, $table);
    my @all_columns = list_columns($dbh, $table);
    for my $column (@columns) {
        if (grep {$_->{COLUMN_NAME} eq $column} @all_columns) { return 1 }
    }
    @columns ? 0:1;
}

$SPEC{list_tables} = {
    v => 1.1,
    summary => 'List table names in a database',
    args => {
        %arg0_dbh,
    },
    args_as => "array",
    result_naked => 1,
};
sub list_tables {
    my ($dbh) = @_;

    my $driver = $dbh->{Driver}{Name};

    my @res;
    my $sth = $dbh->table_info(undef, undef, undef, undef);
    while (my $row = $sth->fetchrow_hashref) {
        my $name  = $row->{TABLE_NAME};
        my $schem = $row->{TABLE_SCHEM};
        my $type  = $row->{TABLE_TYPE};

        if ($driver eq 'mysql') {
            # mysql driver returns database name as schema, so that's useless
            $schem = '';
        }

        next if $type eq 'VIEW';
        next if $type eq 'INDEX';
        next if $schem =~ /^(information_schema)$/;

        if ($driver eq 'Pg') {
            next if $schem =~ /^(pg_catalog)$/;
        } elsif ($driver eq 'SQLite') {
            next if $schem =~ /^(temp)$/;
            next if $name =~ /^(sqlite_master|sqlite_temp_master)$/;
        }

        push @res, join(
            "",
            $schem,
            length($schem) ? "." : "",
            $name,
        );
    }
    sort @res;
}

$SPEC{list_indexes} = {
    v => 1.1,
    summary => 'List indexes for a table in a database',
    description => <<'_',

SQLite notes: information is retrieved from DBI's table_info(). Autoindex for
primary key is not listed using table_info(), but this function adds it by
looking at `sqlite_master` table.

MySQL notes: information is retrieved from statistics_info(). Note that a
multi-column index is reported as separate rows by statistics_info(), one for
each indexed column. But this function merges them and returns the list of
columns in `columns`.

_
    args => {
        %arg0_dbh,
        %arg1_table,
    },
    args_as => "array",
    result_naked => 1,
};
sub list_indexes {
    my ($dbh, $wanted_table) = @_;

    my $driver = $dbh->{Driver}{Name};

    my @res;

    if ($driver eq 'SQLite') {

        my @wanted_tables;
        if (defined $wanted_table) {
            @wanted_tables = ($wanted_table);
        } else {
            @wanted_tables = list_tables($dbh);
        }
        for (@wanted_tables) { $_ = $1 if /.+\.(.+)/ }

        my $sth = $dbh->prepare("SELECT * FROM sqlite_master");
        $sth->execute;
        while (my $row = $sth->fetchrow_hashref) {
            next unless $row->{type} eq 'index';
            next unless grep { $_ eq $row->{tbl_name} } @wanted_tables;
            next unless $row->{name} =~ /\Asqlite_autoindex_.+_(\d+)\z/;
            my $col_num = $1;
            my @cols = list_columns($dbh, $row->{tbl_name});
            push @res, {
                name      => "PRIMARY",
                table     => $row->{tbl_name},
                columns   => [$cols[$col_num-1]{COLUMN_NAME}],
                is_unique => 1,
                is_pk     => 1,
            };
        }

        $sth = $dbh->table_info(undef, undef, undef, undef);
      ROW:
        while (my $row = $sth->fetchrow_hashref) {
            next unless $row->{TABLE_TYPE} eq 'INDEX';

            my $table = $row->{TABLE_NAME};
            my $schem = $row->{TABLE_SCHEM};

            # match table name
            if (defined $wanted_table) {
                if ($wanted_table =~ /(.+)\.(.+)/) {
                    next unless $schem eq $1 && $table eq $2;
                } else {
                    next unless $table eq $wanted_table;
                }
            }

            next unless my $sql = $row->{sqlite_sql};
            #use DD; dd $row;
            $sql =~ s/\A\s*CREATE\s+(UNIQUE\s+)?INDEX\s+//is or do {
                log_trace "Not a CREATE INDEX statement, skipped: $row->{sqlite_sql}";
                next ROW;
            };

            $row->{is_unique} = $1 ? 1:0; # not-standard, backward compat
            $row->{NON_UNIQUE} = $1 ? 0:1;

            $sql =~ s/\A(\S+)\s+//s
                or die "Can't extract index name from sqlite_sql: $sql";
            $row->{name} = $1; # non-standard, backward compat
            $row->{INDEX_NAME} = $1;

            $sql =~ s/\AON\s*(\S+)\s*\(\s*(.+)\s*\)//s
                or die "Can't extract indexed table+columns from sqlite_sql: $sql";
            $row->{table} = $table // $1; # non-standard, backward-compat
            $row->{columns} = [split /\s*,\s*/, $2]; # non-standard

            push @res, $row;
        } # while row

    } elsif ($driver eq 'mysql') {

        my $sth = $dbh->statistics_info(undef, undef, undef, undef, undef);
        $sth->execute;
        my @res0;
        while (my $row = $sth->fetchrow_hashref) {
            if (defined $wanted_table) {
                if ($wanted_table =~ /(.+)\.(.+)/) {
                    next unless $row->{TABLE_SCHEM} eq $1 && $row->{TABLE_NAME} eq $2;
                } else {
                    next unless $row->{TABLE_NAME} eq $wanted_table;
                }
            }
            $row->{table} = $row->{TABLE_NAME}; # non-standard, backward-compat
            $row->{name} = $row->{INDEX_NAME}; # non-standard, backward-compat
            $row->{is_unique} = $row->{NON_UNIQUE} ? 0:1; # non-standard, backward-compat
            $row->{is_pk} = $row->{INDEX_NAME} eq 'PRIMARY' ? 1:0; # non-standard, backward-compat

            push @res0, $row;
        }

        # merge separated per-indexed-column result into a single all-columns
        # result
        my @index_names;
        for my $row (@res0) { push @index_names, $row->{INDEX_NAME} unless grep { $row->{INDEX_NAME} eq $_ } @index_names }
        for my $index_name (@index_names) {
            my @hashes = grep { $_->{INDEX_NAME} eq $index_name } @res0;
            if (@hashes == 1) {
                push @res, $hashes[0];
            } else {
                my %merged_hash;
                $merged_hash{columns} = [];
                for my $hash (@hashes) {
                    $merged_hash{columns}[ $hash->{ORDINAL_POSITION}-1 ] = $hash->{COLUMN_NAME};
                    for (keys %$hash) { $merged_hash{$_} = $hash->{$_} }
                }
                delete $merged_hash{ORDINAL_POSITION};
                push @res, \%merged_hash;
            }
        }

    } else {

        die "Driver $driver is not yet supported for list_indexes";
    }

    @res;
}

$SPEC{list_columns} = {
    v => 1.1,
    summary => 'List columns of a table',
    args => {
        %arg0_dbh,
        %arg1_table,
    },
    args_as => "array",
    result_naked => 1,
};
sub list_columns {
    my ($dbh, $table) = @_;

    my @res;
    my ($schema, $utable);
    if ($table =~ /\./) {
        ($schema, $utable) = split /\./, $table;
    } else {
        $schema = undef;
        $utable = $table;
    }
    my $sth = $dbh->column_info(undef, $schema, $utable, undef);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $row;
    }
    sort @res;
}

1;
# ABSTRACT: Utility routines related to database schema

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Util::Schema - Utility routines related to database schema

=head1 VERSION

This document describes version 0.002 of DBIx::Util::Schema (from Perl distribution DBIx-Util-Schema), released on 2020-05-06.

=head1 SYNOPSIS

 use DBIx::Util::Schema qw(
     table_exists
     column_exists

     list_tables
     list_columns
     list_indexes
 );

 say "Database has table named 'foo'" if table_exists($dbh, "foo");

=head1 DESCRIPTION

L<DBI> already provides methods to query schema information, e.g.
C<table_info()>, C<column_info()>, C<statistics_info()>, but simple things like
checking whether a table or a column exists is not straightforward or easy
enough. This module provides convenience routines for those tasks.

Currently only tested on SQLite, MySQL, and Postgres.

=head1 FUNCTIONS


=head2 column_exists

Usage:

 column_exists($dbh, $table, $column) -> any

Alias for has_column().

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$column>* => I<str>

Table column name.

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 has_all_columns

Usage:

 has_all_columns($dbh, $table, $columns, ...) -> any

Check whether a table has all specified columns.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$columns>* => I<array[str]>

Table column names.

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 has_all_tables

Usage:

 has_all_tables($dbh, $tables, ...) -> any

Check whether database has all specified tables.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$tables>* => I<array[str]>

Table names.


=back

Return value:  (any)



=head2 has_any_column

Usage:

 has_any_column($dbh, $table, $columns, ...) -> any

Check whether a table has at least one of specified columns.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$columns>* => I<array[str]>

Table column names.

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 has_any_table

Usage:

 has_any_table($dbh, $tables, ...) -> any

Check whether database has at least one of specified tables.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$tables>* => I<array[str]>

Table names.


=back

Return value:  (any)



=head2 has_column

Usage:

 has_column($dbh, $table, $column) -> any

Check whether a table has a specified column.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$column>* => I<str>

Table column name.

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 has_table

Usage:

 has_table($dbh, $table) -> any

Check whether database has a certain table.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 list_columns

Usage:

 list_columns($dbh, $table) -> any

List columns of a table.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 list_indexes

Usage:

 list_indexes($dbh, $table) -> any

List indexes for a table in a database.

SQLite notes: information is retrieved from DBI's table_info(). Autoindex for
primary key is not listed using table_info(), but this function adds it by
looking at C<sqlite_master> table.

MySQL notes: information is retrieved from statistics_info(). Note that a
multi-column index is reported as separate rows by statistics_info(), one for
each indexed column. But this function merges them and returns the list of
columns in C<columns>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 list_tables

Usage:

 list_tables($dbh) -> any

List table names in a database.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.


=back

Return value:  (any)



=head2 table_exists

Usage:

 table_exists($dbh, $table) -> any

Alias for has_table().

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-Util-Schema>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-Util-Schema>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Util-Schema>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Test::DBUnit> currently has more methods.

L<DBI>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
