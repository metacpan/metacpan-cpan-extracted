package App::SQLiteUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Expect;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-13'; # DATE
our $DIST = 'App-SQLiteUtils'; # DIST
our $VERSION = '0.005'; # VERSION

our %SPEC;

sub _connect {
    require DBI;

    my $args = shift;
    DBI->connect("dbi:SQLite:dbname=$args->{db_file}", undef, undef, {RaiseError=>1});
}

our %args_common = (
    db_file => {
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

our %arg1_table = (
    table => {
        schema => ['str*', min_len=>1],
        req => 1,
        pos => 1,
    },
);

our %argopt_table = (
    table => {
        schema => 'str*',
    },
);

$SPEC{list_sqlite_tables} = {
    v => 1.1,
    description => <<'_',

See also the `.tables` meta-command of the `sqlite3` CLI.

_
    args => {
        %args_common,
    },
    result_naked => 1,
};
sub list_sqlite_tables {
    require DBIx::Util::Schema;

    my %args = @_;
    my $dbh = _connect(\%args);
    [DBIx::Util::Schema::list_tables($dbh)];
}

$SPEC{list_sqlite_columns} = {
    v => 1.1,
    description => <<'_',

See also the `.schema` and `.fullschema` meta-command of the `sqlite3` CLI.

_
    args => {
        %args_common,
        %arg1_table,
    },
    result_naked => 1,
};
sub list_sqlite_columns {
    require DBIx::Util::Schema;

    my %args = @_;
    my $dbh = _connect(\%args);
    [DBIx::Util::Schema::list_columns($dbh, $args{table})];
}

$SPEC{import_csv_to_sqlite} = {
    v => 1.1,
    summary => 'Import a CSV file into SQLite database',
    description => <<'_',

This tool utilizes the `sqlite3` command-line client to import a CSV file into
SQLite database. It pipes the following commands to the `sqlite3` CLI:

    .mode csv
    .import CSVNAME TABLENAME

where CSVNAME is the CSV filename and TABLENAME is the table name.

If CSV filename is not specified, will be assumed to be `-` (stdin).

If table name is not specified, it will be derived from the CSV filename
(basename) with extension removed. `-` will become `stdin`. All non-alphanumeric
characters will be replaced with `_` (underscore). If filename starts with
number, `t` prefix will be added. If table already exists, a suffix of `_2`,
`_3`, and so on will be added. Some examples:

    CSV filename          Table name         Note
    ------------          ----------         ----
    -                     stdin
    -                     stdin_2            If 'stdin` already exists
    /path/to/t1.csv       t1
    /path/to/t1.csv       t1_2               If 't1` already exists
    /path/to/t1.csv       t1_3               If 't1` and `t1_2` already exist
    ./2.csv               t2
    report 2021.csv       report_2021
    report 2021.rev1.csv  report_2021

Note that the **sqlite3** CLI client can be used non-interactively as well. You
can pipe the commands to its stdin, e.g.:

    % echo -e ".mode csv\n.import /PATH/TO/FILE.CSV TABLENAME" | sqlite3 DB_FILE

But this utility gives you convenience of picking a table name automatically.

_
    args => {
        %args_common,
        csv_file => {
            schema => 'filename*',
            default => '-',
            pos => 1,
        },
        %argopt_table,
        # XXX allow customizing Expect timeout, for larger table
    },
    deps => {
        prog => 'sqlite3', # XXX allow customizing path?
    },
};
sub import_csv_to_sqlite {
    require DBIx::Util::Schema;
    require Expect;
    require File::Temp;
    require String::ShellQuote;

    my %args = @_;
    my $csv_file = $args{csv_file} // '-';

    my $dbh = _connect(\%args);

    my $table = $args{table};
  PICK_TABLE_NAME: {
        last if defined $table;
        if ($csv_file eq '-') {
            $table = 'stdin';
            last;
        }
        $table = $csv_file;
        $table =~ s!.+/!!;
        $table =~ s!(?:\.\w+)+\z!!;
        $table =~ s!\W+!_!g;
        $table = "t" unless length $table;
        $table = "t$table" if $table =~ /\A[0-9]/;
        my $table0 = $table;
        my $i = 1;
        while (DBIx::Util::Schema::table_exists($dbh, $table)) {
            $i++;
            $table = "${table0}_$i";
        }
        log_trace "Picking table name: %s", $table;
    }

    if ($csv_file eq '-') {
        my ($tempfh, $tempfile) = File::Temp::tempfile();
        print $tempfh while <STDIN>;
        close $tempfh;
        $csv_file = $tempfile;
    }

    $dbh->disconnect; # we're releasing any locks, for sqlite3 CLI client

    my $exp = Expect->spawn("sqlite3", $args{db_file})
        or die "import_csv_to_sqlite(): Cannot spawn command: $!\n";
    if (log_is_trace()) { $exp->exp_internal(1) }
    unless (log_is_trace()) { $exp->log_stdout(0) }
    #$exp->debug(3);

    $exp->expect(
        2,
        [
            qr/sqlite> $/,
            sub {
                my $self = shift;
                $exp->clear_accum;
                $exp->send(".mode csv\n");
            },
        ],
        [
            'eof',
            sub {
                die "sqlite3 exits prematurely";
            },
        ],
        [
            'timeout',
            sub {
                die "Unexpected sqlite3 response";
            },
        ],
    );

    $exp->expect(
        2,
        [
            qr/sqlite> $/,
            sub {
                my $self = shift;
                $exp->clear_accum;
                $exp->send(".import ". String::ShellQuote::shell_quote($csv_file) . " \"" . $table . "\"\n");
            },
        ],
        [
            'eof',
            sub {
                die "sqlite3 exits prematurely";
            },
        ],
        [
            'timeout',
            sub {
                die "Unexpected sqlite3 response";
            },
        ],
    );

    my $err;
    $exp->expect(
        30,
        [
            qr/Error: (.+)/,
            sub {
                my $self = shift;
                $exp->clear_accum;
                my @m = $exp->matchlist;
                $err = $m[0];
            },
        ],
        [
            qr/sqlite> $/,
            sub {
                my $self = shift;
                # import success
            },
        ],
        [
            'eof',
            sub {
                die "sqlite3 exits prematurely";
            },
        ],
        [
            'timeout',
            sub {
                die "Unexpected sqlite3 response";
            },
        ],
    );

    # there's still a ~1 second delay which i don't know how to avoid yet,
    # including with hard_close().
    #$exp->hard_close;

    if ($err) {
        return [500, "Can't import: $err"];
    }

    [200, "OK", undef, {
        'func.table' => $table,
        'cmdline.result' => "Imported to table $table",
    }];
}

1;
# ABSTRACT: Utilities related to SQLite

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SQLiteUtils - Utilities related to SQLite

=head1 VERSION

This document describes version 0.005 of App::SQLiteUtils (from Perl distribution App-SQLiteUtils), released on 2021-09-13.

=head1 DESCRIPTION

This distribution includes several utilities:

=over

=item * L<import-csv-to-sqlite>

=item * L<list-sqlite-columns>

=item * L<list-sqlite-tables>

=back

=head1 FUNCTIONS


=head2 import_csv_to_sqlite

Usage:

 import_csv_to_sqlite(%args) -> [$status_code, $reason, $payload, \%result_meta]

Import a CSV file into SQLite database.

This tool utilizes the C<sqlite3> command-line client to import a CSV file into
SQLite database. It pipes the following commands to the C<sqlite3> CLI:

 .mode csv
 .import CSVNAME TABLENAME

where CSVNAME is the CSV filename and TABLENAME is the table name.

If CSV filename is not specified, will be assumed to be C<-> (stdin).

If table name is not specified, it will be derived from the CSV filename
(basename) with extension removed. C<-> will become C<stdin>. All non-alphanumeric
characters will be replaced with C<_> (underscore). If filename starts with
number, C<t> prefix will be added. If table already exists, a suffix of C<_2>,
C<_3>, and so on will be added. Some examples:

 CSV filename          Table name         Note
 ------------          ----------         ----
 -                     stdin
 -                     stdin_2            If 'stdinC<already exists
 /path/to/t1.csv       t1
 /path/to/t1.csv       t1_2               If 't1> already exists
 /path/to/t1.csv       t1_3               If 't1C<and>t1_2` already exist
 ./2.csv               t2
 report 2021.csv       report_2021
 report 2021.rev1.csv  report_2021

Note that the B<sqlite3> CLI client can be used non-interactively as well. You
can pipe the commands to its stdin, e.g.:

 % echo -e ".mode csv\n.import /PATH/TO/FILE.CSV TABLENAME" | sqlite3 DB_FILE

But this utility gives you convenience of picking a table name automatically.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<csv_file> => I<filename> (default: "-")

=item * B<db_file>* => I<filename>

=item * B<table> => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_sqlite_columns

Usage:

 list_sqlite_columns(%args) -> any

See also the C<.schema> and C<.fullschema> meta-command of the C<sqlite3> CLI.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_file>* => I<filename>

=item * B<table>* => I<str>


=back

Return value:  (any)



=head2 list_sqlite_tables

Usage:

 list_sqlite_tables(%args) -> any

See also the C<.tables> meta-command of the C<sqlite3> CLI.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_file>* => I<filename>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SQLiteUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SQLiteUtils>.

=head1 SEE ALSO

L<App::DBIUtils>

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

This software is copyright (c) 2021 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SQLiteUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
