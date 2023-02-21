package App::TextWrapUtils;

use 5.010001;
use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-12-13'; # DATE
our $DIST = 'App-TextWrapUtils'; # DIST
our $VERSION = '0.002'; # VERSION

our %SPEC;

our @BACKENDS = qw(
                      Text::ANSI::Fold
                      Text::ANSI::Util
                      Text::ANSI::WideUtil
                      Text::Fold
                      Text::LineFold
                      Text::WideChar::Util
                      Text::Wrap
              );

$SPEC{textwrap} = {
    v => 1.1,
    summary => 'Wrap (fold) text using one of several Perl modules',
    description => <<'_',

Paragraphs are separated with two or more blank lines.

_
    args => {
        filename => {
            schema => 'filename*',
            default => '-',
            pos => 0,
            description => <<'_',

Use dash (`-`) to read from stdin.

_
        },
        width => {
            schema => 'posint*',
            default => 80,
            cmdline_aliases => {w=>{}},
        },
        # XXX arg: initial indent string/number of spaces?
        # XXX arg: subsequent indent string/number of spaces?
        # XXX arg: option to not wrap verbatim paragraphs
        # XXX arg: pass per-backend options
        backend => {
            schema => ['perl::modname*', in=>\@BACKENDS],
            default => 'Text::ANSI::Util',
        },
    },
};
sub textwrap {
    require File::Slurper::Dash;

    my %args = @_;
    my $text = File::Slurper::Dash::read_text($args{filename});
    $text =~ s/\R/ /;

    my $backend = $args{backend} // 'Text::Wrap';
    my $width = $args{width} // 80;

    log_trace "Using text wrapping backend %s", $backend;

    my @paras = split /(\R{2,})/, $text;

    my $res = '';
    while (my ($para_text, $blank_lines) = splice @paras, 0, 2) {
        $para_text =~ s/\R/ /g;

        if ($backend eq 'Text::ANSI::Fold') {
            require Text::ANSI::Fold;
            $para_text = join("", map {"$_\n"} Text::ANSI::Fold->new(width=>$width)->text($para_text)->chops);
            $para_text =~ s/\R\z//;
        } elsif ($backend eq 'Text::ANSI::Util') {
            require Text::ANSI::Util;
            $para_text = Text::ANSI::Util::ta_wrap($para_text, $width);
        } elsif ($backend eq 'Text::ANSI::WideUtil') {
            require Text::ANSI::WideUtil;
            $para_text = Text::ANSI::WideUtil::ta_mbwrap($para_text, $width);
        } elsif ($backend eq 'Text::Fold') {
            require Text::Fold;
            $para_text = Text::Fold::fold_text($para_text, $width);
        } elsif ($backend eq 'Text::LineFold') {
            require Text::LineFold;
            $para_text = Text::LineFold->new(ColMax => $width)->fold('', '', $para_text);
            $para_text =~ s/\R\z//;
        } elsif ($backend eq 'Text::WideChar::Util') {
            require Text::WideChar::Util;
            $para_text = Text::WideChar::Util::mbwrap($para_text, $width);
        } elsif ($backend eq 'Text::Wrap') {
            require Text::Wrap;
            local $Text::Wrap::columns = $width;
            $para_text = Text::Wrap::wrap('', '', $para_text);
        } else {
            return [400, "Unknown backend '$backend'"];
        }

        $res .= $para_text . ($blank_lines // "");
    }
    [200, "OK", $res];
}

1;
# ABSTRACT: Utilities related to text wrapping

__END__

=pod

=encoding UTF-8

=head1 NAME

App::TextWrapUtils - Utilities related to text wrapping

=head1 VERSION

This document describes version 0.002 of App::TextWrapUtils (from Perl distribution App-TextWrapUtils), released on 2022-12-13.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<textwrap>

=back

Keywords: fold.

=head1 FUNCTIONS


=head2 textwrap

Usage:

 textwrap(%args) -> [$status_code, $reason, $payload, \%result_meta]

Wrap (fold) text using one of several Perl modules.

Paragraphs are separated with two or more blank lines.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<backend> => I<perl::modname> (default: "Text::ANSI::Util")

(No description)

=item * B<filename> => I<filename> (default: "-")

Use dash (C<->) to read from stdin.

=item * B<width> => I<posint> (default: 80)

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

Please visit the project's homepage at L<https://metacpan.org/release/App-TextWrapUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-TextWrapUtils>.

=head1 SEE ALSO

L<Text::Wrap> and other backends.

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-TextWrapUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
