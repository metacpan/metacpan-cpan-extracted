package App::sort_by_spec;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Sort;
use AppBase::Sort::File ();
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-06'; # DATE
our $DIST = 'App-sort_by_spec'; # DIST
our $VERSION = '0.003'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'sort_by_spec',
    base_name   => 'AppBase::Sort::sort_appbase',
    summary     => 'Sort lines of text by spec',
    description => <<'MARKDOWN',

This utility lets you sort lines of text "by spec". Sorting by spec in an
advanced form of sorting by example. In addition to specifying example strings,
you can also specify regexes or Perl sorter codes. For more details, see the
sorting backend module <pm:Sort::BySpec>.

To specify a regex on the command-line, use one of these forms:

    /.../
    qr(...)

and to specify Perl code on the command-line, use this form:

    sub { ... }

MARKDOWN
    add_args    => {
        %AppBase::Sort::File::argspecs_files,
        specs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'spec',
            schema => ['array*', of=>'str_or_re_or_code*'],
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
                src => q[ perl -E 'say for (1..15,42)' | sort-by-spec 'qr([13579]\z)' 'sub { $_[0] <=> $_[1] }' 4 2 42 'qr([13579]\z)' 'sub { $_[0] <=> $_[1] }'],
                summary => 'Put odd numbers first in ascending order, then put the specific numbers (4,2,42), then put even numbers last in descending order',
                description => <<'MARKDOWN',

This example is taken from the <pm:Sort::BySpec>'s Synopsis.

MARKDOWN
                test => 0,
                'x.doc.show_result' => 0,
            },
        ];

        $meta->{links} //= [];
        push @{ $meta->{links} }, {url=>'pm:Sort::BySpec'};
        push @{ $meta->{links} }, {url=>'pm:App::sort_by_example'};
    },
    output_code => sub {
        my %args = @_;
        my $examples = delete $args{examples};

        AppBase::Sort::File::set_source_arg(\%args);
        $args{_sortgen} = sub {
            my $args = shift;
            require Sort::BySpec;
            my $spec = $args->{specs};
            my $cmp = Sort::BySpec::cmp_by_spec(spec => $spec, reverse => $args->{reverse});
            my $sort = sub {
                my ($a, $b) = @_;
                chomp($a); chomp($b);
                if ($args->{ignore_case}) { $a = lc $a; $b = lc $b }
                $cmp->($a, $b);
            };
            return ($sort, 1);
        };
        AppBase::Sort::sort_appbase(%args);
    },
);

1;
# ABSTRACT: Sort lines of text by spec

__END__

=pod

=encoding UTF-8

=head1 NAME

App::sort_by_spec - Sort lines of text by spec

=head1 VERSION

This document describes version 0.003 of App::sort_by_spec (from Perl distribution App-sort_by_spec), released on 2023-09-06.

=head1 FUNCTIONS


=head2 sort_by_spec

Usage:

 sort_by_spec(%args) -> [$status_code, $reason, $payload, \%result_meta]

Sort lines of text by spec.

This utility lets you sort lines of text "by spec". Sorting by spec in an
advanced form of sorting by example. In addition to specifying example strings,
you can also specify regexes or Perl sorter codes. For more details, see the
sorting backend module L<Sort::BySpec>.

To specify a regex on the command-line, use one of these forms:

 /.../
 qr(...)

and to specify Perl code on the command-line, use this form:

 sub { ... }

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

=item * B<specs>* => I<array[str_or_re_or_code]>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-sort_by_spec>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-sort_by_spec>.

=head1 SEE ALSO


L<Sort::BySpec>.

L<App::sort_by_example>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-sort_by_spec>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
