package Crypt::Passphrase::PBKDF2;
$Crypt::Passphrase::PBKDF2::VERSION = '0.004';
use strict;
use warnings;

use Crypt::Passphrase 0.010 -encoder;

use Carp 'croak';
use PBKDF2::Tiny qw/derive verify/;
use MIME::Base64 qw/encode_base64 decode_base64/;

my %param_for_type =(
	sha1   => 'SHA-1',
	sha224 => 'SHA-224',
	sha256 => 'SHA-256',
	sha384 => 'SHA-384',
	sha512 => 'SHA-512',
);

sub new {
	my ($class, %args) = @_;
	my $type = $args{type} || 'sha256';
	croak "Hash type $type not supported" unless exists $param_for_type{$type};
	return bless {
		salt_size  => $args{salt_size} || 16,
		iterations => $args{iterations} || 100_000,
		type       => $type,
	}, $class;
}

sub ab64_encode {
	my $input = shift;
	return encode_base64($input, '') =~ tr/+=/./dr;
}

sub ab64_decode {
	my $input = shift;
	return decode_base64($input =~ tr/./+/r);
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	my $hash = derive($param_for_type{ $self->{type} }, $password, $salt, $self->{iterations});
	return join '$', "\$pbkdf2-$self->{type}", $self->{iterations}, ab64_encode($salt), ab64_encode($hash);
}

my $decode_regex = qr/ \A \$ pbkdf2- (\w+) \$ (\d+) \$ ([^\$]+) \$ ([^\$]*) \z /x;

sub needs_rehash {
	my ($self, $hash) = @_;
	my ($type, $iterations, $salt64, $hash64) = $hash =~ $decode_regex or return 1;
	return 1 if $type ne $self->{type} or $iterations != $self->{iterations};
	return 1 if length ab64_decode($salt64) != $self->{salt_size};
	return;
}

sub crypt_subtypes {
	return map { "pbkdf2-$_" } keys %param_for_type;
}

sub verify_password {
	my ($class, $password, $hash) = @_;

	my ($type, $iterations, $salt64, $hash64) = $hash =~ $decode_regex or return 0;
	return 0 unless exists $param_for_type{$type};
	return verify(ab64_decode($hash64), $param_for_type{$type}, $password, ab64_decode($salt64), $iterations);
}

1;

# ABSTRACT: A PBKDF2 encoder for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::PBKDF2 - A PBKDF2 encoder for Crypt::Passphrase

=head1 VERSION

version 0.004

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
   encoder => {
     module     => 'PBKDF2',
     type       => 'sha256',
     iterations => 128_000,
   },
 );

=head1 DESCRIPTION

This class implements a PBKDF2 encoder for Crypt::Passphrase. It allows for any SHA-1 or SHA-2 hash, and any number of iterations.

=head2 Configuration

It accepts the following arguments:

=over 4

=item * type

This can be any of C<sha1>, C<sha224>, C<sha256> (default), C<sha384> or C<sha512>.

=item * iterations

This will be the iteration count, defaulting to C<100000>.

=item * salt_size

The size of the salt. This defaults to 16 bytes, which should be more than enough for any use-case.

=back

=head2 COMPATIBILITY

This module aims to be compatible with L<passlib|https://passlib.readthedocs.io/en/stable/lib/passlib.hash.pbkdf2_digest.html> when used with C<sha1>, C<sha256>, or C<sha512>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
