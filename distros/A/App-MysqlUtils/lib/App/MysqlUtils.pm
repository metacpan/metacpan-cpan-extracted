package App::MysqlUtils;

our $DATE = '2016-12-23'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use Perinci::Object;

our %SPEC;

my %args_common = (
    host => {
        schema => 'str*', # XXX hostname
        default => 'localhost',
        tags => ['category:connection'],
    },
    port => {
        schema => ['int*', min=>1, max=>65535], # XXX port
        default => '3306',
        tags => ['category:connection'],
    },
    username => {
        schema => 'str*',
        tags => ['category:connection'],
    },
    password => {
        schema => 'str*',
        tags => ['category:connection'],
    },
);

my %args_database = (
    database => {
        schema => 'str*',
        req => 1,
        pos => 0,
        completion => \&_complete_database,
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'CLI utilities related to MySQL',
};

sub _connect {
    my %args = @_;

    unless (defined $args{username} && defined $args{password}) {
        if (-f (my $path = "$ENV{HOME}/.my.cnf")) {
            require Config::IOD::Reader;
            my $iod = Config::IOD::Reader->new();
            my $hoh = $iod->read_file($path);
            $args{username} //= $hoh->{client}{user};
            $args{password} //= $hoh->{client}{password};
        }
    }

    require DBI;
    my $dbh = DBI->connect(
        "DBI:mysql:".
            join(";",
                 (defined $args{database} ? ("database=$args{database}") : ()),
                 (defined $args{host} ? ("host=$args{host}") : ()),
                 (defined $args{port} ? ("port=$args{port}") : ()),
             ),
        $args{username},
        $args{password},
        {RaiseError => $args{_raise_error} // 1},
    );
}

sub _complete_database {
    require Complete::Util;
    my %args = @_;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $dbh = _connect(%{ $res->[2] }, database=>undef) or return undef;

    my @dbs;
    my $sth = $dbh->prepare("SHOW DATABASES");
    $sth->execute;
    while (my @row = $sth->fetchrow_array) {
        push @dbs, $row[0];
    }
    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => \@dbs,
    );
}

sub _complete_table {
    require Complete::Util;
    my %args = @_;

    # only run under pericmd
    my $cmdline = $args{cmdline} or return undef;
    my $r = $args{r};

    # force read config file, because by default it is turned off when in
    # completion
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $dbh = _connect(%{ $res->[2] }) or return undef;

    my @names = $dbh->tables(undef, undef, undef, undef);
    my @tables;
    for (@names) {
        /\A`(.+)`\.`(.+)`\z/ or next;
        push @tables, $2;
    }
    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => \@tables,
    );
}

$SPEC{mysql_drop_all_tables} = {
    v => 1.1,
    summary => 'Drop all tables in a MySQL database',
    description => <<'_',

For safety, the default is dry-run mode. To actually drop the tables, you must
supply `--no-dry-run` or DRY_RUN=0.

_
    args => {
        %args_common,
        %args_database,
    },
    features => {
        dry_run => {default=>1},
    },
};
sub mysql_drop_all_tables {
    my %args = @_;

    my $dbh = _connect(%args);

    my @names = $dbh->tables(undef, undef, undef, undef);

    my $res = envresmulti();
    for (@names) {
        if ($args{-dry_run}) {
            $log->infof("[DRY_RUN] Dropping table %s ...", $_);
            $res->add_result(304, "OK (dry-run)", {item_id=>$_});
        } else {
            $log->infof("Dropping table %s ...", $_);
            $dbh->do("DROP TABLE $_");
            $res->add_result(200, "OK", {item_id=>$_});
        }
    }
    $res->as_struct;
}

$SPEC{mysql_drop_tables} = {
    v => 1.1,
    summary => 'Drop tables in a MySQL database',
    description => <<'_',

For safety, the default is dry-run mode. To actually drop the tables, you must
supply `--no-dry-run` or DRY_RUN=0.

Examples:

    # Drop table T1, T2, T3 (dry-run mode)
    % mysql-drop-tables DB T1 T2 T3

    # Drop all tables with names matching /foo/ (dry-run mode)
    % mysql-drop-tables DB --table-pattern foo

    # Actually drop all tables with names matching /foo/, don't delete more than 5 tables
    % mysql-drop-tables DB --table-pattern foo --limit 5 --no-dry-run

_
    args => {
        %args_common,
        %args_database,
        tables => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'table',
            schema => ['array*', of=>'str*'],
            element_completion => \&_complete_table,
            pos => 1,
            greedy => 1,
        },
        table_pattern => {
            schema => 're*',
        },
        limit => {
            summary => "Don't delete more than this number of tables",
            schema => 'posint*',
        },
    },
    args_rels => {
        req_one => [qw/tables table_pattern/],
    },
    features => {
        dry_run => {default=>1},
    },
};
sub mysql_drop_tables {
    my %args = @_;

    my $dbh = _connect(%args);

    my @names = $dbh->tables(undef, undef, undef, undef);

    my $res = envresmulti();
    my $n = 0;
  TABLE:
    for my $name (@names) {
        my ($schema, $table) = $name =~ /\A`(.+)`\.`(.+)`\z/
            or die "Invalid table name returned by \$dbh->tables() ($name), expecting `schema`.`table`";

        if ($args{tables}) {
            my $found;
            for (@{ $args{tables} }) {
                if ($_ eq $table) {
                    $found++; last;
                }
            }
            next TABLE unless $found;
        }
        if ($args{table_pattern}) {
            next TABLE unless $table =~ /$args{table_pattern}/;
        }
        $n++;
        if (defined $args{limit} && $n > $args{limit}) {
            last;
        }

        if ($args{-dry_run}) {
            $log->infof("[DRY_RUN] Dropping table %s ...", $name);
            $res->add_result(304, "OK (dry-run)", {item_id=>$name});
        } else {
            $log->infof("Dropping table %s ...", $name);
            $dbh->do("DROP TABLE $name");
            $res->add_result(200, "OK", {item_id=>$name});
        }
    }
    $res->as_struct;
}

