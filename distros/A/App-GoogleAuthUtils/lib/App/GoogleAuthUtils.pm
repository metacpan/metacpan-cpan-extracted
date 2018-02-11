package App::GoogleAuthUtils;

our $DATE = '2018-02-08'; # DATE
our $VERSION = '0.001'; # VERSION

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
    },
    examples => [
        {
            args => {
                secret_key => '6XDT6TSOGR5SCWKHXZ4DFBRXJVZGAKAW',
                issuer => 'example.com',
            },
        },
    ],
};
sub gen_google_auth_qrcode {
    require URI::Encode;

    my %args = @_;

    my $url = join(
        '',
        'https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr',
        '&chl=otpauth://totp/', (
            URI::Encode::uri_encode(
                $args{issuer} . ($args{account} ? ":$args{account}" : "")),
            '%3Fsecret%3D', $args{secret_key}, '%26issuer%3D', $args{issuer},
        ),
    );

    require Browser::Open;
    my $err = Browser::Open::open_browser($url);
    return [500, "Can't open browser for '$url'"] if $err;
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

This document describes version 0.001 of App::GoogleAuthUtils (from Perl distribution App-GoogleAuthUtils), released on 2018-02-08.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<gen-google-auth-qrcode>

=back

=head1 FUNCTIONS


=head2 gen_google_auth_qrcode

Usage:

 gen_google_auth_qrcode(%args) -> [status, msg, result, meta]

Generate Google authenticator QR code (barcode) from a secret key.

Examples:

=over

=item * Example #1:

 gen_google_auth_qrcode(
 secret_key => "6XDT6TSOGR5SCWKHXZ4DFBRXJVZGAKAW",
   issuer => "example.com"
 );

Result:

 undef

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

=item * B<secret_key>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-GoogleAuthUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GoogleAuthUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GoogleAuthUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
