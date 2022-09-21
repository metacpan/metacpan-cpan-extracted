package App::lcpan::Cmd::update;

use 5.010;
use strict;
use warnings;

require App::lcpan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-19'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.071'; # VERSION

our %SPEC;

$SPEC{handle_cmd} = $App::lcpan::SPEC{update};
*handle_cmd = \&App::lcpan::update;

1;
# ABSTRACT: Create/update local CPAN mirror

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::update - Create/update local CPAN mirror

=head1 VERSION

This document describes version 1.071 of App::lcpan::Cmd::update (from Perl distribution App-lcpan), released on 2022-09-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

CreateE<sol>update local CPAN mirror.

This subcommand first create/update the mirror files by downloading from a
remote CPAN mirror, then update the index.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<exclude_author> => I<array[str]>

Exclude files from certain author(s).

=item * B<force_update_index> => I<bool>

Update the index even though there is no change in files.

=item * B<include_author> => I<array[str]>

Only include files from certain author(s).

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<max_file_size> => I<int>

If set, skip downloading files larger than this.

=item * B<remote_url> => I<str>

Select CPAN mirror to download from.

=item * B<retry_delay> => I<int>

Number of seconds to delay between retry attempt.

=item * B<retry_max_attempts> => I<int>

Number of retry attempts on failed HTTP request.

=item * B<skip_file_indexing_pass_1> => I<bool>

=item * B<skip_file_indexing_pass_2> => I<bool>

=item * B<skip_file_indexing_pass_3> => I<bool>

=item * B<skip_index_file_patterns> => I<array[re]>

Skip one or more file patterns from being indexed.

=item * B<skip_index_files> => I<array[str]>

Skip one or more files from being indexed.

=item * B<skip_sub_indexing> => I<bool> (default: 1)

Since sub indexing is still experimental, it is not enabled by default. To
enable it, pass the C<--no-skip-sub-indexing> option.

=item * B<skip_sub_indexing_file_patterns> => I<array[re]>

Skip one or more file patterns from being parsed for subs.

=item * B<skip_sub_indexing_files> => I<array[str]>

Skip one or more files from being parsed for subs.

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

=item * B<update_files> => I<bool> (default: 1)

Update the files.

=item * B<update_index> => I<bool> (default: 1)

Update the index.

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
