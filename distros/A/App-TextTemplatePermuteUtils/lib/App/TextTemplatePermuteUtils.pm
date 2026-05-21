package App::TextTemplatePermuteUtils;

use 5.010001;
use strict;
use warnings;

#use File::Slurper qw(read_text);
use List::Util ();
use Text::Template::Permute;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2026-02-22'; # DATE
our $DIST = 'App-TextTemplatePermuteUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

$SPEC{template_permute} = {
    v => 1.1,
    summary => 'Process a Text::Template::Permute template and output the results',
    args => {
        template => {
            summary => 'The template string',
            schema => 'str*',
            pos => 0,
            cmdline_src => 'stdin_or_file',
        },
        array => {
            summary => 'Return items as array, not as a single string',
            schema => 'bool*',
            cmdline_aliases => {a => {}},
        },
        clipboard => {
            summary => 'Add items to clipboard',
            schema => ['str*', in=>['tee','only']],
            cmdline_aliases => {
                Y => {is_flag=>1, summary=>'Shortcut for --clipboard=tee', code=>sub { $_[0]{clipboard} = 'tee' }},
                y => {is_flag=>1, summary=>'Shortcut for --clipboard=only', code=>sub { $_[0]{clipboard} = 'only' }},
            },
        },
        items => {
            summary => 'Only return this many items',
            schema => 'posint*',
            cmdline_aliases => {n => {}},
        },
        shuffle => {
            summary => 'Shuffle/randomize order or results',
            schema => 'bool*',
            cmdline_aliases => {r => {}},
        },
        separator => {
            summary => 'String to add as separator between items (only when not specifying --array)',
            schema => 'str*',
            cmdline_aliases => {s => {}},
        },
    },
};
sub template_permute {
    my %args = @_;

    my $clipboard = $args{clipboard} // '';

    my $template = $args{template};
    my $ttp = Text::Template::Permute->new;
    $ttp->template($template);
    my @res = $ttp->process;

    if ($args{shuffle}) {
        @res = List::Util::shuffle(@res);
    }
    if ($args{items} && $args{items} < @res) {
        splice @res, $args{items};
    }

    unless ($args{array}) {
        my $separator = $args{separator} // '';
        $separator .= "\n" unless $separator =~ /\R\z/;
        my $res = join $separator, @res;
        @res = ($res);
    }

    if ($clipboard) {
        require Clipboard::Any;
        for my $content (@res) {
            Clipboard::Any::add_clipboard_content(content => $content);
        }
    }

    if ($clipboard eq 'only') {
        [200, "OK"];
    } elsif ($args{array}) {
        [200, "OK", \@res];
    } else {
        [200, "OK", $res[0]];
    }
}

1;
# ABSTRACT: CLI utilities related to Text::Template::Permute

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TextTemplatePermuteUtils - CLI utilities related to Text::Template::Permute

=head1 VERSION

This document describes version 0.002 of App::TextTemplatePermuteUtils (from Perl distribution App-TextTemplatePermuteUtils), released on 2026-02-22.

=head1 DESCRIPTION

This distributions provides the following command-line utilities related to
text fragment:

=over

=item * L<template-permute>

=back

=head1 FUNCTIONS


=head2 template_permute

Usage:

 template_permute(%args) -> [$status_code, $reason, $payload, \%result_meta]

Process a Text::Template::Permute template and output the results.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<array> => I<bool>

Return items as array, not as a single string.

=item * B<clipboard> => I<str>

Add items to clipboard.

=item * B<items> => I<posint>

Only return this many items.

=item * B<separator> => I<str>

String to add as separator between items (only when not specifying --array).

=item * B<shuffle> => I<bool>

ShuffleE<sol>randomize order or results.

=item * B<template> => I<str>

The template string.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-TextTemplatePermuteUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TextTemplatePermuteUtils>.

=head1 SEE ALSO

L<Text::Template::Permute>

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

This software is copyright (c) 2026 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TextTemplatePermuteUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
