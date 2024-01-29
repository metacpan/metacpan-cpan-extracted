package App::lcpan::Cmd::related_authors;

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-26'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.074'; # VERSION

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List other authors related to author(s)',
    description => <<'_',

This subcommand lists other authors that might be related to the author(s) you
specify. This is done in one of the ways below which you can choose.

1. (the default) by finding authors whose modules tend to be mentioned together
in POD documentation.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::authors_args,
        #%App::lcpan::detail_args,
        limit => {
            summary => 'Maximum number of authors to return',
            schema => ['int*', min=>0],
            default => 20,
        },
        with_scores => {
            summary => 'Return score-related fields',
            schema => 'bool*',
        },
        #with_content_paths => {
        #    summary => 'Return the list of content paths where the authors\' module and the module of a related author are mentioned together',
        #    schema => 'bool*',
        #},
        sort => {
            schema => ['array*', of=>['str*', in=>[map {($_,"-$_")} qw/score num_module_mentions num_module_mentions_together pct_module_mentions_together author/]], min_len=>1],
            default => ['-score', '-num_module_mentions'],
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $authors = $args{authors};
    my $authors_s = join(",", map {$dbh->quote(uc $_)} @$authors);

    #if ($args{with_content_paths} && @$modules > 1) {
    #    return [412, "Sorry, --with-content-paths currently works with only one specified module"];
    #}

    my $limit = $args{limit};

    # authors' modules
    my @modules;
    my $sth_authors_modules = $dbh->prepare(
        "SELECT name FROM module WHERE file_id IN (SELECT id FROM file WHERE cpanid IN ($authors_s))");
    $sth_authors_modules->execute;
    while (my @row = $sth_authors_modules->fetchrow_array) {
        push @modules, $row[0];
    }
    log_trace("num_modules released by %s: %d", $authors, scalar(@modules));
    return [400, "No modules released by author(s)"] unless @modules;
    my $modules_s = join(",", map {$dbh->quote($_)} @modules);

    # number of mentions of target modules
    my ($num_module_mentions) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM mention WHERE module_id IN (SELECT id FROM module m2 WHERE name IN ($modules_s))");

    return [400, "No module mentions for author(s)"] if $num_module_mentions < 1;

    log_debug("num_module_mentions for %s: %d", $authors, $num_module_mentions);

    my @join = (
        "LEFT JOIN module m2 ON mtn1.module_id=m2.id",
        "LEFT JOIN file f ON m2.file_id=f.id",
    );

    my @where = (
        "mtn1.source_content_id IN (SELECT source_content_id FROM mention mtn2 WHERE  module_id IN (SELECT id FROM module m2 WHERE name IN ($modules_s)))",
        "m2.cpanid NOT IN ($authors_s)",
    );

    my @order = map {/(-?)(.+)/; $2 . ($1 ? " DESC" : "")} @{$args{sort}};

    # sql parts, to make SQL statement readable
    my $sp_num_module_mentions = "SELECT COUNT(*) FROM mention mnt3 WHERE module_id=m2.id";
    my $sp_pct_module_mentions_together = "ROUND(100.0 * COUNT(*)/($sp_num_module_mentions), 2)";

    my $sql = "SELECT
  m2.cpanid author,
  ($sp_num_module_mentions) num_module_mentions,
  COUNT(*) num_module_mentions_together,
  ($sp_pct_module_mentions_together) pct_module_mentions_together,
  (COUNT(*) * COUNT(*) * ($sp_pct_module_mentions_together)) score
FROM mention mtn1
".join("\n", @join)."
WHERE ".join(" AND ", @where)."
GROUP BY m2.cpanid
    ".(@order ? "\nORDER BY ".join(", ", @order) : "")."
LIMIT $limit
";

#    my $sql_with_content_paths;
#    my $sth_with_content_paths;
#    if ($args{with_content_paths}) {
#        $sql_with_content_paths = "SELECT
#  path
#FROM content c
#WHERE
#  EXISTS(SELECT id FROM mention WHERE module_id=(SELECT id FROM module WHERE name=?) AND source_content_id=c.id) AND
#  EXISTS(SELECT id FROM mention WHERE module_id=(SELECT id FROM module WHERE name=?) AND source_content_id=c.id)
#";
#        $sth_with_content_paths = $dbh->prepare($sql_with_content_paths);#
#    }

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        unless ($args{with_scores}) {
            delete $row->{$_} for qw(num_module_mentions num_module_mentions_together pct_module_mentions_together score);
        }
        #if ($args{with_content_paths}) {
        #    my @content_paths;
        #    $sth_with_content_paths->execute($modules->[0], $row->{module});
        #    while (my $row2 = $sth_with_content_paths->fetchrow_arrayref) {
        #        push @content_paths, $row2->[0];
        #    }
        #    $sth_with_content_paths->finish;
        #    $row->{content_paths} = \@content_paths;
        #}
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/author num_module_mentions num_module_mentions_together pct_module_mentions_together score/];

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List other authors related to author(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::related_authors - List other authors related to author(s)

=head1 VERSION

This document describes version 1.074 of App::lcpan::Cmd::related_authors (from Perl distribution App-lcpan), released on 2023-09-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List other authors related to author(s).

This subcommand lists other authors that might be related to the author(s) you
specify. This is done in one of the ways below which you can choose.

=over

=item 1. (the default) by finding authors whose modules tend to be mentioned together
in POD documentation.

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<authors>* => I<array[str]>

(No description)

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

Maximum number of authors to return.

=item * B<sort> => I<array[str]> (default: ["-score","-num_module_mentions"])

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
