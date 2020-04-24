package DBIx::Diff::Schema;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-23'; # DATE
our $DIST = 'DBIx-Diff-Schema'; # DIST
our $VERSION = '0.096'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use List::Util qw(first);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_columns
                       list_tables
                       list_table_indexes
                       list_indexes
                       check_table_exists
                       diff_db_schema
                       diff_table_schema
                       db_schema_eq
                       table_schema_eq
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Compare schema of two DBI databases',
};

my %arg0_dbh = (
    dbh => {
        schema => ['obj*'],
        summary => 'DBI database handle',
        req => 1,
        pos => 0,
    },
);

my %arg1_table = (
    table => {
        schema => ['str*'],
        summary => 'Table name',
        req => 1,
        pos => 1,
    },
);

my %diff_db_args = (
    dbh1 => {
        schema => ['obj*'],
        summary => 'DBI database handle for the first database',
        req => 1,
        pos => 0,
    },
    dbh2 => {
        schema => ['obj*'],
        summary => 'DBI database handle for the second database',
        req => 1,
        pos => 1,
    },
);

my %diff_table_args = (
    %diff_db_args,
    table1 => {
        schema => 'str*',
        summary => 'Table name',
        req => 1,
        pos => 2,
    },
    table2 => {
        schema => 'str*',
        summary => 'Second table name (assumed to be the same as first table name if unspecified)',
        pos => 3,
    },
);

