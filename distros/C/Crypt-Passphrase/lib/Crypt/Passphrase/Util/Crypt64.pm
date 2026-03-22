package Crypt::Passphrase::Util::Crypt64;
$Crypt::Passphrase::Util::Crypt64::VERSION = '0.022';
use strict;
use warnings;

use Exporter 'import';
my @strings = qw/encode_crypt64 decode_crypt64/;
my @numbers = qw/encode_crypt64_number decode_crypt64_number/;
our @EXPORT_OK = (@strings, @numbers);
our %EXPORT_TAGS = (
	all => \@EXPORT_OK,
	strings => \@strings,
	numbers => \@numbers,
);

use Carp 'croak';

my $base64_digits = './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

sub encode_crypt64 {
	my $bytes = shift;
	my $nbytes = length $bytes;
	my $npadbytes = 2 - ($nbytes + 2) % 3;
	$bytes .= "\0" x $npadbytes;
	my $digits = '';
	for (my $i = 0; $i < $nbytes; $i += 3) {
		my $v = ord(substr $bytes, $i, 1) |
			(ord(substr $bytes, $i + 1, 1) << 8) |
			(ord(substr $bytes, $i + 2, 1) << 16);
			$digits .= substr($base64_digits, $v & 0x3f, 1) .
			substr($base64_digits, ($v >> 6) & 0x3f, 1) .
			substr($base64_digits, ($v >> 12) & 0x3f, 1) .
			substr($base64_digits, ($v >> 18) & 0x3f, 1);
	}
	substr $digits, -$npadbytes, $npadbytes, '';
	return $digits;
}

sub decode_crypt64 {
	my $digits = shift;
	my $ndigits = length($digits);
	my $npadbytes = 3 - ($ndigits + 3) % 4;
	$digits .= '.' x $npadbytes;
	my $bytes = '';
	for(my $i = 0; $i < $ndigits; $i += 4) {
		my $v = index($base64_digits, substr $digits, $i, 1) |
			(index($base64_digits, substr $digits, $i + 1, 1) << 6) |
			(index($base64_digits, substr $digits, $i + 2, 1) << 12) |
			(index($base64_digits, substr $digits, $i + 3, 1) << 18);
		$bytes .= chr($v & 0xff) . chr(($v >> 8) & 0xff) . chr(($v >> 16) & 0xff);
	}
	substr $bytes, -$npadbytes, $npadbytes, '';
	return $bytes;
}

sub encode_crypt64_number {
	my ($input, $length) = @_;
	my $output = '';
	for (1 .. $length) {
		my $remainder = $input % 64;
		$output .= substr $base64_digits, $remainder, 1;
		$input = int($input / 64);
	}
	croak "Number doesn't fit in $length characters" if $input != 0;
	return $output;
}

sub decode_crypt64_number {
	my $input = shift;
	my $result = 0;
	for (0 .. length($input) - 1) {
		$result += index($base64_digits, substr $input, $_, 1) * (1 << (6 * $_));
	}
	return $result;
}

1;

# ABSTRACT: An implementation of the crypt64 encoding

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Util::Crypt64 - An implementation of the crypt64 encoding

=head1 VERSION

version 0.022

=head1 SYNOPSIS

 use Crypt::Passphrase::Crypt64 ':all';

 my $encoded = encode_crypt64('abcd');
 my $decoded = decode_crypt64($encoded);

=head1 DESCRIPTION

This module provides functions to encode and decode strings into and from the crypt64 encoding. This is similar to base64, but incompatible because it uses a slightl different alphabet and because it's little-endian. This encoding is traditionally used to C<crypt> style encrypt password hashes.

=head1 FUNCTIONS

=head2 encode_crypt64

This takes a bytestring and encodes it in crypt64.

=head2 decode_crypt64

This takes a crypt64 encoded string and decodes it to a bytestring.

=head2 endcode_crypt64_number

This takes a number to encode, and optionally a desired length.

=head2 decode_crypt64_number

This takes a crypt64 encoded number, and decodes it to a number.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
