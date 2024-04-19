package App::GoogleAuthUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-04-18'; # DATE
our $DIST = 'App-GoogleAuthUtils'; # DIST
our $VERSION = '0.006'; # VERSION

our %SPEC;

$SPEC{gen_google_auth_qrcode} = {
    v => 1.1,
    summary => 'Generate Google authenticator QR code (barcode) from a secret key',
    description => <<'MARKDOWN',

When generating a new 2FA token, you are usually presented with a secret key as
well as a 2D barcode (QR code) representation of this secret key. You are
advised to store the secret key and it's usually more convenient to store the
key code instead of the QR code. But when entering the secret key to the Google
authenticator app, it's often more convenient to scan the barcode instead of
typing or copy-pasting the code.

This utility will convert the secret key code into bar code (opened in a
browser) so you can conveniently scan the bar code into your app.

MARKDOWN
    args => {
        secret_key => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        issuer => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
        account => {
            schema => 'str*',
            pos => 2,
        },
        output => {
            schema => 'filename*',
            cmdline_aliases => {o=>{}},
        },
    },
    examples => [
        {
            args => {
                secret_key => '6XDT6TSOGR5SCWKHXZ4DFBRXJVZGAKAW',
                issuer => 'example.com',
            },
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub gen_google_auth_qrcode {
    require File::Which;
    require String::ShellQuote;
    require URI::Encode;

    my %args = @_;

    my $url = join(
        "",
        "otpauth://totp/",
        URI::Encode::uri_encode($args{issuer} . ($args{account} ? ":$args{account}" : "")),
        "?secret=", $args{secret_key},
        "&issuer=", $args{issuer},
    );

    require App::QRCodeUtils;
    App::QRCodeUtils::gen_qrcode(text => $url);
}

1;
# ABSTRACT: Utilities related to Google Authenticator

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GoogleAuthUtils - Utilities related to Google Authenticator

=head1 VERSION

This document describes version 0.006 of App::GoogleAuthUtils (from Perl distribution App-GoogleAuthUtils), released on 2024-04-18.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<gen-google-auth-qrcode>

=back

=head1 FUNCTIONS


=head2 gen_google_auth_qrcode

Usage:

 gen_google_auth_qrcode(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate Google authenticator QR code (barcode) from a secret key.

Examples:

=over

=item * Example #1:

 gen_google_auth_qrcode(
   secret_key => "6XDT6TSOGR5SCWKHXZ4DFBRXJVZGAKAW",
   issuer => "example.com"
 );

=back

When generating a new 2FA token, you are usually presented with a secret key as
well as a 2D barcode (QR code) representation of this secret key. You are
advised to store the secret key and it's usually more convenient to store the
key code instead of the QR code. But when entering the secret key to the Google
authenticator app, it's often more convenient to scan the barcode instead of
typing or copy-pasting the code.

This utility will convert the secret key code into bar code (opened in a
browser) so you can conveniently scan the bar code into your app.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account> => I<str>

(No description)

=item * B<issuer>* => I<str>

(No description)

=item * B<output> => I<filename>

(No description)

=item * B<secret_key>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-GoogleAuthUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GoogleAuthUtils>.

=head1 SEE ALSO

L<App::QRCodeUtils>

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

This software is copyright (c) 2024, 2021, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GoogleAuthUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
