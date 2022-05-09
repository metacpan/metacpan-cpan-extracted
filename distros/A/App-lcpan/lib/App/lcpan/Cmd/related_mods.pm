package App::lcpan::Cmd::related_mods;

use 5.010001;
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
    summary => 'List other modules related to module(s)',
    description => <<'_',

This subcommand lists other modules that might be related to the module(s) you
specify. This is done by listing modules that tend be mentioned together in POD
documentation.

The scoring/ranking still needs to be tuned.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mods_args,
        #%App::lcpan::detail_args,
        limit => {
            summary => 'Maximum number of modules to return',
            schema => ['int*', min=>0],
            default => 20,
        },
        with_scores => {
            summary => 'Return score-related fields',
            schema => 'bool*',
        },
        with_content_paths => {
            summary => 'Return the list of content paths where the module and a related module are mentioned together',
            schema => 'bool*',
        },
        sort => {
            schema => ['array*', of=>['str*', in=>[map {($_,"-$_")} qw/score num_mentions num_mentions_together pct_mentions_together module/]], min_len=>1],
            default => ['-score', '-num_mentions'],
        },
        skip_same_dist => {
            summary => 'Skip modules from the same distribution',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
        submodules => {
            summary => 'Whether to include submodules',
            schema => 'bool*',
            description => <<'_',

If set to true, will only show related submodules, e.g. `lcpan related-modules
Foo::Bar` will only show `Foo::Bar::Baz`, `Foo::Bar::Quz`, and so on.

If set to false, will only show related modules that are not submodules, e.g.
`lcpan related-modules Foo::Bar` will show `Baz`, `Foo::Baz`, but not
`Foo::Bar::Baz`.

_
            cmdline_aliases => {
                exclude_submodules => {is_flag=>1, summary=>"Equivalent to --no-submodules", code=>sub {$_[0]{submodules}=0}},
                include_submodules => {is_flag=>1, summary=>"Equivalent to --submodules", code=>sub {$_[0]{submodules}=1}},
            },
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $modules = $args{modules};
    my $modules_s = join(",", map {$dbh->quote($_)} @$modules);

    if ($args{with_content_paths} && @$modules > 1) {
        return [412, "Sorry, --with-content-paths currently works with only one specified module"];
    }

    my $limit = $args{limit};

    # number of mentions of target modules
    my ($num_mentions) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM mention WHERE module_id IN (SELECT id FROM module m2 WHERE name IN ($modules_s))");

    return [400, "No mentions for module(s)"] if $num_mentions < 1;

    log_debug("num_mentions for %s: %d", $modules, $num_mentions);

    my @join = (
        "LEFT JOIN module m2 ON mtn1.module_id=m2.id",
        "LEFT JOIN file f ON m2.file_id=f.id",
    );

    my @where = (
        "mtn1.source_content_id IN (SELECT source_content_id FROM mention mtn2 WHERE  module_id IN (SELECT id FROM module m2 WHERE name IN ($modules_s)))",
        "m2.name NOT IN ($modules_s)",
    );

    my @dist_names;
    if ($args{skip_same_dist}) {
        my $sth = $dbh->prepare(
            "SELECT DISTINCT dist_name FROM file WHERE dist_name IS NOT NULL AND id IN (SELECT file_id FROM module WHERE name IN ($modules_s))");
        $sth->execute;
        while (my ($dist_name) = $sth->fetchrow_array) {
            push @dist_names, $dist_name;
        }
        push @where, "f.dist_name NOT IN (".join(", ", map { $dbh->quote($_) } @dist_names).")";
    }
    if ($args{submodules}) {
        for my $module (@$modules) {
            push @where, "m2.name LIKE " . $dbh->quote("$module\::%");
        }
    } elsif (defined $args{submodules} && !$args{submodules}) {
        for my $module (@$modules) {
            push @where, "m2.name NOT LIKE " . $dbh->quote("$module\::%");
        }
    }

    my @order = map {/(-?)(.+)/; $2 . ($1 ? " DESC" : "")} @{$args{sort}};

    # sql parts, to make SQL statement readable
    my $sp_num_mentions = "SELECT COUNT(*) FROM mention mnt3 WHERE module_id=m2.id";
    my $sp_pct_mentions_together = "ROUND(100.0 * COUNT(*)/($sp_num_mentions), 2)";

    my $sql = "SELECT
  m2.name module,
  m2.abstract abstract,
  ($sp_num_mentions) num_mentions,
  COUNT(*) num_mentions_together,
  ($sp_pct_mentions_together) pct_mentions_together,
  (COUNT(*) * COUNT(*) * ($sp_pct_mentions_together)) score,
  f.dist_name dist,
  m2.cpanid author
FROM mention mtn1
".join("\n", @join)."
WHERE ".join(" AND ", @where)."
GROUP BY m2.name
    ".(@order ? "\nORDER BY ".join(", ", @order) : "")."
LIMIT $limit
";

    my $sql_with_content_paths;
    my $sth_with_content_paths;
    if ($args{with_content_paths}) {
        $sql_with_content_paths = "SELECT
  path
FROM content c
WHERE
  EXISTS(SELECT id FROM mention WHERE module_id=(SELECT id FROM module WHERE name=?) AND source_content_id=c.id) AND
  EXISTS(SELECT id FROM mention WHERE module_id=(SELECT id FROM module WHERE name=?) AND source_content_id=c.id)
";
        $sth_with_content_paths = $dbh->prepare($sql_with_content_paths);
    }

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        unless ($args{with_scores}) {
            delete $row->{$_} for qw(num_mentions num_mentions_together pct_mentions_together score);
        }
        if ($args{with_content_paths}) {
            my @content_paths;
            $sth_with_content_paths->execute($modules->[0], $row->{module});
            while (my $row2 = $sth_with_content_paths->fetchrow_arrayref) {
                push @content_paths, $row2->[0];
            }
            $sth_with_content_paths->finish;
            $row->{content_paths} = \@content_paths;
        }
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/module abstract num_mentions num_mentions_together pct_mentions_together score dist author/];

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List other modules related to module(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::related_mods - List other modules related to module(s)

=head1 VERSION

This document describes version 1.070 of App::lcpan::Cmd::related_mods (from Perl distribution App-lcpan), released on 2022-03-27.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List other modules related to module(s).

This subcommand lists other modules that might be related to the module(s) you
specify. This is done by listing modules that tend be mentioned together in POD
documentation.

The scoring/ranking still needs to be tuned.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<limit> => I<int> (default: 20)

Maximum number of modules to return.

=item * B<modules>* => I<array[perl::modname]>

=item * B<skip_same_dist> => I<bool>

Skip modules from the same distribution.

=item * B<sort> => I<array[str]> (default: ["-score","-num_mentions"])

=item * B<submodules> => I<bool>

Whether to include submodules.

If set to true, will only show related submodules, e.g. C<lcpan related-modules
Foo::Bar> will only show C<Foo::Bar::Baz>, C<Foo::Bar::Quz>, and so on.

If set to false, will only show related modules that are not submodules, e.g.
C<lcpan related-modules Foo::Bar> will show C<Baz>, C<Foo::Baz>, but not
C<Foo::Bar::Baz>.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=item * B<with_content_paths> => I<bool>

Return the list of content paths where the module and a related module are mentioned together.

=item * B<with_scores> => I<bool>

Return score-related fields.


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
