package App::dbinfo;

our $DATE = '2018-04-03'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get/extract information from database',
};

our %args_common = (
    dsn => {
        summary => 'DBI data source, '.
            'e.g. "dbi:SQLite:dbname=/path/to/db.db"',
        schema => 'str*',
        tags => ['connection', 'common'],
        pos => 0,
    },
    user => {
        schema => 'str*',
        cmdline_aliases => {u=>{}},
        tags => ['connection', 'common'],
    },
    password => {
        schema => 'str*',
        cmdline_aliases => {p=>{}},
        tags => ['connection', 'common'],
        description => <<'_',

You might want to specify this parameter in a configuration file instead of
directly as command-line option.

_
    },
    dbh => {
        summary => 'Alternative to specifying dsn/user/password (from Perl)',
        schema => 'obj*',
        tags => ['connection', 'common', 'hidden-cli'],
    },
);

our %args_rels_common = (
    'req_one&' => [
        [qw/dsn dbh/],
    ],
);

our %arg_table = (
    table => {
        summary => 'Table name',
        schema => 'str*',
        req => 1,
        pos => 1,
    },
);

our %arg_detail = (
    detail => {
        summary => 'Show detailed information per record',
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

sub __json_encode {
    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new->canonical(1);
    };
    $json->encode(shift);
}

sub _connect {
    require DBI;

    my $args = shift;

    return $args->{dbh} if $args->{dbh};
    DBI->connect($args->{dsn}, $args->{user}, $args->{password},
                 {RaiseError=>1});
}

$SPEC{list_tables} = {
    v => 1.1,
    summary => 'List tables in the database',
    args => {
        %args_common,
    },
    args_rels => {
        %args_rels_common,
    },
};
sub list_tables {
    require DBIx::Diff::Schema;

    my %args = @_;

    my $dbh = _connect(\%args);

    return [200, "OK", [
            DBIx::Diff::Schema::_list_tables($dbh)]];
}

$SPEC{list_columns} = {
    v => 1.1,
    summary => 'List columns of a table',
    args => {
        %args_common,
        %arg_table,
        %arg_detail,
    },
    args_rels => {
        %args_rels_common,
    },
    examples => [
        {
            args => {dsn=>'dbi:SQLite:database=/tmp/test.db', table=>'main.table1'},
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_columns {
    require DBIx::Diff::Schema;

    my %args = @_;

    my $dbh = _connect(\%args);

    my $ltres = list_tables(%args);
    return [500, "Can't list tables: $ltres->[0] - $ltres->[1]"]
        unless $ltres->[0] == 200;
    my $tables = $ltres->[2];
    #my $tables_wo_schema = [map {my $n=$_; $n=~s/.+\.//; $n} @$tables];
    #return [404, "No such table '$args{table}'"]
    #    unless grep { $args{table} eq $_ } (@$tables, @$tables_wo_schema);
    return [404, "No such table '$args{table}'"]
        unless grep { $args{table} eq $_ } @$tables;

    my @cols = DBIx::Diff::Schema::_list_columns($dbh, $args{table});
    @cols = map { $_->{COLUMN_NAME} } @cols unless $args{detail};
    return [200, "OK", \@cols];
}

our %args_dump_table = (
    row_format => {
        schema => ['str*', in=>['array', 'hash']],
        default => 'hash',
        cmdline_aliases => {
            array => { summary => 'Shortcut for --row-format=array', is_flag=>1, code => sub { $_[0]{row_format} = 'array' } },
            a     => { summary => 'Shortcut for --row-format=array', is_flag=>1, code => sub { $_[0]{row_format} = 'array' } },
        },
    },
    exclude_columns => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'exclude_column',
        schema => ['array*', {
            of=>'str*',
            #'x.perl.coerce_rules'=>['str_comma_sep'],
        }],
        cmdline_aliases => {C=>{}},
    },
    include_columns => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'include_column',
        schema => ['array*', {
            of=>'str*',
            #'x.perl.coerce_rules'=>['str_comma_sep'],
        }],
        cmdline_aliases => {c=>{}},
    },
    wheres => {
        summary => 'Add WHERE clause',
        'x.name.is_plural' => 1,
        'x.name.singular' => 'where',
        schema => ['array*', {
            of=>'str*',
        }],
        cmdline_aliases => {w=>{}},
    },
    limit_number => {
        schema => 'uint*',
        cmdline_aliases => {n=>{}},
    },
    limit_offset => {
        schema => 'uint*',
        cmdline_aliases => {o=>{}},
    },
);

$SPEC{dump_table} = {
    v => 1.1,
    summary => 'Dump table into various formats',
    args => {
        %args_common,
        %arg_table,
        %args_dump_table,
    },
    args_rels => {
        %args_rels_common,
    },
    result => {
        schema => 'str*',
    },
    examples => [
        {
            argv => [qw/table1/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Only include specified columns',
            argv => [qw/table2 -c col1 -c col2/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Exclude some columns',
            argv => [qw/table3 -C col1 -C col2/],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'Select some rows',
            argv => ['table4', '-w', q(name LIKE 'John*'), '-n', 10],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub dump_table {
    require DBIx::Diff::Schema;

    my %args = @_;
    my $table = $args{table};
    my $is_hash = $args{row_format} eq 'array' ? 0:1;

    # let's ignore schema for now
    $table =~ s/.+\.//;

    $is_hash++ if $args{exclude_columns} && @{$args{exclude_columns}};

    my $dbh = _connect(\%args);

    my $col_term = "*";
    if ($args{include_columns} && @{$args{include_columns}}) {
        $col_term = join(",", map {$dbh->quote_identifier($_)} @{$args{include_columns}});
    }

    my $wheres = $args{wheres};
    my $sql = join(
        "",
        "SELECT $col_term FROM ", $dbh->quote_identifier($table),
        ($args{wheres} && @{$args{wheres}} ?
             " WHERE ".join(" AND ", @{$args{wheres}}) : ""),
        # XXX what about database that don't support LIMIT clause?
        (defined $args{limit_offset} ? " LIMIT $args{limit_offset},".($args{limit_number} // "-1") :
             defined $args{limit_number} ? " LIMIT $args{limit_number}" : ""),
    );

    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my $code_get_row = sub {
        my $row;
        if ($is_hash) {
            $row = $sth->fetchrow_hashref;
            return undef unless $row;
            if ($args{exclude_columns} && @{$args{exclude_columns}}) {
                for (@{ $args{exclude_columns} }) {
                    delete $row->{$_};
                }
            }
        } else {
            $row = $sth->fetchrow_arrayref;
            return undef unless $row;
        }
        __json_encode($row);
    };

    [200, "OK", $code_get_row, {stream=>1}];
}


1;
# ABSTRACT: Get/extract information from database

__END__

=pod

=encoding UTF-8

=head1 NAME

App::dbinfo - Get/extract information from database

=head1 VERSION

This document describes version 0.004 of App::dbinfo (from Perl distribution App-dbinfo), released on 2018-04-03.

=head1 SYNOPSIS

See included script L<dbinfo>.

=head1 FUNCTIONS


=head2 dump_table

Usage:

 dump_table(%args) -> [status, msg, result, meta]

Dump table into various formats.

Examples:

=over

=item * Example #1:

 dump_table( dsn => "table1");

=item * Only include specified columns:

 dump_table( dsn => "table2", include_columns => ["col1", "col2"]);

=item * Exclude some columns:

 dump_table( dsn => "table3", exclude_columns => ["col1", "col2"]);

=item * Select some rows:

 dump_table( dsn => "table4", limit_number => 10, wheres => ["name LIKE 'John*'"]);

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

Alternative to specifying dsn/user/password (from Perl).

=item * B<dsn> => I<str>

DBI data source, e.g. "dbi:SQLite:dbname=/path/to/db.db".

=item * B<exclude_columns> => I<array[str]>

=item * B<include_columns> => I<array[str]>

=item * B<limit_number> => I<uint>

=item * B<limit_offset> => I<uint>

=item * B<password> => I<str>

You might want to specify this parameter in a configuration file instead of
directly as command-line option.

=item * B<row_format> => I<str> (default: "hash")

=item * B<table>* => I<str>

Table name.

=item * B<user> => I<str>

=item * B<wheres> => I<array[str]>

Add WHERE clause.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (str)


=head2 list_columns

Usage:

 list_columns(%args) -> [status, msg, result, meta]

List columns of a table.

Examples:

=over

=item * Example #1:

 list_columns(dsn => "dbi:SQLite:database=/tmp/test.db", table => "main.table1");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

Alternative to specifying dsn/user/password (from Perl).

=item * B<detail> => I<bool>

Show detailed information per record.

=item * B<dsn> => I<str>

DBI data source, e.g. "dbi:SQLite:dbname=/path/to/db.db".

=item * B<password> => I<str>

You might want to specify this parameter in a configuration file instead of
directly as command-line option.

=item * B<table>* => I<str>

Table name.

=item * B<user> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_tables

Usage:

 list_tables(%args) -> [status, msg, result, meta]

List tables in the database.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

Alternative to specifying dsn/user/password (from Perl).

=item * B<dsn> => I<str>

DBI data source, e.g. "dbi:SQLite:dbname=/path/to/db.db".

=item * B<password> => I<str>

You might want to specify this parameter in a configuration file instead of
directly as command-line option.

=item * B<user> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-dbinfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-dbinfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-dbinfo>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI>

L<App::diffdb>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
