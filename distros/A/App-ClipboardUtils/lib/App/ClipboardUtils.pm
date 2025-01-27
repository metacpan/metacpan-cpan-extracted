package App::ClipboardUtils;

use strict;
use warnings;
use Log::ger;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-01-27'; # DATE
our $DIST = 'App-ClipboardUtils'; # DIST
our $VERSION = '0.009'; # VERSION

use Clipboard::Any ();
use Clone::PP qw(clone);

our %SPEC;

$SPEC{add_clipboard_content} = clone $Clipboard::Any::SPEC{add_clipboard_content};
$SPEC{add_clipboard_content}{args}{split_by} = {
    summary => 'Split content by specified string/regex, add the split content as multiple clipboard entries',
    schema => ['str_or_re*'],
    description => <<'MARKDOWN',

Note that if you supply a regex, you should not have any capture groups in the
regex.

MARKDOWN
    cmdline_aliases => {s=>{}},
};
$SPEC{add_clipboard_content}{args}{tee} = {
    summary => 'Pass stdin to stdout',
    schema => ['true*'],
    description => <<'MARKDOWN',

MARKDOWN
    cmdline_aliases => {t=>{}},
};
sub add_clipboard_content {
    my %args = @_;
    my $split_by = delete $args{split_by};
    my $tee = delete $args{tee};

    if (defined $split_by) {
        my $content = delete $args{content};
        my @split_parts = split /($split_by)/, $content;
        log_trace "split_by=%s, split_contents=%s", $split_by, \@split_parts;

        my $res = [204, "OK (no content)"];
        my $i = 0;
        while (my ($part, $separator) = splice @split_parts, 0, 2) {
            if ($tee) {
                print $part;
                print $separator if defined $separator;
            }

            # do not add empty part to clipboard
            if (length $part) {
                $res = Clipboard::Any::add_clipboard_content(
                    %args, content => $part,
                ); # currently we use the last add_clipboard_content status
            }
        }
        $res->[3]{'func.parts'} = @split_parts;
        $res;
    } else {
        print $args{content} if $tee;
        Clipboard::Any::add_clipboard_content(%args);
    }
}

1;
# ABSTRACT: CLI utilities related to clipboard

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ClipboardUtils - CLI utilities related to clipboard

=head1 VERSION

This document describes version 0.009 of App::ClipboardUtils (from Perl distribution App-ClipboardUtils), released on 2025-01-27.

=head1 DESCRIPTION

This distribution contains the following CLI utilities related to clipboard:

=over

=item 1. L<add-clipboard-content>

=item 2. L<ca>

=item 3. L<cg>

=item 4. L<clear-clipboard-content>

=item 5. L<clear-clipboard-history>

=item 6. L<clipadd>

=item 7. L<clipget>

=item 8. L<detect-clipboard-manager>

=item 9. L<get-clipboard-content>

=item 10. L<get-clipboard-history-item>

=item 11. L<list-clipboard-history>

=back

=head1 FUNCTIONS


=head2 add_clipboard_content

Usage:

 add_clipboard_content(%args) -> [$status_code, $reason, $payload, \%result_meta]

Add a new content to the clipboard.

For C<xclip>: when adding content, the primary selection is set. The clipboard
content is unchanged.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<clipboard_manager> => I<str>

Explicitly set clipboard manager to use.

The default, when left undef, is to detect what clipboard manager is running.

=item * B<content> => I<str>

(No description)

=item * B<split_by> => I<str_or_re>

Split content by specified stringE<sol>regex, add the split content as multiple clipboard entries.

Note that if you supply a regex, you should not have any capture groups in the
regex.

=item * B<tee> => I<true>

Pass stdin to stdout.



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

Please visit the project's homepage at L<https://metacpan.org/release/App-ClipboardUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ClipboardUtils>.

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

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ClipboardUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
