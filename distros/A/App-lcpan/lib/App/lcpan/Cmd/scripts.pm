package App::lcpan::Cmd::scripts;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '1.035'; # VERSION

use 5.010;
use strict;
use warnings;

require App::lcpan;

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List scripts',
    description => <<'_',

This subcommand lists scripts. Scripts are identified heuristically from
contents of release archives matching this regex:

    #         container dir,  script dir,       script name
    \A (\./)? ([^/]+)/?       (s?bin|scripts?)/ ([^/]+) \z

A few exception are excluded, e.g. if script name begins with a dot (e.g.
`bin/.exists` which is usually a marker only).

Scripts are currently indexed by its release file and its name, so if a single
release contains both `bin/foo` and `script/foo`, only one of those will be
indexed. Normally a proper release shouldn't be like that though.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::fauthor_args,
        %App::lcpan::fdist_args,
        %App::lcpan::query_multi_args,
        query_type => {
            schema => ['str*', in=>[qw/any name exact-name abstract/]],
            default => 'any',
            cmdline_aliases => {
                x => {
                    summary => 'Shortcut for --query-type exact-name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'exact-name' },
                },
                n => {
                    summary => 'Shortcut for --query-type name',
                    is_flag => 1,
                    code => sub { $_[0]{query_type} = 'name' },
                },
            },
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
    my $qt = $args{query_type} // 'any';

    my @bind;
    my @where;
    {
        my @q_where;
        for my $q0 (@{ $args{query} // [] }) {
            if ($qt eq 'any') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(script.name LIKE ? OR script.abstract LIKE ?)";
                push @bind, $q, $q;
            } elsif ($qt eq 'abstract') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(script.abstract LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'name') {
                my $q = $q0 =~ /%/ ? $q0 : '%'.$q0.'%';
                push @q_where, "(script.name LIKE ?)";
                push @bind, $q;
            } elsif ($qt eq 'exact-name') {
                push @q_where, "(script.name=?)";
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
        push @where, "(script.cpanid=?)";
        push @bind, $author;
    }
    if ($dist) {
        push @where, "(script.file_id=(SELECT file_id FROM dist WHERE name=?))";
        push @bind, $dist;
    }

    my $sql = "SELECT
  file.name release,
  script.cpanid cpanid,
  script.name name,
  script.abstract abstract
FROM script
LEFT JOIN file ON file.id=script.file_id".
    (@where ? " WHERE ".join(" AND ", @where) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $detail ? $row : $row->{name};
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/name abstract release cpanid/]
        if $detail;
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::scripts - List scripts

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::scripts (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List scripts.

This subcommand lists scripts. Scripts are identified heuristically from
contents of release archives matching this regex:

 #         container dir,  script dir,       script name
 \A (\./)? ([^/]+)/?       (s?bin|scripts?)/ ([^/]+) \z

A few exception are excluded, e.g. if script name begins with a dot (e.g.
C<bin/.exists> which is usually a marker only).

Scripts are currently indexed by its release file and its name, so if a single
release contains both C<bin/foo> and C<script/foo>, only one of those will be
indexed. Normally a proper release shouldn't be like that though.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<str>

Filter by author.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<detail> => I<bool>

=item * B<dist> => I<perl::distname>

Filter by distribution.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<or> => I<bool>

When there are more than one query, perform OR instead of AND logic.

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
