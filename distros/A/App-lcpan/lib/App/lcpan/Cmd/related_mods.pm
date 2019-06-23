package App::lcpan::Cmd::related_mods;

our $DATE = '2019-06-19'; # DATE
our $VERSION = '1.034'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

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
        sort => {
            schema => ['array*', of=>['str*', in=>[map {($_,"-$_")} qw/score num_mentions num_mentions_together pct_mentions_together module/]], min_len=>1],
            default => ['-score', '-num_mentions'],
        },
        skip_same_dist => {
            summary => 'Skip modules from the same distribution',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'rw');
    my $dbh = $state->{dbh};

    my $modules = $args{modules};
    my $modules_s = join(",", map {$dbh->quote($_)} @$modules);

    my $limit = $args{limit};

    # number of mentions of target modules
    my ($num_mentions) = $dbh->selectrow_array(
        "SELECT COUNT(*) FROM mention WHERE module_id IN (SELECT id FROM module m2 WHERE name IN ($modules_s))");

    return [400, "No mentions for module(s)"] if $num_mentions < 1;

    log_debug("num_mentions for %s: %d", $modules, $num_mentions);

    my @join = (
        "LEFT JOIN module m2 ON mtn1.module_id=m2.id",
        "LEFT JOIN dist d ON m2.file_id=d.file_id",
    );

    my @where = (
        "mtn1.source_content_id IN (SELECT source_content_id FROM mention mtn2 WHERE  module_id IN (SELECT id FROM module m2 WHERE name IN ($modules_s)))",
        "m2.name NOT IN ($modules_s)",
    );

    my @dist_ids;
    if ($args{skip_same_dist}) {
        my $sth = $dbh->prepare(
            "SELECT id FROM dist WHERE file_id IN (SELECT file_id FROM module WHERE name IN ($modules_s))");
        $sth->execute;
        while (my ($id) = $sth->fetchrow_array) {
            push @dist_ids, $id;
        }
        push @where, "d.id NOT IN (".join(", ", @dist_ids).")";
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
  d.name dist,
  m2.cpanid author
FROM mention mtn1
".join("\n", @join)."
WHERE ".join(" AND ", @where)."
GROUP BY m2.name
    ".(@order ? "\nORDER BY ".join(", ", @order) : "")."
LIMIT $limit
";

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $row = $sth->fetchrow_hashref) {
        unless ($args{with_scores}) {
            delete $row->{$_} for qw(num_mentions num_mentions_together pct_mentions_together score);
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

This document describes version 1.034 of App::lcpan::Cmd::related_mods (from Perl distribution App-lcpan), released on 2019-06-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

List other modules related to module(s).

This subcommand lists other modules that might be related to the module(s) you
specify. This is done by listing modules that tend be mentioned together in POD
documentation.

The scoring/ranking still needs to be tuned.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

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

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=item * B<with_scores> => I<bool>

Return score-related fields.

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
