package App::reposdb;

our $DATE = '2016-06-15'; # DATE
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Manipulate repos.db',
    description => <<'_',

`repos.db` is a SQLite database that lists repository names along with some
extra data. They have various uses, but my first use-case for this is to store
last commit/status/pull time (updated via a post-commit git hook or `gitwrap`).
This is useful to speed up like syncing of repositories in `Git::Bunch` that
wants to find out which of the hundreds/thousand+ git repositories are "the most
recently used" to prioritize these repositories first. Using information from
`repos.db` is faster than having to `git status` or even stat() each repository.

_
};

sub _complete_repo {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    _set_args_default($args);

    my $dbh = _connect_db($args);
    my @repos;
    my $sth = $dbh->prepare("SELECT name FROM repos");
    $sth->execute;
    while (my ($n) = $sth->fetchrow_array) {
        push @repos, $n;
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => \@repos,
    );
}

sub _complete_tag {
    my %args = @_;
    my $word    = $args{word} // '';
    my $cmdline = $args{cmdline};
    my $r       = $args{r};

    return undef unless $cmdline;

    # force reading config file
    $r->{read_config} = 1;
    my $res = $cmdline->parse_argv($r);

    my $args = $res->[2];
    _set_args_default($args);

    my $dbh = _connect_db($args);
    my %tags;
    my $sth = $dbh->prepare("SELECT tags FROM repos WHERE tags IS NOT NULL");
    $sth->execute;
    while (my ($t) = $sth->fetchrow_array) {
        my @tags = split /,/, $t;
        $tags{$_} = 1 for @tags;
    }

    require Complete::Util;
    Complete::Util::complete_array_elem(
        word  => $word,
        array => [keys %tags],
    );
}

our $db_schema_spec = {
    latest_v => 3,
    install_v1 => [
        "CREATE TABLE repos (
             name TEXT NOT NULL PRIMARY KEY,
             commit_time INT NOT NULL
         )",
    ],
    upgrade_to_v2 => [
        # we lose data :p but this distro first released at v2 anyway
        "DROP TABLE repos",
        "CREATE TABLE repos (
             name TEXT NOT NULL PRIMARY KEY,
             commit_time INT,
             status_time INT,
             pull_time INT
         )",
    ],
    upgrade_to_v3 => [
        "ALTER TABLE repos ADD COLUMN tags TEXT",
    ],
    install => [
        "CREATE TABLE repos (
             name TEXT NOT NULL PRIMARY KEY,
             commit_time INT,
             status_time INT,
             pull_time INT,
             tags TEXT
         )",
    ],
};

my %common_args = (
    reposdb_path => {
        schema => 'str*', # XXX path
        tags => ['common'],
        req => 1,
    },
);

my %repo_arg = (
    repo => {
        schema => 'str*',
        pos => 0,
        completion => \&_complete_repo,
    },
);

my %tags_arg = (
    tags => {
        'x.name.is_plural' => 1,
        schema => ['array*', of=>'str*'],
        req => 1,
        pos => 1,
        greedy => 1,
        element_completion => \&_complete_tag,
    },
);

sub _set_args_default {
    require Cwd;

    my ($args, $set_repo_default) = @_;

    if ($set_repo_default && !defined($args->{repo})) {
        my $repo;
        {
            my $cwd = Cwd::getcwd();
            while (1) {
                if (-d ".git") {
                    ($repo = $cwd) =~ s!.+/!!;
                    last;
                }
                chdir ".." or last;
                $cwd =~ s!(.+)/.+!$1! or last;
            }
        }
        $args->{repo} = $repo;
    }
}

sub _connect_db {
    require DBI;
    require SQL::Schema::Versioned;

    my $args = shift;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$args->{reposdb_path}", "", "",
                           {RaiseError=>1});
    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        dbh => $dbh, spec => $db_schema_spec);
    die "Cannot create/update database schema: $res->[0] - $res->[1]"
        unless $res->[0] == 200;

    $dbh;
}

