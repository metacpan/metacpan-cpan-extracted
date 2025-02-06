package Crypt::SysRandom;
$Crypt::SysRandom::VERSION = '0.007';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = 'random_bytes';

use Carp ();
use Errno ();

if (eval { require Crypt::SysRandom::XS }) {
	*random_bytes = \&Crypt::SysRandom::XS::random_bytes;
} elsif (eval { require Win32::API }) {
	my $genrand = Win32::API->new('advapi32', 'INT SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength)')
		or die "Could not import SystemFunction036: $^E";
	sub random_bytes_win32 {
		my ($count) = @_;
		return '' if $count == 0;
		my $buffer = chr(0) x $count;
		$genrand->Call($buffer, $count) or Carp::croak("Could not read random bytes");
		return $buffer;
	}
	*random_bytes = \&random_bytes_win32;
} elsif (-e '/dev/urandom') {
	open my $fh, '<:raw', '/dev/urandom' or die "Couldn't open /dev/urandom: $!";
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
	die "No source of randomness found";
}

delete @Crypt::SysRandom::{qw(random_bytes_win32 random_bytes_urandom)};

1;

# ABSTRACT: Perl interface to system randomness

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::SysRandom - Perl interface to system randomness

=head1 VERSION

version 0.007

=head1 SYNOPSIS

 use Crypt::SysRandom 'random_bytes';
 my $random = random_bytes(16);

=head1 DESCRIPTION

This module uses whatever interface is available to procure cryptographically random data from the system.

=head1 FUNCTIONS

=head2 random_bytes($count)

This will fetch a string of C<$count> random bytes containing cryptographically secure random date.

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
