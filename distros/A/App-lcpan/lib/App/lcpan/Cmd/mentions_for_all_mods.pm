package App::lcpan::Cmd::mentions_for_all_mods;

use 5.010;
use strict;
use warnings;
use Log::ger;

require App::lcpan;
require App::lcpan::Cmd::mentions_for_mod;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-19'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.071'; # VERSION

our %SPEC;

my $mentions_for_mod_args = $App::lcpan::Cmd::mentions_for_mod::SPEC{handle_cmd}{args};

$SPEC{'handle_cmd'} = {
    v => 1.1,
    summary => 'List PODs which mention all specified module(s)',
    description => <<'_',

This subcommand searches PODs that mention all of the specified modules. To
search for PODs that mention *any* of the specified modules, see the
`mentions-for-mods` subcommand.

_
    args => $mentions_for_mod_args,
};
sub handle_cmd {
    my %args = @_;

    my $mres = App::lcpan::Cmd::mentions_for_mod::handle_cmd(%args);
    return $mres unless $mres->[0] == 200;

    my $mods = $args{modules};

    my %counts; # key = content_path, value = hash of module name => count
    my %content_data; # key = content_path, value = data
    for my $e (@{ $mres->[2] }) {
        $counts{$e->{content_path}}{$e->{module}}++;
        $content_data{$e->{content_path}} //= {
            release          => $e->{release},
            mentioner_author => $e->{mentioner_author},
            content_path     => $e->{content_path},
        };
    }

    my $resmeta = {'table.fields' => [qw/content_path mentioner_author release/]};

    my @res;
    for my $cp (sort keys %counts) {
        next unless keys(%{ $counts{$cp} }) == @$mods;
        push @res, $content_data{$cp};
    }

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: List PODs which mention all specified module(s)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::mentions_for_all_mods - List PODs which mention all specified module(s)

=head1 VERSION

This document describes version 1.071 of App::lcpan::Cmd::mentions_for_all_mods (from Perl distribution App-lcpan), released on 2022-09-19.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

List PODs which mention all specified module(s).

This subcommand searches PODs that mention all of the specified modules. To
search for PODs that mention I<any> of the specified modules, see the
C<mentions-for-mods> subcommand.

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

=item * B<mentioner_authors> => I<array[str]>

Filter by author(s) of POD that does the mentioning.

=item * B<mentioner_authors_arent> => I<array[str]>

=item * B<mentioner_modules> => I<array[str]>

Filter by module(s) that do the mentioning.

=item * B<mentioner_scripts> => I<array[str]>

Filter by script(s) that do the mentioning.

=item * B<modules>* => I<array[perl::modname]>

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

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
