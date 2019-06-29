package App::lcpan::Cmd::subs;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

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

This document describes version 1.035 of App::lcpan::Cmd::subs (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List subroutines.

This subcommand lists subroutines/methods/static methods.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<authors> => I<array[str]>

Filter by author(s) of module.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

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

=item * B<sort> => I<array[str]> (default: ["sub"])

Sort the result.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
