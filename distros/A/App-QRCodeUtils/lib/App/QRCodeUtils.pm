package App::QRCodeUtils;

our $DATE = '2021-05-25'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{decode_qrcode} = {
    v => 1.1,
    summary => 'Decode QR Code',
    args => {
        filename => {
            schema => 'filename*',
            req => 1,
            pos => 0,
        },
    },
    examples => [
    ],
};
sub decode_qrcode {
    require Image::DecodeQR;

    my %args = @_;

    my $str = Image::DecodeQR::decode($args{filename});

    [200, "OK", $str];
}

1;
# ABSTRACT: Utilities related to QR Code

__END__

=pod

=encoding UTF-8

=head1 NAME

App::QRCodeUtils - Utilities related to QR Code

=head1 VERSION

This document describes version 0.002 of App::QRCodeUtils (from Perl distribution App-QRCodeUtils), released on 2021-05-25.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<decode-qrcode>

=back

=head1 FUNCTIONS


=head2 decode_qrcode

Usage:

 decode_qrcode(%args) -> [$status_code, $reason, $payload, \%result_meta]

Decode QR Code.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename>* => I<filename>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-QRCodeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-QRCodeUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-QRCodeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::GoogleAuthUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