$SPEC{list_repos} = {
    v => 1.1,
    summary => 'List repositories registered in repos.db',
    args => {
        %common_args,
        sorts => {
            'x.name.is_plural' => 1,
            schema => ['array*', {
                of => ['str*', in=>[qw/name -name commit_time -commit_time status_time -status_time pull_time -pull_time/]]
            }],
            default => ['name'],
            tags => ['category:sorting'],
        },
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
            tags => ['category:field-selection'],
        },
        has_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'has_tag',
            schema => ['array*', of=>'str*'],
            element_completion => \&_complete_tag,
            tags => ['category:filtering'],
        },
        lacks_tags => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'lacks_tag',
            schema => ['array*', of=>'str*'],
            element_completion => \&_complete_tag,
            tags => ['category:filtering'],
        },
    },
};
sub list_repos {
    my %args = @_;

    _set_args_default(\%args);
    my $dbh = _connect_db(\%args);

    my @orders;
    for my $sort (@{ $args{sorts} }) {
        $sort =~ /\A(-)?(\w+)\z/ or return [400, "Invalid sort order `$sort`"];
        push @orders, $2 . ($1 ? " DESC":"");
    }
    my $sql = "SELECT * FROM repos ORDER BY ".join(", ", @orders);

    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my @res;
  ROW:
    while (my $row = $sth->fetchrow_hashref) {
        if ($args{has_tags} && @{ $args{has_tags} }) {
            my @row_tags = split ',', ($row->{tags} // '');
            my $found;
            for my $t (@{ $args{has_tags} }) {
                if (grep { $t eq $_ } @row_tags) {
                    $found++; last;
                }
            }
            next ROW unless $found;
        }
        if ($args{lacks_tags} && @{ $args{lacks_tags} }) {
            my @row_tags = split ',', ($row->{tags} // '');
            my $found;
            for my $t (@{ $args{lacks_tags} }) {
                if (grep { $t eq $_ } @row_tags) {
                    next ROW;
                }
            }
        }
        push @res, $row;
    }

    my $resmeta = {};
    if ($args{detail}) {
        $resmeta->{'table.fields'} =
            [qw/name commit_time status_time pull_time tags/];
        $resmeta->{'table.field_formats'} =
            [undef, qw/iso8601_datetime iso8601_datetime iso8601_datetime/];
    } else {
        @res = map { $_->{name} } @res;
    }

    [200, "OK", \@res, $resmeta];
}

$SPEC{touch_repo} = {
    v => 1.1,
    args => {
        %common_args,
        %repo_arg,
        commit_time => {
            schema => [bool => is=>1],
        },
        status_time => {
            schema => [bool => is=>1],
        },
        pull_time => {
            schema => [bool => is=>1],
        },
        to => {
            schema => 'date*',
        },
    },
    args_rels => {
        req_some => [1, 3, [qw/commit_time status_time pull_time/]],
    },
};
sub touch_repo {
    my %args = @_;

    _set_args_default(\%args, 1);
    my $dbh = _connect_db(\%args);

    return [400, "Please specify repo name"] unless defined $args{repo};

    $dbh->begin_work;
    $dbh->do("INSERT OR IGNORE INTO repos (name) VALUES (?)", {},
             $args{repo});
    my $now = time();
    if ($args{commit_time}) {
        $dbh->do("UPDATE repos SET commit_time=? WHERE name=?", {},
                 $now, $args{repo});
    }
    if ($args{status_time}) {
        $dbh->do("UPDATE repos SET status_time=? WHERE name=?", {},
                 $now, $args{repo});
    }
    if ($args{pull_time}) {
        $dbh->do("UPDATE repos SET pull_time=? WHERE name=?", {},
                 $now, $args{repo});
    }
    $dbh->commit;
    [200];
}

$SPEC{add_repo_tag} = {
    v => 1.1,
    args => {
        %common_args,
        %repo_arg,
        %tags_arg,
    },
};
sub add_repo_tag {
    my %args = @_;

    _set_args_default(\%args);
    my $dbh = _connect_db(\%args);

    return [400, "Please specify repo name"] unless defined $args{repo};

    $dbh->begin_work;
    $dbh->do("INSERT OR IGNORE INTO repos (name) VALUES (?)",
             {}, $args{repo});
    my ($tags) = $dbh->selectrow_array("SELECT tags FROM repos WHERE name=?",
                                       {}, $args{repo});
    $tags //= '';
    my %tags = map { $_ => 1 } split /,/, $tags;
    $tags{$_} = 1 for @{ $args{tags} };
    $dbh->do("UPDATE repos SET tags=? WHERE name=?",
             {}, join(",", sort keys %tags), $args{repo});
    $dbh->commit;
    [200];
}

$SPEC{remove_repo_tag} = {
    v => 1.1,
    args => {
        %common_args,
        %repo_arg,
        %tags_arg,
    },
};
sub remove_repo_tag {
    my %args = @_;

    _set_args_default(\%args, 1);
    my $dbh = _connect_db(\%args);

    return [400, "Please specify repo name"] unless defined $args{repo};

    $dbh->begin_work;
    my ($tags) = $dbh->selectrow_array("SELECT tags FROM repos WHERE name=?",
                                       {}, $args{repo});
    defined($tags) or return [404, "No such repo '$args{repo}'"];

    my %tags = map { $_ => 1 } split /,/, $tags;
    delete $tags{$_} for @{ $args{tags} };
    $dbh->do("UPDATE repos SET tags=? WHERE name=?",
             {}, join(",", sort keys %tags), $args{repo});
    $dbh->commit;
    [200];
}

$SPEC{remove_all_repo_tags} = {
    v => 1.1,
    args => {
        %common_args,
        %repo_arg,
    },
};
sub remove_all_repo_tags {
    my %args = @_;

    _set_args_default(\%args, 1);
    my $dbh = _connect_db(\%args);

    return [400, "Please specify repo name"] unless defined $args{repo};

    $dbh->begin_work;
    my ($tags) = $dbh->selectrow_array("SELECT tags FROM repos WHERE name=?",
                                       {}, $args{repo});
    defined($tags) or return [404, "No such repo '$args{repo}'"];
    $dbh->do("UPDATE repos SET tags=NULL WHERE name=?",
             {}, $args{repo});
    $dbh->commit;
    [200];
}

1;
# ABSTRACT: Manipulate repos.db

__END__

=pod

=encoding UTF-8

=head1 NAME

App::reposdb - Manipulate repos.db

=head1 VERSION

This document describes version 0.004 of App::reposdb (from Perl distribution App-reposdb), released on 2016-06-15.

=head1 SYNOPSIS

See L<reposdb>.

=head1 DESCRIPTION


C<repos.db> is a SQLite database that lists repository names along with some
extra data. They have various uses, but my first use-case for this is to store
last commit/status/pull time (updated via a post-commit git hook or C<gitwrap>).
This is useful to speed up like syncing of repositories in C<Git::Bunch> that
wants to find out which of the hundreds/thousand+ git repositories are "the most
recently used" to prioritize these repositories first. Using information from
C<repos.db> is faster than having to C<git status> or even stat() each repository.

=head1 FUNCTIONS


=head2 add_repo_tag(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<repo> => I<str>

=item * B<reposdb_path>* => I<str>

=item * B<tags>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_repos(%args) -> [status, msg, result, meta]

List repositories registered in repos.db.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<has_tags> => I<array[str]>

=item * B<lacks_tags> => I<array[str]>

=item * B<reposdb_path>* => I<str>

=item * B<sorts> => I<array[str]> (default: ["name"])

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 remove_all_repo_tags(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<repo> => I<str>

=item * B<reposdb_path>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 remove_repo_tag(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<repo> => I<str>

=item * B<reposdb_path>* => I<str>

=item * B<tags>* => I<array[str]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 touch_repo(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<commit_time> => I<bool>

=item * B<pull_time> => I<bool>

=item * B<repo> => I<str>

=item * B<reposdb_path>* => I<str>

=item * B<status_time> => I<bool>

=item * B<to> => I<date>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-reposdb>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-reposdb>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-reposdb>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
