package App::lcpan::Cmd::contents;

use 5.010;
use strict;
use warnings;

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.073'; # VERSION

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List contents inside releases',
    description => <<'_',

This subcommand lists files inside release archives.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::fauthor_args,
        %App::lcpan::fdist_args,
        %App::lcpan::file_id_args,
        "package" => {
            schema => 'str*',
            tags => ['category:filtering'],
        },
        %App::lcpan::query_multi_args,
        query_type => {
            schema => ['str*', in=>[qw/any path exact-path package
                                       exact-package/]],
            default => 'any',
        },
        #%App::lcpan::dist_args,
        # all=>1
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $detail = $args{detail};
    my $author = uc($args{author} // '');
    my $dist = $args{dist};
    my $file_id = $args{file_id};
    my $package = $args{package};
    my $qt = $args{query_type} // 'any';

    my @bind;
    my @where;
    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(content.path LIKE ? OR package LIKE ?)";
                push @bind, $q, $q;
            } elsif ($qt eq 'path') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(content.path LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-path') {
                push @q_where, "(content.path=?)";
                push @bind, $q0;
            } elsif ($qt eq 'package') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(content.package LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-package') {
                push @q_where, "(content.package=?)";
                push @bind, $q0;
            }
        }
        if (@q_where > 1) {
            push @where, "(".join(($args{or} ? " OR " : " AND "), @q_where).")";
        } elsif (@q_where == 1) {
            push @where, @q_where;
        }
    }
    if ($author) {
        push @where, "(file.cpanid=?)";
        push @bind, $author;
    }
    if ($dist) {
        push @where, "file.dist_name=?";
        push @bind, $dist;
    }
    if ($package) {
        push @where, "content.package=?";
        push @bind, $package;
    }
    if ($file_id) {
        push @where, "file.id=?";
        push @bind, $file_id;
    }

    my $sql = "SELECT
  file.cpanid cpanid,
  file.name release,
  content.path path,
  content.mtime mtime,
  content.size size,
  content.package AS package
FROM content
LEFT JOIN file ON content.file_id=file.id
".
    (@where ? " WHERE ".join(" AND ", @where) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $detail ? $row : $row->{path};
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/path release cpanid mtime size package/]
        if $detail;
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List contents inside releases

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::contents - List contents inside releases

=head1 VERSION

This document describes version 1.073 of App::lcpan::Cmd::contents (from Perl distribution App-lcpan), released on 2023-07-09.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List contents inside releases.

This subcommand lists files inside release archives.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

(No description)

=item * B<dist> => I<perl::distname>

Filter by distribution.

=item * B<file_id> => I<posint>

Filter by file ID.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<package> => I<str>

(No description)

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

(No description)

=item * B<update_db_schema> => I<bool> (default: 1)

Whether to update database schema to the latest.

By default, when the application starts and reads the index database, it updates
the database schema to the latest if the database happens to be last updated by
an older version of the application and has the old database schema (since
database schema is updated from time to time, for example at 1.070 the database
schema is at version 15).

When you disable this option, the application will not update the database
schema. This option is for testing only, because it will probably cause the
application to run abnormally and then die with a SQL error when reading/writing
to the database.

Note that in certain modes e.g. doing tab completion, the application also will
not update the database schema.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