$SPEC{mysql_query} = {
    v => 1.1,
    summary => 'Run query and return table result',
    description => <<'_',

This is like just regular querying, but the result will be returned as table
data (formattable using different backends). Or, you can output as JSON.

Examples:

    # by default, show as pretty text table, like in interactive mysql client
    % mysql-query DBNAME "SELECT * FROM t1"

    # show as JSON (array of hashes)
    % mysql-query DBNAME "QUERY..." --json ;# or, --format json

    # show as CSV
    % mysql-query DBNAME "QUERY..." --format csv

    # show as CSV table using Text::Table::CSV
    % FORMAT_PRETTY_TABLE_BACKEND=Text::Table::Org mysql-query DBNAME "QUERY..."

_
    args => {
        %args_common,
        %args_database,
        query => {
            schema => 'str*',
            req => 1,
            pos => 0,
            cmdline_src => 'stdin_or_args',
        },
        add_row_numbers => {
            summary => 'Add first field containing number from 1, 2, ...',
            schema => ['bool*', is=>1],
        },
    },
};
sub mysql_query {
    my %args = @_;

    my $dbh = _connect(%args);

    my $sth = $dbh->prepare($args{query});
    $sth->execute;

    my @columns = @{ $sth->{NAME_lc} };
    if ($args{add_row_numbers}) {
        unshift @columns, "_row"; # XXX what if columns contains '_row' already, we need to supply a unique name e.g. '_row2', ...
    };
    my @rows;
    my $i = 0;
    while (my $row = $sth->fetchrow_hashref) {
        $i++;
        $row->{_row} = $i if $args{add_row_numbers};
        push @rows, $row;
    }

    [200, "OK", \@rows, {'table.fields'=>\@columns}];
}

1;
# ABSTRACT: CLI utilities related to MySQL

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MysqlUtils - CLI utilities related to MySQL

=head1 VERSION

This document describes version 0.003 of App::MysqlUtils (from Perl distribution App-MysqlUtils), released on 2016-12-23.

=head1 SYNOPSIS

This distribution includes the following CLI utilities:

=over

=back

=head1 FUNCTIONS


=head2 mysql_drop_all_tables(%args) -> [status, msg, result, meta]

Drop all tables in a MySQL database.

For safety, the default is dry-run mode. To actually drop the tables, you must
supply C<--no-dry-run> or DRY_RUN=0.

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<database>* => I<str>

=item * B<host> => I<str> (default: "localhost")

=item * B<password> => I<str>

=item * B<port> => I<int> (default: 3306)

=item * B<username> => I<str>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 mysql_drop_tables(%args) -> [status, msg, result, meta]

Drop tables in a MySQL database.

For safety, the default is dry-run mode. To actually drop the tables, you must
supply C<--no-dry-run> or DRY_RUN=0.

Examples:

 # Drop table T1, T2, T3 (dry-run mode)
 % mysql-drop-tables DB T1 T2 T3
 
 # Drop all tables with names matching /foo/ (dry-run mode)
 % mysql-drop-tables DB --table-pattern foo
 
 # Actually drop all tables with names matching /foo/, don't delete more than 5 tables
 % mysql-drop-tables DB --table-pattern foo --limit 5 --no-dry-run

This function is not exported.

This function supports dry-run operation.


Arguments ('*' denotes required arguments):

=over 4

=item * B<database>* => I<str>

=item * B<host> => I<str> (default: "localhost")

=item * B<limit> => I<posint>

Don't delete more than this number of tables.

=item * B<password> => I<str>

=item * B<port> => I<int> (default: 3306)

=item * B<table_pattern> => I<re>

=item * B<tables> => I<array[str]>

=item * B<username> => I<str>

=back

Special arguments:

=over 4

=item * B<-dry_run> => I<bool>

Pass -dry_run=>1 to enable simulation mode.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 mysql_query(%args) -> [status, msg, result, meta]

Run query and return table result.

This is like just regular querying, but the result will be returned as table
data (formattable using different backends). Or, you can output as JSON.

Examples:

 # by default, show as pretty text table, like in interactive mysql client
 % mysql-query DBNAME "SELECT * FROM t1"
 
 # show as JSON (array of hashes)
 % mysql-query DBNAME "QUERY..." --json ;# or, --format json
 
 # show as CSV
 % mysql-query DBNAME "QUERY..." --format csv
 
 # show as CSV table using Text::Table::CSV
 % FORMAT_PRETTY_TABLE_BACKEND=Text::Table::Org mysql-query DBNAME "QUERY..."

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<add_row_numbers> => I<bool>

Add first field containing number from 1, 2, ...

=item * B<database>* => I<str>

=item * B<host> => I<str> (default: "localhost")

=item * B<password> => I<str>

=item * B<port> => I<int> (default: 3306)

=item * B<query>* => I<str>

=item * B<username> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-MysqlUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MysqlUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MysqlUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
