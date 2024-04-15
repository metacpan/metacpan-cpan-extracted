package App::sort_by_example;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Sort;
use AppBase::Sort::File ();
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-06'; # DATE
our $DIST = 'AppBase-Sort'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'sort_by_example',
    base_name   => 'AppBase::Sort::sort_appbase',
    summary     => 'Sort lines of text by example',
    description => <<'_',

This is a sort-like utility that is based on <pm:AppBase::Sort>, mainly for
demoing and testing the module.

_
    add_args    => {
        %AppBase::Sort::File::argspecs_files,
        examples => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'example',
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
    modify_args => {
        files => sub {
            my $argspec = shift;
            delete $argspec->{pos};
            delete $argspec->{slurpy};
        },
    },
    modify_meta => sub {
        my $meta = shift;

        $meta->{examples} = [
            {
                src_plang => 'bash',
                src => 'some-cmd | sort-by-examples foo bar baz',
                summary => 'Put "foo", "bar", "baz" lines first, in that order',
                test => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} //= [];
        push @{ $meta->{links} }, {url=>'pm:Sort::ByExample'};
        push @{ $meta->{links} }, {url=>'pm:App::sort_by_spec'};
    },
    output_code => sub {
        my %args = @_;
        my $examples = delete $args{examples};

        AppBase::Sort::File::set_source_arg(\%args);
        $args{_sortgen} = sub {
            my $args = shift;
            require Sort::ByExample;
            my $cmp = Sort::ByExample->cmp($examples);
            my $sort = sub {
                my ($a, $b) = @_;
                chomp($a); chomp($b);
                $cmp->($a, $b);
            };
            return ($sort);
        };
        AppBase::Sort::sort_appbase(%args);
    },
);

1;
# ABSTRACT: Sort lines of text by example

__END__

=pod

=encoding UTF-8

=head1 NAME

App::sort_by_example - Sort lines of text by example

=head1 VERSION

This document describes version 0.003 of App::sort_by_example (from Perl distribution AppBase-Sort), released on 2024-03-06.

=head1 FUNCTIONS


=head2 sort_by_example

Usage:

 sort_by_example(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort lines of text by example.

This is a sort-like utility that is based on L<AppBase::Sort>, mainly for
demoing and testing the module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dereference_recursive> => I<true>

Read all files under each directory, recursively, following all symbolic links, unlike -r.

=item * B<examples>* => I<array[str]>

(No description)

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

Please visit the project's homepage at L<https://metacpan.org/release/AppBase-Sort>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-AppBase-Sort>.

=head1 SEE ALSO


L<Sort::ByExample>.

L<App::sort_by_spec>.

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

This software is copyright (c) 2024, 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=AppBase-Sort>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
