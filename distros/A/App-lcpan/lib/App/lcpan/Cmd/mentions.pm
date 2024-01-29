package App::lcpan::Cmd::mentions;

use 5.010;
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
    summary => 'List mentions',
    description => <<'_',

This subcommand lists mentions (references to modules/scripts in POD files
inside releases).

Only mentions to modules/scripts in another release are indexed (i.e. mentions
to modules/scripts in the same dist/release are not indexed). Only mentions to
known scripts are indexed, but mentions to unknown modules are also indexed.

_
    args => {
        %App::lcpan::common_args,
        type => {
            summary => 'Filter by type of things being mentioned',
            schema => ['str*', in=>['any', 'script', 'module', 'unknown-module', 'known-module']],
            default => 'any',
            tags => ['category:filtering'],
        },

        mentioned_modules => {
            'x.name.is_plural' => 1,
            summary => 'Filter by module name(s) being mentioned',
            schema => ['array*', of=>'str*', min_len=>1],
            element_completion => \&App::lcpan::_complete_mod,
            tags => ['category:filtering'],
        },
        mentioned_scripts => {
            'x.name.is_plural' => 1,
            summary => 'Filter by script name(s) being mentioned',
            schema => ['array*', of=>'str*', min_len=>1],
            element_completion => \&App::lcpan::_complete_script,
            tags => ['category:filtering'],
        },
        mentioned_authors => {
            'x.name.is_plural' => 1,
            summary => 'Filter by author(s) of module/script being mentioned',
            schema => ['array*', of=>'str*', min_len=>1],
            tags => ['category:filtering'],
            completion => \&App::lcpan::_complete_cpanid,
        },

        mentioner_modules => {
            'x.name.is_plural' => 1,
            summary => 'Filter by module(s) that do the mentioning',
            schema => ['array*', of=>'str*', min_len=>1],
            element_completion => \&App::lcpan::_complete_mod,
            tags => ['category:filtering'],
        },
        mentioner_scripts => {
            'x.name.is_plural' => 1,
            summary => 'Filter by script(s) that do the mentioning',
            schema => ['array*', of=>'str*', min_len=>1],
            element_completion => \&App::lcpan::_complete_script,
            tags => ['category:filtering'],
        },
        mentioner_authors => {
            'x.name.is_plural' => 1,
            summary => 'Filter by author(s) of POD that does the mentioning',
            schema => ['array*', of=>'str*', min_len=>1],
            tags => ['category:filtering'],
            completion => \&App::lcpan::_complete_cpanid,
        },
        mentioner_authors_arent => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'mentioner_author_isnt',
            schema => ['array*', of=>'str*'],
            tags => ['category:filtering'],
            element_completion => \&App::lcpan::_complete_cpanid,
        },
        #%App::lcpan::fauthor_args,
        %App::lcpan::fctime_args,
        %App::lcpan::fmtime_args,
        %App::lcpan::fctime_or_mtime_args,
    },
};
sub handle_cmd {
    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my $type = $args{type} // 'any';

    my $mentioned_modules = $args{mentioned_modules} // [];
    my $mentioned_scripts = $args{mentioned_scripts} // [];
    my $mentioned_authors = $args{mentioned_authors} // [];

    my $mentioner_modules = $args{mentioner_modules} // [];
    my $mentioner_scripts = $args{mentioner_scripts} // [];
    my $mentioner_authors = $args{mentioner_authors} // [];
    my $mentioner_authors_arent = $args{mentioner_authors_arent} // [];

    my @extra_join;
    my @bind;
    my @where;
    #my @having;

    App::lcpan::_set_since(\%args, $dbh);
    App::lcpan::_add_since_where_clause(\%args, \@where, "mention");

    if ($type eq 'script') {
        push @where, "mention.script_name IS NOT NULL";
    } elsif ($type eq 'module') {
        push @where, "(mention.module_id IS NOT NULL OR mention.module_name IS NOT NULL)";
    } elsif ($type eq 'known-module') {
        push @where, "mention.module_id IS NOT NULL";
    } elsif ($type eq 'unknown-module') {
        push @where, "mention.module_name IS NOT NULL";
    }

    if (@$mentioned_modules) {
        my $mods_s = join(",", map { $dbh->quote($_) } @$mentioned_modules);
        if ($type eq 'known-module') {
            push @where, "m1.name IN ($mods_s)";
        } elsif ($type eq 'unknown-module') {
            push @where, "mention.module_name IN ($mods_s)";
        } else {
            push @where, "(m1.name IN ($mods_s) OR mention.module_name IN ($mods_s))";
        }
    }

    if (@$mentioned_scripts) {
        my $scripts_s = join(",", map { $dbh->quote($_) } @$mentioned_scripts);
        push @where, "mention.script_name IN ($scripts_s)";
    }

    if (@$mentioned_authors) {
        my $authors_s = join(",", map { $dbh->quote(uc $_) } @$mentioned_authors);
        push @where, "(module_author IN ($authors_s) OR script_author IN ($authors_s))";
    }

    if (@$mentioner_modules) {
        my $mods_s = join(",", map { $dbh->quote($_) } @$mentioner_modules);
        push @where, "content.package IN ($mods_s)";
    }

    if (@$mentioner_scripts) {
        my $scripts_s = join(",", map { $dbh->quote($_) } @$mentioner_scripts);
        push @extra_join, "LEFT JOIN script s2 ON content.id=s2.content_id -- mentioner script";
        push @where, "s2.name IN ($scripts_s)";
    }

    if (@$mentioner_authors) {
        my $authors_s = join(",", map { $dbh->quote(uc $_) } @$mentioner_authors);
        push @where, "mentioner_author IN ($authors_s)";
    }

    if (@$mentioner_authors_arent) {
        my $authors_s = join(",", map { $dbh->quote(uc $_) } @$mentioner_authors_arent);
        push @where, "mentioner_author NOT IN ($authors_s)";
    }

    my $sql = "SELECT
  file.name release,
  content.path content_path,
  CASE WHEN m1.name IS NOT NULL THEN m1.name ELSE mention.module_name END AS module,
  m1.cpanid module_author,
  mention.script_name script,
  s1.cpanid script_author,
  file.cpanid mentioner_author
FROM mention
LEFT JOIN file ON file.id=mention.source_file_id
LEFT JOIN content ON content.id=mention.source_content_id
LEFT JOIN module m1 ON mention.module_id=m1.id -- mentioned script
LEFT JOIN script s1 ON mention.script_name=s1.name -- mentioned script
".
    (@extra_join ? join("", map {"$_\n"} @extra_join) : "").
    (@where ? "\nWHERE ".join(" AND ", @where) : "");#.
    #(@having ? "\nHAVING ".join(" AND ", @having) : "");

    my @res;
    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);
    while (my $row = $sth->fetchrow_hashref) {
        if (@$mentioned_modules || $type =~ /module/) {
            delete $row->{script};
            delete $row->{script_author};
        }
        if (@$mentioned_scripts || $type eq 'script') {
            delete $row->{module};
            delete $row->{module_author};
        }
        push @res, $row;
    }
    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/module module_author script script_author release mentioner_author content_path/];

    if (@$mentioned_modules || $type =~ /module/) {
        $resmeta->{'table.fields'} =
            [grep {$_ ne 'script' && $_ ne 'script_author'} @{$resmeta->{'table.fields'}}];
    }
    if (@$mentioned_scripts || $type eq 'script') {
        $resmeta->{'table.fields'} =
            [grep {$_ ne 'module' && $_ ne 'module_author'} @{$resmeta->{'table.fields'}}];
    }

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List mentions

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::mentions - List mentions

