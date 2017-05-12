package Authen::HOTP;

use Digest::SHA1 qw(sha1);
use Digest::HMAC qw(hmac);
use Math::BigInt;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( hotp ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );

our $VERSION = '0.02';

sub hotp
{
    my ($secret, $c, $digits) = @_;

    # guess hex encoded
    $secret = join("", map chr(hex), $secret =~ /(..)/g)
        if $secret =~ /^[a-fA-F0-9]{32,}$/;

    $c = new Math::BigInt ($c)
	unless ref $c eq "Math::BigInt";

    $digits ||= 6;

    die unless length $secret >= 16; # 128-bit minimum
    die unless ref $c eq "Math::BigInt";
    die unless $digits >= 6 and $digits <= 10;

    (my $hex = $c->as_hex) =~ s/^0x(.*)/"0"x(16 - length $1).$1/e;
    my $bin = join '', map chr hex, $hex =~ /(..)/g; # pack 64-bit big endian
    my $hash = hmac $bin, $secret, \&sha1;
    my $offset = hex substr unpack("H*" => $hash), -1;
    my $dt = unpack "N" => substr $hash, $offset, 4;
    $dt &= 0x7fffffff; # 31-bit
    $dt %= (10 ** $digits); # limit range

    sprintf "%0${digits}d", $dt;
}

1;
__END__

=head1 NAME

Authen::HOTP - An HMAC-Based One-Time Password Algorithm

=head1 SYNOPSIS

  use Authen::HOTP qw(hotp);

  my $secret = "abcdefghijklmnopqrst"; # 20-byte
  my $counter = 0;
  my $digits = 6;

  my $pass = hotp($secret, $counter, $digits);

=head1 DESCRIPTION

This library implements the HOTP algorithm as described in RFC 4226.

http://www.rfc-editor.org/rfc/rfc4226.txt

=head2 EXPORT

=head1 SEE ALSO

=head1 AUTHOR

Iain Wade, E<lt>iwade@optusnet.com.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
