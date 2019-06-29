package App::lcpan::Cmd::deps_by_dependent_count;

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
    summary => 'List dependencies, sorted by number of dependents',
    description => <<'_',

This subcommand is like `deps`, except that this subcommand does not support
recursing and it sorts the result by number of dependent dists. For example,
Suppose that dist `Foo` depends on `Mod1` and `Mod2`, `Bar` depends on `Mod2`
and `Mod3`, and `Baz` depends on `Mod2` and `Mod3`, then `lcpan
deps-by-dependent-count Foo Bar Baz` will return `Mod2` (3 dependents), `Mod3`
(2 dependents), `Mod1` (1 dependent).

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mods_args,

        %App::lcpan::deps_phase_args,
        %App::lcpan::deps_rel_args,
        %App::lcpan::finclude_core_args,
        %App::lcpan::finclude_noncore_args,
        %App::lcpan::perl_version_args,
        # XXX with_xs_or_pp
        authors => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'author',
            schema => ['array*', of=>'str*', min_len=>1],
            tags => ['category:filtering'],
            element_completion => \&App::lcpan::_complete_cpanid,
        },
        authors_arent => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'author_isnt',
            schema => ['array*', of=>'str*', min_len=>1],
            tags => ['category:filtering'],
            element_completion => \&App::lcpan::_complete_cpanid,
        },
    },
};
sub handle_cmd {
    require Module::CoreList::More;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $phase   = $args{phase} // 'runtime';
    my $rel     = $args{rel} // 'requires';
    my $include_core    = $args{include_core} // 1;
    my $include_noncore = $args{include_noncore} // 1;
    my $plver   = $args{perl_version} // "$^V";

    # first, get the dist ID's of the requested modules
    my @dist_ids;
    {
        my $mods_s = join(", ", map {$dbh->quote($_)} @{$args{modules}});
        my $sth = $dbh->prepare("SELECT id FROM dist WHERE is_latest AND file_id IN (SELECT file_id FROM module WHERE name IN ($mods_s))");
        $sth->execute;
        while (my ($id) = $sth->fetchrow_array) { push @dist_ids, $id }
        return [404, "No such module(s)"] unless @dist_ids;
    }

    my @cols = (
        # name, dbcolname/expr
        ["module", "m.name"],
        ["author", "m.cpanid"],
        ["version", "m.version"],
        ["is_core", undef],
        ["dependent_count", "COUNT(*)"],
    );

    my @wheres = (
        "m.id IS NOT NULL",
        "dep.dist_id IN (".join(",", @dist_ids).")",
    );
    my @binds;

    if ($phase ne 'ALL') {
        push @wheres, "dep.phase=?";
        push @binds, $phase;
    }
    if ($rel ne 'ALL') {
        push @wheres, "dep.rel=?";
        push @binds, $rel;
    }
    if ($args{authors}) {
        push @wheres, "(".join(" OR ", map {"author=?"} @{$args{authors}}).")";
        push @binds, map {uc $_} @{ $args{authors} };
    }
    if ($args{authors_arent}) {
        for (@{ $args{authors_arent} }) {
            push @wheres, "author<>?";
            push @binds, uc $_;
        }
    }

    my $sth = $dbh->prepare("SELECT
".join(",\n", map {"  $_->[1] AS $_->[0]"} grep {defined $_->[1]} @cols)."
FROM dep
LEFT JOIN module m ON dep.module_id=m.id
WHERE ".join(" AND ", @wheres)."
GROUP BY dep.module_id
ORDER BY COUNT(*) DESC, m.name
");
    $sth->execute(@binds);

    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
        $row->{is_core} = $row->{module} eq 'perl' ||
            Module::CoreList::More->is_still_core(
                $row->{module}, undef,
                version->parse($plver)->numify);
        next if !$include_core    &&  $row->{is_core};
        next if !$include_noncore && !$row->{is_core};
        push @rows, $row;
    }

    [200, "OK", \@rows, {'table.fields'=>[map {$_->[0]} @cols]}];
}

1;
# ABSTRACT: List dependencies, sorted by number of dependents

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::deps_by_dependent_count - List dependencies, sorted by number of dependents

=head1 VERSION

This document describes version 1.035 of App::lcpan::Cmd::deps_by_dependent_count (from Perl distribution App-lcpan), released on 2019-06-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List dependencies, sorted by number of dependents.

This subcommand is like C<deps>, except that this subcommand does not support
recursing and it sorts the result by number of dependent dists. For example,
Suppose that dist C<Foo> depends on C<Mod1> and C<Mod2>, C<Bar> depends on C<Mod2>
and C<Mod3>, and C<Baz> depends on C<Mod2> and C<Mod3>, then C<lcpan
deps-by-dependent-count Foo Bar Baz> will return C<Mod2> (3 dependents), C<Mod3>
(2 dependents), C<Mod1> (1 dependent).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<authors> => I<array[str]>

=item * B<authors_arent> => I<array[str]>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<modules>* => I<array[perl::modname]>

=item * B<perl_version> => I<str> (default: "v5.26.1")

Set base Perl version for determining core modules.

=item * B<phase> => I<str> (default: "runtime")

=item * B<rel> => I<str> (default: "requires")

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
