package App::sort_by_comparer;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Sort;
use AppBase::Sort::File ();
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-07'; # DATE
our $DIST = 'App-sort_by_comparer'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'sort_by_comparer',
    base_name   => 'AppBase::Sort::sort_appbase',
    summary     => 'Sort lines of text by a Comparer module',
    description => <<'MARKDOWN',

This utility lets you sort lines of text using one of the available Comparer::*
perl modules.

MARKDOWN
    add_args    => {
        %AppBase::Sort::File::argspecs_files,
        comparer_module => {
            schema => "perl::comparer::modname_with_optional_args",
            pos => 0,
            req => 1,
        },
    },
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
                src => q[ someprog ... | sort-by-comparer similarity=string,foo],
                test => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} //= [];
        push @{ $meta->{links} }, {url=>'pm:Comparer'};
        push @{ $meta->{links} }, {url=>'prog:sort-by-sorter'};
        push @{ $meta->{links} }, {url=>'prog:sort-by-sortkey'};
    },
    output_code => sub {
        require Module::Load::Util;

        my %oc_args = @_;

        AppBase::Sort::File::set_source_arg(\%oc_args);
        $oc_args{_gen_comparer} = sub {
            my $gc_args = shift;
            Module::Load::Util::call_module_function_with_optional_args(
                {ns_prefix=>"Comparer", function=>"gen_comparer"},
                $gc_args->{comparer_module});
        };
        AppBase::Sort::sort_appbase(%oc_args);
    },
);

1;
# ABSTRACT: Sort lines of text by a Comparer module

__END__

=pod

=encoding UTF-8

=head1 NAME

App::sort_by_comparer - Sort lines of text by a Comparer module

=head1 VERSION

This document describes version 0.002 of App::sort_by_comparer (from Perl distribution App-sort_by_comparer), released on 2024-03-07.

=head1 FUNCTIONS


=head2 sort_by_comparer

Usage:

 sort_by_comparer(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort lines of text by a Comparer module.

This utility lets you sort lines of text using one of the available Comparer::*
perl modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<comparer_module>* => I<perl::comparer::modname_with_optional_args>

(No description)

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

Please visit the project's homepage at L<https://metacpan.org/release/App-sort_by_comparer>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-sort_by_comparer>.

=head1 SEE ALSO


L<Comparer>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-sort_by_comparer>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
