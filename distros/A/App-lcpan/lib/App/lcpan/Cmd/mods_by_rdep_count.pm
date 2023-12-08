package App::lcpan::Cmd::mods_by_rdep_count;

use 5.010;
use strict;
use warnings;

use Function::Fallback::CoreOrPP qw(clone_list);

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-07-09'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.073'; # VERSION

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List "most depended modules" (modules ranked by number of reverse dependencies)',
    args => {
        %App::lcpan::common_args,
        clone_list(%App::lcpan::deps_phase_args),
        clone_list(%App::lcpan::deps_rel_args),
        n => {
            summary => 'Return at most this number of results',
            schema => 'posint*',
        },
        %App::lcpan::argspecsopt_module_authors,
        %App::lcpan::argspecsopt_dist_authors,
    },
};
delete $SPEC{'handle_cmd'}{args}{phase}{default};
delete $SPEC{'handle_cmd'}{args}{rel}{default};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @where;
    my @binds;
    if ($args{module_authors} && @{ $args{module_authors} }) {
        push @where, "(author IN (".join(", ", map {$dbh->quote($_)} @{ $args{module_authors} })."))";
    }
    if ($args{module_authors_arent} && @{ $args{module_authors_arent} }) {
        push @where, "(author NOT IN (".join(", ", map {$dbh->quote($_)} @{ $args{module_authors_arent} })."))";
    }
    if ($args{dist_authors} && @{ $args{dist_authors} }) {
        push @where, "(f.cpanid IN (".join(", ", map {$dbh->quote($_)} @{ $args{dist_authors} })."))";
    }
    if ($args{dist_authors_arent} && @{ $args{dist_authors_arent} }) {
        push @where, "(f.cpanid NOT IN (".join(", ", map {$dbh->quote($_)} @{ $args{dist_authors_arent} })."))";
    }
    if ($args{phase} && $args{phase} ne 'ALL') {
        push @where, "(phase=?)";
        push @binds, $args{phase};
    }
    if ($args{rel} && $args{rel} ne 'ALL') {
        push @where, "(rel=?)";
        push @binds, $args{rel};
    }
    @where = (1) if !@where;

    my $sql = "SELECT
  m.name module,
  m.cpanid author,
  COUNT(*) AS rdep_count
FROM module m
JOIN dep dp ON m.id=dp.module_id
LEFT JOIN file f ON dp.file_id=f.id
WHERE ".join(" AND ", @where)."
GROUP BY m.name
ORDER BY rdep_count DESC
".($args{n} ? " LIMIT ".(0+$args{n}) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@binds);
    while (my $row = $sth->fetchrow_hashref) {
        push @res, $row;
    }

    require Data::TableData::Rank;
    Data::TableData::Rank::add_rank_column_to_table(table => \@res, data_columns => ['rdep_count']);

    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/rank module author rdep_count/];
    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List "most depended modules" (modules ranked by number of reverse dependencies)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::mods_by_rdep_count - List "most depended modules" (modules ranked by number of reverse dependencies)

=head1 VERSION

This document describes version 1.073 of App::lcpan::Cmd::mods_by_rdep_count (from Perl distribution App-lcpan), released on 2023-07-09.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List "most depended modules" (modules ranked by number of reverse dependencies).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<dist_authors> => I<array[str]>

Only select dependent distributions published by specified author(s).

=item * B<dist_authors_arent> => I<array[str]>

Do not select dependent distributions published by specified author(s).

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<module_authors> => I<array[str]>

Only list depended modules published by specified author(s).

=item * B<module_authors_arent> => I<array[str]>

Do not list depended modules published by specified author(s).

=item * B<n> => I<posint>

Return at most this number of results.

=item * B<phase> => I<str>

(No description)

=item * B<rel> => I<str>

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
