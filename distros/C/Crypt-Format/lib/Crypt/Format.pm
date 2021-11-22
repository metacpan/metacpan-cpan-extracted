package Crypt::Format;

use strict;
use warnings;

our $VERSION = '0.12';

our $BASE64_MODULE = 'MIME::Base64';

=encoding utf-8

=head1 NAME

Crypt::Format - Conversion utilities for encryption applications

=head1 SYNOPSIS

    use Crypt::Format;

    my $der = Crypt::Format::pem2der($pem);
    my $pem = Crypt::Format::der2pem($der, 'CERTIFICATE REQUEST');

    my $good_pem = Crypt::Format::normalize_pem($weird_pem);

    # Split PEM chains such as application/pem-certificate-chain …
    my @pems = Crypt::Format::split_pem_chain($pem_chain);

    {
        #If, for whatever reason, you don’t like MIME::Base64,
        #then customize this. The module must have encode() and/or decode()
        #functions, depending on which of this module’s functions you use.
        #
        local $Crypt::Format::BASE64_MODULE = '..';

        Crypt::Format::...
    }

=head1 DESCRIPTION

Not much more to say! This module is for simple conversions that I got
tired of writing out.

=cut

my $_LINE_SEP = "\n";

sub der2pem {
    my ($der_r, $whatsit) = (\$_[0], $_[1]);

    die "Missing object type!" if !$whatsit;

    my $pem = _do_base64('encode', $$der_r, q<>);
    $pem = join( $_LINE_SEP, $pem =~ m<(.{1,64})>g, q<> );

    substr( $pem, 0, 0, "-----BEGIN $whatsit-----$_LINE_SEP" );
    substr( $pem, length($pem), 0, "-----END $whatsit-----" );

    return $pem;
}

sub pem2der {
    my ($pem) = @_;

    # Strip the first line:
    $pem =~ s<.+?[\x0d\x0a]+><>s;

    # Strip the last line and any trailing CRs and LFs:
    $pem =~ s<[\x0d\x0a]+ [^\x0d\x0a]+? [\x0d\x0a]*\z><>sx;

    return _do_base64('decode', $pem);
}

sub split_pem_chain {
    return split m[(?<=-)[\x0d\x0a]+(?=-)], shift();
}

sub _do_base64 {
    my $path = "$BASE64_MODULE.pm";
    $path =~ s<::></>g;

    _load_module($BASE64_MODULE) if !$INC{$path};

    my $cr = $BASE64_MODULE->can(shift);
    return $cr->(@_);
}

sub _load_module {
    local $@;
    eval "use $_[0]; 1" or die;
    return $_[0];
}

sub normalize_pem {
    my ($pem) = @_;

    $pem =~ m<BEGIN ([^-]+)> or die "Invalid PEM: “$pem”";

    return der2pem( pem2der( $pem ), $1 );
}

=pod

=head1 AUTHOR

Felipe Gasper (FELIPE)

=head1 REPOSITORY

https://github.com/FGasper/p5-Crypt-Format

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
