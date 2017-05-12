package App::MarkdownUtils;

our $DATE = '2016-01-31'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{markdown_to_pod} = {
    v => 1.1,
    summary => 'Convert Markdown to POD',
    description => <<'_',

Currently using `Markdown::To::POD` perl module.

_
    args => {
        markdown => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            req => 1,
            pos => 0,
        },
    },
};
sub markdown_to_pod {
    require Markdown::To::POD;

    my %args = @_;

    my $pod = Markdown::To::POD::markdown_to_pod($args{markdown});

    [200, "OK", $pod];
}

$SPEC{markdown_to_html} = {
    v => 1.1,
    summary => 'Convert Markdown to HTML',
    description => <<'_',

Currently using `Text::Markdown` perl module.

_
    args => {
        markdown => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            req => 1,
            pos => 0,
        },
    },
};
sub markdown_to_html {
    require Text::Markdown;

    my %args = @_;

    my $html = Text::Markdown::markdown($args{markdown});

    [200, "OK", $html];
}

1;
# ABSTRACT: Collection of CLI utilities related to Markdown

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MarkdownUtils - Collection of CLI utilities related to Markdown

=head1 VERSION

This document describes version 0.02 of App::MarkdownUtils (from Perl distribution App-MarkdownUtils), released on 2016-01-31.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
Markdown:

=over

=item * L<markdown-to-html>

=item * L<markdown-to-pod>

=back

=head1 FUNCTIONS


=head2 markdown_to_html(%args) -> [status, msg, result, meta]

Convert Markdown to HTML.

Currently using C<Text::Markdown> perl module.

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<markdown>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 markdown_to_pod(%args) -> [status, msg, result, meta]

Convert Markdown to POD.

Currently using C<Markdown::To::POD> perl module.

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<markdown>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-MarkdownUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MarkdownToPODUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-MarkdownUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::CommonMarkUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
