package App::GoogleAuthUtils;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{gen_google_auth_qrcode} = {
    v => 1.1,
    summary => 'Generate Google authenticator QR code (barcode) from a secret key',
    description => <<'_',

When generating a new 2FA token, you are usually presented with a secret key as
well as a 2D barcode (QR code) representation of this secret key. You are
advised to store the secret key and it's usually more convenient to store the
key code instead of the QR code. But when entering the secret key to the Google
authenticator app, it's often more convenient to scan the barcode instead of
typing or copy-pasting the code.

This utility will convert the secret key code into bar code (opened in a
browser) so you can conveniently scan the bar code into your app.

_
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

    if (File::Which::which("qrencode")) {
        my $output = $args{output} // '-';

        my $cmd = join(
            "",
            "qrencode -o ", String::ShellQuote::shell_quote($output),
            " -d 300 -s 10 ",
            String::ShellQuote::shell_quote(
                join(
                    "",
                    "otpauth://totp/",
                    URI::Encode::uri_encode($args{issuer} . ($args{account} ? ":$args{account}" : "")),
                    "?secret=", $args{secret_key},
                    "&issuer=", $args{issuer},
                )
            ),
        );
        if ($output eq '-') {
            system "$cmd | display";
        } else {
            system $cmd;
        }
    } else {
        my $url = join(
            '',
            'https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr',
            '&chl=otpauth://totp/', (
                URI::Encode::uri_encode(
                    $args{issuer} . ($args{account} ? ":$args{account}" : "")),
                '%3Fsecret%3D', $args{secret_key},
                '%26issuer%3D', $args{issuer},
            ),
        );

        require Browser::Open;
        my $err = Browser::Open::open_browser($url);
        return [500, "Can't open browser for '$url'"] if $err;
    }
    [200];
}

1;
# ABSTRACT: Utilities related to Google Authenticator

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GoogleAuthUtils - Utilities related to Google Authenticator

=head1 VERSION

This document describes version 0.005 of App::GoogleAuthUtils (from Perl distribution App-GoogleAuthUtils), released on 2021-05-25.

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

=item * B<issuer>* => I<str>

=item * B<output> => I<filename>

=item * B<secret_key>* => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or "OK" if status is
200. Third element ($payload) is optional, the actual result. Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GoogleAuthUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GoogleAuthUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GoogleAuthUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::QRCodeUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
