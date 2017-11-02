package App::mysqlinfo;

our $DATE = '2017-10-30'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use App::dbinfo ();

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Get/extract information from MySQL database',
};

our %args_common = (
    dbname => {
        schema => 'str*',
        tags => ['connection', 'common'],
        pos => 0,
    },
    host => {
        schema => 'str*', # XXX hostname
        tags => ['connection', 'common'],
    },
    port => {
        schema => ['int*', min=>1, max=>65535], # XXX port
        tags => ['connection', 'common'],
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
        [qw/dbname dbh/],
    ],
);

our %arg_table = %App::dbinfo::arg_table;

our %arg_detail = %App::dbinfo::arg_detail;

sub __json_encode {
    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new->canonical(1);
    };
    $json->encode(shift);
}

sub _connect {
    require DBIx::Connect::MySQL;

    my $args = shift;

    return $args->{dbh} if $args->{dbh};
    DBIx::Connect::MySQL->connect(
        join(
            "",
            "DBI:mysql:database=$args->{dbname}",
            (defined $args->{host} ? ";host=$args->{host}" : ""),
            (defined $args->{port} ? ";port=$args->{port}" : ""),
        ),
        $args->{user}, $args->{password},
        {RaiseError=>1});
}

sub _preprocess_args {
    my $args = shift;

    if ($args->{dbh}) {
        return $args;
    }
    $args->{dbh} = _connect($args);
    $args->{_dbname} = delete $args->{dbname};

    if (defined $args->{table}) {
        $args->{table} = "$args->{_dbname}.$args->{table}"
            unless $args->{table} =~ /\./;
    }

    $args;
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
    my %args = @_;

    _preprocess_args(\%args);
    my $res = App::dbinfo::list_tables(%args);
    if ($res->[0] == 200) {
        for (@{ $res->[2] }) { s/^\Q$args{_dbname}\E\.// }
    }
    $res;
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
            args => {dbname=>'test', table=>'main.table1'},
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_columns {
    my %args = @_;
    _preprocess_args(\%args);
    App::dbinfo::list_columns(%args);
}

$SPEC{dump_table} = {
    v => 1.1,
    summary => 'Dump table into various formats',
    args => {
        %args_common,
        %arg_table,
        %App::dbinfo::args_dump_table,
    },
    args_rels => {
        %args_rels_common,
    },
    result => {
        schema => 'str*',
    },
    examples => [
    ],
};
sub dump_table {
    my %args = @_;
    _preprocess_args(\%args);
    App::dbinfo::dump_table(%args);
}


1;
# ABSTRACT: Get/extract information from MySQL database

__END__

=pod

=encoding UTF-8

=head1 NAME

App::mysqlinfo - Get/extract information from MySQL database

=head1 VERSION

This document describes version 0.001 of App::mysqlinfo (from Perl distribution App-mysqlinfo), released on 2017-10-30.

=head1 SYNOPSIS

See included script L<mysqlinfo>.

=head1 FUNCTIONS


=head2 dump_table

Usage:

 dump_table(%args) -> [status, msg, result, meta]

Dump table into various formats.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

Alternative to specifying dsn/user/password (from Perl).

=item * B<dbname> => I<str>

=item * B<exclude_columns> => I<array[str]>

=item * B<host> => I<str>

=item * B<include_columns> => I<array[str]>

=item * B<limit_number> => I<nonnegint>

=item * B<limit_offset> => I<nonnegint>

=item * B<password> => I<str>

You might want to specify this parameter in a configuration file instead of
directly as command-line option.

=item * B<port> => I<int>

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

 list_columns(dbname => "test", table => "main.table1");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

Alternative to specifying dsn/user/password (from Perl).

=item * B<dbname> => I<str>

=item * B<detail> => I<bool>

Show detailed information per record.

=item * B<host> => I<str>

=item * B<password> => I<str>

You might want to specify this parameter in a configuration file instead of
directly as command-line option.

=item * B<port> => I<int>

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

=item * B<dbname> => I<str>

=item * B<host> => I<str>

=item * B<password> => I<str>

You might want to specify this parameter in a configuration file instead of
directly as command-line option.

=item * B<port> => I<int>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-mysqlinfo>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-mysqlinfo>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-mysqlinfo>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DBI>

L<App::dbinfo>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
