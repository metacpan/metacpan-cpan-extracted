package App::QRCodeUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-04-18'; # DATE
our $DIST = 'App-QRCodeUtils'; # DIST
our $VERSION = '0.004'; # VERSION

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
    return [500, "Currently Image::DecodeQR cannot be built"];

    #require Image::DecodeQR;

    my %args = @_;

    my $str = Image::DecodeQR::decode($args{filename});

    [200, "OK", $str];
}

$SPEC{gen_qrcode} = {
    v => 1.1,
    summary => 'Generate QR Code and by default show it (or save it to a file)',
    args => {
        text => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        filename => {
            schema => 'filename*',
            pos => 1,
            description => <<'MARKDOWN',

If unspecified, will save to a temporary filename and show it with
<pm:Desktop::Open>.

MARKDOWN
        },
        format => {
            schema => ['str*', in=>[qw/png html txt/]],
            default => 'png',
        },
    },
    examples => [
    ],
};
sub gen_qrcode {
    require QRCode::Any;

    my %args = @_;
    my $format = $args{format} // 'png';

    my $filename = $args{filename};
    unless (defined $filename) {
        require File::Temp;
        (undef, $filename) = File::Temp::tempfile("qrcodeXXXXXXXXX", TMPDIR=>1, SUFFIX=>".$format");
    }

    my $res = QRCode::Any::encode_qrcode(
        format => $format,
        text => $args{text},
        filename => $filename,
    );
    return $res unless $res->[0] == 200;

    require Desktop::Open;
    Desktop::Open::open_desktop($filename);

    [200, "OK", undef, {"func.filename"=>$filename}];
}

1;
# ABSTRACT: Utilities related to QR Code

__END__

=pod

=encoding UTF-8

=head1 NAME

App::QRCodeUtils - Utilities related to QR Code

=head1 VERSION

This document describes version 0.004 of App::QRCodeUtils (from Perl distribution App-QRCodeUtils), released on 2024-04-18.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<decode-qrcode>

=item * L<gen-qrcode>

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



=head2 gen_qrcode

Usage:

 gen_qrcode(%args) -> [$status_code, $reason, $payload, \%result_meta]

Generate QR Code and by default show it (or save it to a file).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<filename> => I<filename>

If unspecified, will save to a temporary filename and show it with
L<Desktop::Open>.

=item * B<format> => I<str> (default: "png")

(No description)

=item * B<text>* => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-QRCodeUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-QRCodeUtils>.

=head1 SEE ALSO

L<App::GoogleAuthUtils>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-QRCodeUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
