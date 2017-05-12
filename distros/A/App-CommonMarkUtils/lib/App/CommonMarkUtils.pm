package App::CommonMarkUtils;

our $DATE = '2017-03-21'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{commonmark_to_html} = {
    v => 1.1,
    summary => 'Convert CommonMark to HTML',
    args => {
        commonmark => {
            schema => 'str*',
            cmdline_src => 'stdin_or_files',
            req => 1,
            pos => 0,
        },
    },
};
sub commonmark_to_html {
    require CommonMark;

    my %args = @_;

    my $html = CommonMark->markdown_to_html($args{commonmark});

    [200, "OK", $html];
}

1;
# ABSTRACT: Collection of CLI utilities related to CommonMark

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CommonMarkUtils - Collection of CLI utilities related to CommonMark

=head1 VERSION

This document describes version 0.02 of App::CommonMarkUtils (from Perl distribution App-CommonMarkUtils), released on 2017-03-21.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
CommonMark:

=over

=item * L<commonmark-to-html>

=back

=head1 FUNCTIONS


=head2 commonmark_to_html

Usage:

 commonmark_to_html(%args) -> [status, msg, result, meta]

Convert CommonMark to HTML.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<commonmark>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-CommonMarkUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CommonMarkUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CommonMarkUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<http://commonmark.org>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
