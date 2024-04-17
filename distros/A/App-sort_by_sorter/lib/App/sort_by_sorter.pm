package App::sort_by_sorter;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Sort;
use AppBase::Sort::File ();
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-06'; # DATE
our $DIST = 'App-sort_by_sorter'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'sort_by_sorter',
    base_name   => 'AppBase::Sort::sort_appbase',
    summary     => 'Sort lines of text by a Sorter module',
    description => <<'MARKDOWN',

This utility lets you sort lines of text using one of the available Sorter::*
perl modules.

MARKDOWN
    add_args    => {
        %AppBase::Sort::File::argspecs_files,
        sorter_module => {
            schema => "perl::sorter::modname_with_optional_args",
            req => 1,
            pos => 0,
        },
    },
    delete_args => [qw/ignore_case reverse/],
    modify_args => {
        files => sub {
            my $argspec = shift;
            #delete $argspec->{pos};
            #delete $argspec->{slurpy};
        },
    },
    modify_meta => sub {
        my $meta = shift;

        $meta->{examples} = [
            {
                src_plang => 'bash',
                src => q[ someprog ... | sort-by-sorter date_in_text=reverse,1],
                test => 0,
                'x.doc.show_result' => 0,
            },
        ];
    },
    output_code => sub {
        require Module::Load::Util;

        my %oc_args = @_;

        AppBase::Sort::File::set_source_arg(\%oc_args);
        $oc_args{_gen_sorter} = sub {
            my $gs_args = shift;
            Module::Load::Util::call_module_function_with_optional_args(
                {
                    ns_prefix => 'Sorter',
                    function => 'gen_sorter',
                },
                $gs_args->{sorter_module});
        };
        AppBase::Sort::sort_appbase(%oc_args);
    },
);

1;
# ABSTRACT: Sort lines of text by a Sorter module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::sort_by_sorter - Sort lines of text by a Sorter module

=head1 VERSION

This document describes version 0.001 of App::sort_by_sorter (from Perl distribution App-sort_by_sorter), released on 2024-03-06.

=head1 FUNCTIONS


=head2 sort_by_sorter

Usage:

 sort_by_sorter(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort lines of text by a Sorter module.

This utility lets you sort lines of text using one of the available Sorter::*
perl modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dereference_recursive> => I<true>

Read all files under each directory, recursively, following all symbolic links, unlike -r.

=item * B<files> => I<array[filename]>

(No description)

=item * B<ignore_case> => I<bool>

If set to true, will search case-insensitively.

=item * B<recursive> => I<true>

Read all files under each directory, recursively, following symbolic links only if they are on the command line.

=item * B<reverse> => I<bool>

Reverse sort order.

=item * B<sorter_module>* => I<perl::sorter::modname_with_optional_args>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-sort_by_sorter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-sort_by_sorter>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-sort_by_sorter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
