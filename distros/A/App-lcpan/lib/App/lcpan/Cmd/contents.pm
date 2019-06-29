package App::lcpan::Cmd::contents;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

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
        push @where, "(file.id=(SELECT file_id FROM dist WHERE name=?))";
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

This document describes version 1.035 of App::lcpan::Cmd::contents (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List contents inside releases.

This subcommand lists files inside release archives.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<dist> => I<posint>

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

=item * B<query> => I<array[str]>

Search query.

=item * B<query_type> => I<str> (default: "any")

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