=head1 VERSION

This document describes version 1.074 of App::lcpan::Cmd::mentions (from Perl distribution App-lcpan), released on 2023-09-26.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List mentions.

This subcommand lists mentions (references to modules/scripts in POD files
inside releases).

Only mentions to modules/scripts in another release are indexed (i.e. mentions
to modules/scripts in the same dist/release are not indexed). Only mentions to
known scripts are indexed, but mentions to unknown modules are also indexed.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<added_or_updated_since> => I<date>

Include only records that are addedE<sol>updated since a certain date.

=item * B<added_or_updated_since_last_index_update> => I<true>

Include only records that are addedE<sol>updated since the last index update.

=item * B<added_or_updated_since_last_n_index_updates> => I<posint>

Include only records that are addedE<sol>updated since the last N index updates.

=item * B<added_since> => I<date>

Include only records that are added since a certain date.

=item * B<added_since_last_index_update> => I<true>

Include only records that are added since the last index update.

=item * B<added_since_last_n_index_updates> => I<posint>

Include only records that are added since the last N index updates.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<mentioned_authors> => I<array[str]>

Filter by author(s) of moduleE<sol>script being mentioned.

=item * B<mentioned_modules> => I<array[str]>

Filter by module name(s) being mentioned.

=item * B<mentioned_scripts> => I<array[str]>

Filter by script name(s) being mentioned.

=item * B<mentioner_authors> => I<array[str]>

Filter by author(s) of POD that does the mentioning.

=item * B<mentioner_authors_arent> => I<array[str]>

(No description)

=item * B<mentioner_modules> => I<array[str]>

Filter by module(s) that do the mentioning.

=item * B<mentioner_scripts> => I<array[str]>

Filter by script(s) that do the mentioning.

=item * B<type> => I<str> (default: "any")

Filter by type of things being mentioned.

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

=item * B<updated_since> => I<date>

Include only records that are updated since certain date.

=item * B<updated_since_last_index_update> => I<true>

Include only records that are updated since the last index update.

=item * B<updated_since_last_n_index_updates> => I<posint>

Include only records that are updated since the last N index updates.

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
