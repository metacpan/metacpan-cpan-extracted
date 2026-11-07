package Crypt::SysRandom;
$Crypt::SysRandom::VERSION = '0.008';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/random_bytes random_hex random_base64 random_base64url random_uuid/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp ();
use Errno ();
use MIME::Base64 3.11 ();

my $rtl_gen_random = 'INT SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength)';

if (eval { require Crypt::SysRandom::XS }) {
	*random_bytes = \&Crypt::SysRandom::XS::random_bytes;
} elsif (my $genrand = eval { require Win32::API; Win32::API->new('advapi32', $rtl_gen_random) }) {
	sub random_bytes_win32 {
		my ($count) = @_;
		return '' if $count == 0;
		my $buffer = chr(0) x $count;
		$genrand->Call($buffer, $count) or Carp::croak("Could not read random bytes");
		return $buffer;
	}
	*random_bytes = \&random_bytes_win32;
} elsif (open my $fh, '<:raw', '/dev/urandom') {
	sub random_bytes_urandom {
		my ($count) = @_;
		my ($result, $offset) = ('', 0);
		while ($offset < $count) {
			my $read = sysread $fh, $result, $count - $offset, $offset;
			next if not defined $read and $!{EINTR};
			Carp::croak("Could not read random bytes") if not defined $read or $read == 0;
			$offset += $read;
		}
		return $result;
	}
	*random_bytes = \&random_bytes_urandom;
} else {
	die "No source of randomness found, consider installing Crypt::SysRandom::XS";
}

delete @Crypt::SysRandom::{qw(random_bytes_win32 random_bytes_urandom)};

sub random_hex {
	return unpack 'H*', random_bytes(@_);
}

sub random_base64 {
	return MIME::Base64::encode_base64(random_bytes(@_), '');
}

sub random_base64url {
	return MIME::Base64::encode_base64url(random_bytes(@_));
}

sub random_uuid {
	my $random = random_bytes(16);
	vec($random, 35, 2) = 2; # Variant marker, must be 2 per RFC 9562
	vec($random, 13, 4) = 4; # Version marker, we're doing UUIDv4
	return join '-', unpack 'H8H4H4H4H12', $random;
}

1;

# ABSTRACT: Perl interface to system randomness

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SysRandom - Perl interface to system randomness

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 use Crypt::SysRandom 'random_bytes';
 my $random = random_bytes(16);

=head1 DESCRIPTION

This module uses whatever interface is available to procure cryptographically random data from the system. All functions are optionally exported.

=head1 FUNCTIONS

=head2 random_bytes($count)

This will fetch a string of C<$count> random bytes containing cryptographically secure random data.

=head2 random_hex($count)

This will fetch a string of C<$count> random bytes containing cryptographically secure random data and hex encode it (so the result will be twice as many bytes).

=head2 random_base64($count)

This will fetch a string of C<$count> random bytes containing cryptographically secure random data and base64 encode it (so the result will be about 33% larger).

=head2 random_base64url($count)

This will fetch a string of C<$count> random bytes containing cryptographically secure random data and base64url encode it (so the result will be about 33% larger).

=head2 random_uuid()

This will generate a cryptographically random UUIDv4.

=head1 Backends

The current backends are tried in order:

=over 4

=item * L<Crypt::SysRandom::XS|Crypt::SysRandom::XS>

=item * C<RtlGenRandom> using L<Win32::API|Win32::API>

=item * C</dev/urandom>

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
