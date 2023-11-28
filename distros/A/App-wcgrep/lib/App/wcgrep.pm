## no critic: InputOutput::RequireBriefOpen

package App::wcgrep;

use 5.010001;
use strict;
use warnings;
use Log::ger;

use AppBase::Grep;
use AppBase::Grep::File ();
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-17'; # DATE
our $DIST = 'App-wcgrep'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

gen_modified_sub(
    output_name => 'wcgrep',
    base_name   => 'AppBase::Grep::grep',
    summary     => 'Print lines matching a wildcard pattern',
    description => <<'_',

This is another grep-like utility that is based on <pm:AppBase::Grep>, mainly
for demoing and testing the module. It accepts bash wildcard pattern instead of
regular expression.

_
    add_args    => {
        %AppBase::Grep::File::argspecs_files,
    },
    modify_meta => sub {
        my $meta = shift;

        # modify arg
        $meta->{args}{pattern} = {
            summary => 'Specify *wildcard pattern* to search for',
            schema => 'str*',
            req => 1,
            pos => 0,
        };

        # delete args
        delete $meta->{args}{regexps};
        delete $meta->{args}{dash_prefix_inverts};
        delete $meta->{args}{all};

        $meta->{examples} = [
            {
                summary => 'Show lines that contain foo and bar, in that order',
                'src' => q([[prog]] 'foo*bar' file1 file2),
                'src_plang' => 'bash',
                'test' => 0,
                'x.doc.show_result' => 0,
            },
        ];
        $meta->{links} = [
            {url=>'prog:abgrep'},
        ];
    },
    output_code => sub {
        my %args = @_;

        # convert wildcard pattern to regex
        my $pat = delete $args{pattern};
        require String::Wildcard::Bash;
        my $re = String::Wildcard::Bash::convert_wildcard_to_re($pat);
        $args{regexps} = [$re];

        AppBase::Grep::File::set_source_arg(\%args);
        AppBase::Grep::grep(%args);
    },
);

1;
# ABSTRACT: Print lines matching a wildcard pattern

__END__

=pod

=encoding UTF-8

=head1 NAME

App::wcgrep - Print lines matching a wildcard pattern

=head1 VERSION

This document describes version 0.002 of App::wcgrep (from Perl distribution App-wcgrep), released on 2023-11-17.

=head1 FUNCTIONS


=head2 wcgrep

Usage:

 wcgrep(%args) -> [$status_code, $reason, $payload, \%result_meta]

Print lines matching a wildcard pattern.

This is another grep-like utility that is based on L<AppBase::Grep>, mainly
for demoing and testing the module. It accepts bash wildcard pattern instead of
regular expression.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<color> => I<str> (default: "auto")

Specify when to show color (never, always, or autoE<sol>when interactive).

=item * B<count> => I<true>

Supress normal output, return a count of matching lines.

=item * B<dereference_recursive> => I<true>

Read all files under each directory, recursively, following all symbolic links, unlike -r.

=item * B<files> => I<array[filename]>

(No description)

=item * B<ignore_case> => I<bool>

If set to true, will search case-insensitively.

=item * B<invert_match> => I<bool>

Invert the sense of matching.

=item * B<line_number> => I<true>

Show line number along with matches.

=item * B<pattern>* => I<str>

Specify *wildcard pattern* to search for.

=item * B<quiet> => I<true>

Do not print matches, only return appropriate exit code.

=item * B<recursive> => I<true>

Read all files under each directory, recursively, following symbolic links only if they are on the command line.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-wcgrep>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-wcgrep>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-wcgrep>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
