package App::lcpan::Cmd::author_deps;

use 5.010;
use strict;
use warnings;

require App::lcpan;
use Hash::Subset qw(hash_subset);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-19'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.071'; # VERSION

our %SPEC;

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => "List dependencies for all of the dists of an author",
    description => <<'_',

For a CPAN author, this subcommand is a shortcut for doing:

    % lcpan deps Your-Dist

for all of your distributions. It shows just how many modules are you currently
using in one of your distros on CPAN.

To show how many modules from other authors you are depending:

    % lcpan author-deps YOURCPANID --module-author-isnt YOURCPANID

To show how many of your own modules you are depending in your own distros:

    % lcpan author-deps YOURCPANID --module-author-is YOURCPANID

To find whether there are any prerequisites that you mention in your
distributions that are currently broken (not indexed on CPAN):

    % lcpan author-deps YOURCPANID --broken --dont-uniquify

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::author_args,
        %App::lcpan::deps_args,
        %App::lcpan::argspecsopt_module_authors,
    },
};
sub handle_cmd {
    my %args = @_;

    my $author = $args{author};

    my $res = App::lcpan::dists(
        hash_subset(\%args, \%App::lcpan::common_args, \%App::lcpan::author_args),
    );
    return $res if $res->[0] != 200;
    my $dists = $res->[2];

    my %deps_args = %args;
    $deps_args{dists} = $dists;
    delete $deps_args{author};
    delete $deps_args{authors};
    delete $deps_args{authors_arent};
    $deps_args{authors} = delete $args{module_authors};
    $deps_args{authors_arent} = delete $args{module_authors_arent};
    $deps_args{phase} = delete $args{phase};
    $deps_args{rel} = delete $args{rel};
    $deps_args{added_since} = delete $args{added_since};
    $deps_args{updated_since} = delete $args{updated_since};
    $deps_args{added_or_updated_since} = delete $args{added_or_updated_since};
    $res = App::lcpan::deps(%deps_args);
    return $res if $res->[0] != 200;

    $res;
}

1;
# ABSTRACT: List dependencies for all of the dists of an author

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::author_deps - List dependencies for all of the dists of an author

=head1 VERSION

This document describes version 1.071 of App::lcpan::Cmd::author_deps (from Perl distribution App-lcpan), released on 2022-09-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List dependencies for all of the dists of an author.

For a CPAN author, this subcommand is a shortcut for doing:

 % lcpan deps Your-Dist

for all of your distributions. It shows just how many modules are you currently
using in one of your distros on CPAN.

To show how many modules from other authors you are depending:

 % lcpan author-deps YOURCPANID --module-author-isnt YOURCPANID

To show how many of your own modules you are depending in your own distros:

 % lcpan author-deps YOURCPANID --module-author-is YOURCPANID

To find whether there are any prerequisites that you mention in your
distributions that are currently broken (not indexed on CPAN):

 % lcpan author-deps YOURCPANID --broken --dont-uniquify

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

=item * B<author>* => I<str>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<dont_uniquify> => I<bool>

Allow showing multiple modules for different dists.

=item * B<flatten> => I<bool>

Instead of showing tree-like information, flatten it.

When recursing, the default is to show the final result in a tree-like table,
i.e. indented according to levels, e.g.:

 % lcpan deps -R MyModule
 | module            | author  | version |
 |-------------------|---------|---------|
 | Foo               | AUTHOR1 | 0.01    |
 |   Bar             | AUTHOR2 | 0.23    |
 |   Baz             | AUTHOR3 | 1.15    |
 | Qux               | AUTHOR2 | 0       |

To be brief, if C<Qux> happens to also depends on C<Bar>, it will not be shown in
the result. Thus we don't know the actual C<Bar> version that is needed by the
dependency tree of C<MyModule>. For example, if C<Qux> happens to depends on C<Bar>
version 0.45 then C<MyModule> indirectly requires C<Bar> 0.45.

To list all the direct and indirect dependencies on a single flat list, with
versions already resolved to the largest version required, use the C<flatten>
option:

 % lcpan deps -R --flatten MyModule
 | module            | author  | version |
 |-------------------|---------|---------|
 | Foo               | AUTHOR1 | 0.01    |
 | Bar               | AUTHOR2 | 0.45    |
 | Baz               | AUTHOR3 | 1.15    |
 | Qux               | AUTHOR2 | 0       |

Note that C<Bar>'s required version is already 0.45 in the above example.

=item * B<include_core> => I<bool> (default: 1)

Include core modules.

=item * B<include_indexed> => I<bool> (default: 1)

Include modules that are indexed (listed in 02packages.details.txt.gz).

=item * B<include_noncore> => I<bool> (default: 1)

Include non-core modules.

=item * B<include_unindexed> => I<bool> (default: 1)

Include modules that are not indexed (not listed in 02packages.details.txt.gz).

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<level> => I<int> (default: 1)

Recurse for a number of levels (-1 means unlimited).

=item * B<module_authors> => I<array[str]>

Only list depended modules published by specified author(s).

=item * B<module_authors_arent> => I<array[str]>

Do not list depended modules published by specified author(s).

=item * B<perl_version> => I<str> (default: "v5.34.0")

Set base Perl version for determining core modules.

=item * B<phase> => I<str> (default: "runtime")

=item * B<rel> => I<str> (default: "requires")

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

=item * B<with_xs_or_pp> => I<bool>

Check each dependency as XSE<sol>PP.


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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
