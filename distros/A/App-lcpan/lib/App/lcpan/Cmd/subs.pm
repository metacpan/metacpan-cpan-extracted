package App::lcpan::Cmd::subs;

use 5.010;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-03-27'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.070'; # VERSION

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List subroutines',
    description => <<'_',

This subcommand lists subroutines/methods/static methods.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::query_multi_args,
        query_type => {
            schema => ['str*', in=>[qw/any name exact-name/]],
            default => 'any',
        },
        # XXX include_method
        # XXX include_static_method
        # XXX include_function
        packages => {
            'x.name.is_plural' => 1,
            summary => 'Filter by package name(s)',
            schema => ['array*', of=>'str*', min_len=>1],
            element_completion => \&App::lcpan::_complete_mod,
            tags => ['category:filtering'],
        },
        authors => {
            'x.name.is_plural' => 1,
            summary => 'Filter by author(s) of module',
            schema => ['array*', of=>'str*', min_len=>1],
            element_completion => \&App::lcpan::_complete_cpanid,
            tags => ['category:filtering'],
        },
        %App::lcpan::sort_args_for_subs,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @bind;
    my @where;
    #my @having;

    my $packages = $args{packages} // [];
    my $authors  = $args{authors} // [];
    my $qt = $args{query_type} // 'any';
    my $sort = $args{sort} // ['sub'];

    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(sub.name LIKE ? OR content.package LIKE ?)";
                push @bind, $q, $q;
            } elsif ($qt eq 'name') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(sub.name LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-name') {
                push @q_where, "(sub.name=?)";
                push @bind, $q0;
            }
        }
        if (@q_where > 1) {
            push @where, "(".join(($args{or} ? " OR " : " AND "), @q_where).")";
        } elsif (@q_where == 1) {
            push @where, @q_where;
        }
    }
    if (@$packages) {
        my $packages_s = join(",", map {$dbh->quote($_)} @$packages);
        push @where, "(content.package IN ($packages_s))";
    }
    if (@$authors) {
        my $authors_s = join(",", map {$dbh->quote($_)} @$authors);
        push @where, "(file.cpanid IN ($authors_s))";
    }

    my @order;
    for (@$sort) { /\A(-?)(\w+)/ and push @order, $2 . ($1 ? " DESC" : "") }

    my $sql = "SELECT
  sub.name sub,
  content.package package,
  sub.linum linum,
  content.path content_path,
  file.name release,
  file.cpanid author
FROM sub
LEFT JOIN file ON sub.file_id=file.id
LEFT JOIN content ON sub.content_id=content.id
".
    (@where ? " WHERE ".join(" AND ", @where) : "").
    #(@having ? " HAVING ".join(" AND ", @having) : "");
    (@order ? " ORDER BY ".join(", ", @order) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $args{detail} ? $row : $row->{sub};
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/sub package linum content_path release author/]
        if $args{detail};

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List subroutines

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::subs - List subroutines

=head1 VERSION

This document describes version 1.070 of App::lcpan::Cmd::subs (from Perl distribution App-lcpan), released on 2022-03-27.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List subroutines.

This subcommand lists subroutines/methods/static methods.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<authors> => I<array[str]>

Filter by author(s) of module.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

=item * B<packages> => I<array[str]>

Filter by package name(s).

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

=item * B<random> => I<true>

Random sort.

=item * B<sort> => I<array[str]> (default: ["sub"])

Sort the result.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
