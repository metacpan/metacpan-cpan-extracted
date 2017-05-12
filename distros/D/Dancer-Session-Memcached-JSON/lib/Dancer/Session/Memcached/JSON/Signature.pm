use strict;
use warnings;
package Dancer::Session::Memcached::JSON::Signature;

# Adapted from https://github.com/visionmedia/node-cookie-signature

use Digest::SHA qw(hmac_sha256_base64 sha1_hex);
use Function::Parameters qw(:strict);

use Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(sign unsign);

fun sign(Str $val, Str $secret) {
    my $mac = hmac_sha256_base64($val, $secret);
    $mac =~ s/\=+$//;

    return "s:$val.$mac";
}

fun unsign(Str $val, Str $secret) {
    $val =~ s/^s://;

    my ($str, $id) = split /\./, $val;
    my $mac = sign($str, $secret);

    return $str
        if sha1_hex($mac) eq sha1_hex("s:$val");
}

1;

__END__

=pod

=head1 NAME

Dancer::Session::Memcached::JSON::Signature

=head1 VERSION

version 0.005

=head1 AUTHOR

Forest Belton <forest@homolo.gy>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Forest Belton.

This is free software, licensed under:

  The MIT (X11) License

=cut
