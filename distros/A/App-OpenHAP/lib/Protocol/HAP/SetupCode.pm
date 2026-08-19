# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2025 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Protocol::HAP::SetupCode;
our $VERSION = '0.1.0';
use Exporter qw(import);
our @EXPORT_OK = qw(normalize_setup_code validate_setup_code);

# Protocol::HAP::SetupCode - the rules of the 8-digit setup code.
#
# The specification says "setup code" [HAP-Pairing §2]. The word PIN is
# the one it replaced, so no name here uses it.

# Invalid setup codes per HAP specification
# These are sequential or trivial patterns. Do not use them.
use constant INVALID_SETUP_CODES => qw(
    00000000 11111111 22222222 33333333 44444444
    55555555 66666666 77777777 88888888 99999999
    12345678 87654321
);

# normalize_setup_code($code):
#	Remove dashes and spaces from the setup code for internal use
#	Returns: an 8-digit numeric string, or undef if the format
#	is invalid
sub normalize_setup_code ($code)
{
	return unless defined $code;

	# Remove the dashes and spaces
	$code =~ s/[-\s]//g;

	# Make sure the setup code is exactly 8 digits
	return unless $code =~ /^\d{8}$/;

	return $code;
}

# validate_setup_code($code):
#	Validate that the setup code meets the HAP requirements
#	Returns: 1 if the setup code is valid, undef if it is invalid
sub validate_setup_code ($code)
{
	# Normalize the setup code first
	my $normalized = normalize_setup_code($code);
	return unless defined $normalized;

	# Check the setup code against the list of invalid codes
	my %invalid = map { $_ => 1 } INVALID_SETUP_CODES;
	return if exists $invalid{$normalized};

	return 1;
}

1;
