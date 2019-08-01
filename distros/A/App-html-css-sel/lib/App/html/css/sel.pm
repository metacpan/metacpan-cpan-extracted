package App::html::css::sel;

our $DATE = '2019-07-26'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{html_css_sel} = {
    v => 1.1,
    summary => 'Select HTML elements using CSS selector syntax',
    args => {
        expr => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        file => {
            schema => 'str*',
            'x.schema.entity' => 'filename',
            pos => 1,
            default => '-',
        },
        match_action => {
            schema => 'str*',
            default => 'print-as-string',
            cmdline_aliases => {
                count => { is_flag => 1, summary => 'Shortcut for --match-action=count', code => sub { $_[0]{match_action} = 'count' } },
                # dump
            },
        },
    },
};
sub html_css_sel {
    my %args = @_;

    my $expr = $args{expr};

    require Mojo::DOM;
    my $dom;
    if ($args{file} eq '-') {
        binmode STDIN, ":encoding(utf8)";
        $dom = Mojo::DOM->new(join "", <>);
    } else {
        # XXX use cached parse result when possible
        require File::Slurper;
        $dom = Mojo::DOM->new(File::Slurper::read_text($args{file}));
    }

    if ($args{match_action} eq 'count') {
        [200, "OK", $dom->find($expr)->size];
    } else {
        [200, "OK", [$dom->find($expr)->map('to_string')->each]];
    }
}

1;
# ABSTRACT: Select HTML elements using CSS selector syntax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::html::css::sel - Select HTML elements using CSS selector syntax

=head1 VERSION

This document describes version 0.003 of App::html::css::sel (from Perl distribution App-html-css-sel), released on 2019-07-26.

=head1 SYNOPSIS

=head1 FUNCTIONS


=head2 html_css_sel

Usage:

 html_css_sel(%args) -> [status, msg, payload, meta]

Select HTML elements using CSS selector syntax.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<expr>* => I<str>

=item * B<file> => I<str> (default: "-")

=item * B<match_action> => I<str> (default: "print-as-string")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-html-css-sel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-html-css-sel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-html-css-sel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<htmlsel> (from L<App::htmlsel>), to select HTML tree nodes using
L<CSel|Data::CSel> syntax.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