$SPEC{check_table_exists} = {
    v => 1.1,
    summary => 'Check whether a table exists',
    args => {
        %arg0_dbh,
        %arg1_table,
    },
    args_as => "array",
    result_naked => 1,
};
sub check_table_exists {
    my ($dbh, $name) = @_;
    my $sth;
    if ($name =~ /(.+)\.(.+)/) {
        $sth = $dbh->table_info(undef, $1, $2, undef);
    } else {
        $sth = $dbh->table_info(undef, undef, $name, undef);
    }

    $sth->fetchrow_hashref ? 1:0;
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

General notes: information is retrieved from DBI's table_info().

SQLite notes: autoindex for primary key is also listed as the first index, if it
exists. This information is retrieved using "SELECT * FROM sqlite_master".
Autoindex is not listed using table_info().

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

# old name, deprecated
$SPEC{list_table_indexes} = $SPEC{list_indexes};
*list_table_indexes = \&list_indexes;

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

sub _diff_column_schema {
    my ($c1, $c2) = @_;

    my $res = {};
    {
        if ($c1->{TYPE_NAME} ne $c2->{TYPE_NAME}) {
            $res->{old_type} = $c1->{TYPE_NAME};
            $res->{new_type} = $c2->{TYPE_NAME};
            last;
        }
        if ($c1->{NULLABLE} xor $c2->{NULLABLE}) {
            $res->{old_nullable} = $c1->{NULLABLE};
            $res->{new_nullable} = $c2->{NULLABLE};
        }
        if (defined $c1->{CHAR_OCTET_LENGTH}) {
            if ($c1->{CHAR_OCTET_LENGTH} != $c2->{CHAR_OCTET_LENGTH}) {
                $res->{old_length} = $c1->{CHAR_OCTET_LENGTH};
                $res->{new_length} = $c2->{CHAR_OCTET_LENGTH};
            }
        }
        if (defined $c1->{DECIMAL_DIGITS}) {
            if ($c1->{DECIMAL_DIGITS} != $c2->{DECIMAL_DIGITS}) {
                $res->{old_digits} = $c1->{DECIMAL_DIGITS};
                $res->{new_digits} = $c2->{DECIMAL_DIGITS};
            }
        }
        if (($c1->{mysql_is_auto_increment} // 0) != ($c2->{mysql_is_auto_increment} // 0)) {
            $res->{old_auto_increment} = $c1->{mysql_is_auto_increment} // 0;
            $res->{new_auto_increment} = $c2->{mysql_is_auto_increment} // 0;
        }
    }
    $res;
}

sub _diff_table_schema {
    my ($dbh1, $dbh2, $table1, $table2) = @_;

    my @columns1 = list_columns($dbh1, $table1);
    my @columns2 = list_columns($dbh2, $table2);

    log_trace("columns1: %s ...", \@columns1);
    log_trace("columns2: %s ...", \@columns2);

    my (@added, @deleted, %modified);
    for my $c1 (@columns1) {
        my $c1n = $c1->{COLUMN_NAME};
        my $c2 = first {$c1n eq $_->{COLUMN_NAME}} @columns2;
        if (defined $c2) {
            my $tres = _diff_column_schema($c1, $c2);
            $modified{$c1n} = $tres if %$tres;
        } else {
            push @deleted, $c1n;
        }
    }
    for my $c2 (@columns2) {
        my $c2n = $c2->{COLUMN_NAME};
        my $c1 = first {$c2n eq $_->{COLUMN_NAME}} @columns1;
        if (defined $c1) {
        } else {
            push @added, $c2n;
        }
    }

    my $res = {};
    $res->{added_columns}    = \@added    if @added;
    $res->{deleted_columns}  = \@deleted  if @deleted;
    $res->{modified_columns} = \%modified if %modified;
    $res;
}

$SPEC{diff_table_schema} = {
    v => 1.1,
    summary => 'Compare schema of two DBI tables',
    description => <<'_',

This function compares schemas of two DBI tables. You supply two `DBI` database
handles along with table name and this function will return a hash:

    {
        deleted_columns => [...],
        added_columns => [...],
        modified_columns => {
            column1 => {
                old_type => '...',
                new_type => '...',
                ...
            },
        },
    }

_
    args => {
        %diff_table_args,
    },
    args_as => "array",
    result_naked => 1,
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub diff_table_schema {
    my $dbh1    = shift; my $arg_err; { no warnings ('void');require Scalar::Util;((defined($dbh1)) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::blessed($dbh1)) ? 1 : (($arg_err //= "Not of type object"),0)); if ($arg_err) { die "diff_table_schema(): " . "Invalid argument value for dbh1: $arg_err" } } # VALIDATE_ARG
    my $dbh2    = shift; { no warnings ('void');((defined($dbh2)) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::blessed($dbh2)) ? 1 : (($arg_err //= "Not of type object"),0)); if ($arg_err) { die "diff_table_schema(): " . "Invalid argument value for dbh2: $arg_err" } } # VALIDATE_ARG
    my $table1  = shift; { no warnings ('void');((defined($table1)) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($table1)) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { die "diff_table_schema(): " . "Invalid argument value for table1: $arg_err" } } # VALIDATE_ARG
    my $table2  = shift // $table1; { no warnings ('void');((defined($table2)) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((!ref($table2)) ? 1 : (($arg_err //= "Not of type text"),0)); if ($arg_err) { die "diff_table_schema(): " . "Invalid argument value for table2: $arg_err" } } # VALIDATE_ARG

    #$log->tracef("Comparing table %s vs %s ...", $table1, $table2);

    die "Table $table1 in first database does not exist"
        unless check_table_exists($dbh1, $table1);
    die "Table $table2 in second database does not exist"
        unless check_table_exists($dbh2, $table2);
    _diff_table_schema($dbh1, $dbh2, $table1, $table2);
}

$SPEC{table_schema_eq} = {
    v => 1.1,
    summary => 'Return true if two DBI tables have the same schema',
    description => <<'_',

This is basically just a shortcut for:

    my $res = diff_table_schema(...);
    !%res;

_
    args => {
        %diff_table_args,
    },
    args_as => "array",
    result_naked => 1,
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub table_schema_eq {
    my $res = diff_table_schema(@_);
    !%$res;
}

$SPEC{diff_db_schema} = {
    v => 1.1,
    summary => 'Compare schemas of two DBI databases',
    description => <<'_',

This function compares schemas of two DBI databases. You supply two `DBI`
database handles and this function will return a hash:

    {
        # list of tables found in first db but missing in second
        deleted_tables => ['table1', ...],

        # list of tables found only in the second db
        added_tables => ['table2', ...],

        # list of modified tables, with details for each
        modified_tables => {
            table3 => {
                deleted_columns => [...],
                added_columns => [...],
                modified_columns => {
                    column1 => {
                        old_type => '...',
                        new_type => '...',
                        ...
                    },
                },
            },
        },
    }

_
    args => {
        %diff_db_args,
    },
    args_as => "array",
    result_naked => 1,
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub diff_db_schema {
    my $dbh1 = shift; my $arg_err; { no warnings ('void');require Scalar::Util;((defined($dbh1)) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::blessed($dbh1)) ? 1 : (($arg_err //= "Not of type object"),0)); if ($arg_err) { die "diff_db_schema(): " . "Invalid argument value for dbh1: $arg_err" } } # VALIDATE_ARG
    my $dbh2 = shift; { no warnings ('void');((defined($dbh2)) ? 1 : (($arg_err //= "Required but not specified"),0)) && ((Scalar::Util::blessed($dbh2)) ? 1 : (($arg_err //= "Not of type object"),0)); if ($arg_err) { die "diff_db_schema(): " . "Invalid argument value for dbh2: $arg_err" } } # VALIDATE_ARG

    my @tables1 = list_tables($dbh1);
    my @tables2 = list_tables($dbh2);

    log_trace("tables1: %s ...", \@tables1);
    log_trace("tables2: %s ...", \@tables2);

    my (@added, @deleted, %modified);
    for my $t (@tables1) {
        if (grep {$_ eq $t} @tables2) {
            #$log->tracef("Comparing table %s ...", $_);
            my $tres = _diff_table_schema($dbh1, $dbh2, $t, $t);
            $modified{$t} = $tres if %$tres;
        } else {
            push @deleted, $t;
        }
    }
    for my $t (@tables2) {
        if (grep {$_ eq $t} @tables1) {
        } else {
            push @added, $t;
        }
    }

    my $res = {};
    $res->{added_tables}    = \@added    if @added;
    $res->{deleted_tables}  = \@deleted  if @deleted;
    $res->{modified_tables} = \%modified if %modified;
    $res;
}

$SPEC{db_schema_eq} = {
    v => 1.1,
    summary => 'Return true if two DBI databases have the same schema',
    description => <<'_',

This is basically just a shortcut for:

    my $res = diff_db_schema(...);
    !%$res;

_
    args => {
        %diff_db_args,
    },
    args_as => "array",
    result_naked => 1,
    "x.perinci.sub.wrapper.disable_validate_args" => 1,
};
sub db_schema_eq {
    my $res = diff_db_schema(@_);
    !%$res;
}

1;
# ABSTRACT: Compare schema of two DBI databases

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Diff::Schema - Compare schema of two DBI databases

=head1 VERSION

This document describes version 0.096 of DBIx::Diff::Schema (from Perl distribution DBIx-Diff-Schema), released on 2020-04-23.

=head1 SYNOPSIS

 use DBIx::Diff::Schema qw(diff_db_schema diff_table_schema
                           db_schema_eq table_schema_eq);

To compare schemas of whole databases:

 my $res = diff_db_schema($dbh1, $dbh2);
 say "the two dbs are equal" if db_schema_eq($dbh1, $dbh2);

To compare schemas of a single table from two databases:

 my $res = diff_table_schema($dbh1, $dbh2, 'tablename');
 say "the two tables are equal" if table_schema_eq($dbh1, $dbh2, 'tablename');

=head1 DESCRIPTION

Currently only tested on Postgres and SQLite.

=head1 FUNCTIONS


=head2 check_table_exists

Usage:

 check_table_exists($dbh, $table) -> any

Check whether a table exists.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 db_schema_eq

Usage:

 db_schema_eq($dbh1, $dbh2) -> any

Return true if two DBI databases have the same schema.

This is basically just a shortcut for:

 my $res = diff_db_schema(...);
 !%$res;

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh1>* => I<obj>

DBI database handle for the first database.

=item * B<$dbh2>* => I<obj>

DBI database handle for the second database.


=back

Return value:  (any)



=head2 diff_db_schema

Usage:

 diff_db_schema($dbh1, $dbh2) -> any

Compare schemas of two DBI databases.

This function compares schemas of two DBI databases. You supply two C<DBI>
database handles and this function will return a hash:

 {
     # list of tables found in first db but missing in second
     deleted_tables => ['table1', ...],
 
     # list of tables found only in the second db
     added_tables => ['table2', ...],
 
     # list of modified tables, with details for each
     modified_tables => {
         table3 => {
             deleted_columns => [...],
             added_columns => [...],
             modified_columns => {
                 column1 => {
                     old_type => '...',
                     new_type => '...',
                     ...
                 },
             },
         },
     },
 }

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh1>* => I<obj>

DBI database handle for the first database.

=item * B<$dbh2>* => I<obj>

DBI database handle for the second database.


=back

Return value:  (any)



=head2 diff_table_schema

Usage:

 diff_table_schema($dbh1, $dbh2, $table1, $table2) -> any

Compare schema of two DBI tables.

This function compares schemas of two DBI tables. You supply two C<DBI> database
handles along with table name and this function will return a hash:

 {
     deleted_columns => [...],
     added_columns => [...],
     modified_columns => {
         column1 => {
             old_type => '...',
             new_type => '...',
             ...
         },
     },
 }

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh1>* => I<obj>

DBI database handle for the first database.

=item * B<$dbh2>* => I<obj>

DBI database handle for the second database.

=item * B<$table1>* => I<str>

Table name.

=item * B<$table2> => I<str>

Second table name (assumed to be the same as first table name if unspecified).


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

General notes: information is retrieved from DBI's table_info().

SQLite notes: autoindex for primary key is also listed as the first index, if it
exists. This information is retrieved using "SELECT * FROM sqlite_master".
Autoindex is not listed using table_info().

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh>* => I<obj>

DBI database handle.

=item * B<$table>* => I<str>

Table name.


=back

Return value:  (any)



=head2 list_table_indexes

Usage:

 list_table_indexes($dbh, $table) -> any

List indexes for a table in a database.

General notes: information is retrieved from DBI's table_info().

SQLite notes: autoindex for primary key is also listed as the first index, if it
exists. This information is retrieved using "SELECT * FROM sqlite_master".
Autoindex is not listed using table_info().

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



=head2 table_schema_eq

Usage:

 table_schema_eq($dbh1, $dbh2, $table1, $table2) -> any

Return true if two DBI tables have the same schema.

This is basically just a shortcut for:

 my $res = diff_table_schema(...);
 !%res;

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$dbh1>* => I<obj>

DBI database handle for the first database.

=item * B<$dbh2>* => I<obj>

DBI database handle for the second database.

=item * B<$table1>* => I<str>

Table name.

=item * B<$table2> => I<str>

Second table name (assumed to be the same as first table name if unspecified).


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DBIx-Diff-Schema>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DBIx-Diff-Schema>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Diff-Schema>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBIx::Compare> to compare database contents.

L<diffdb> from L<App::diffdb> which can compare two database (schema as well as
content) and display the result as the familiar colored unified-style diff.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
