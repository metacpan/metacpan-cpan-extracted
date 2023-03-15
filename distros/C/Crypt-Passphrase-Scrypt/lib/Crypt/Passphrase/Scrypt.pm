package Crypt::Passphrase::Scrypt;
$Crypt::Passphrase::Scrypt::VERSION = '0.003';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';

use Carp 'croak';
use Crypt::ScryptKDF qw/scrypt_b64 scrypt_raw/;
use MIME::Base64 qw/encode_base64 decode_base64/;

sub new {
	my ($class, %args) = @_;
	return bless {
		cost        => $args{cost}        || 16,
		block_size  => $args{block_size}  ||  8,
		parallel    => $args{parallel}    ||  1,
		salt_size   => $args{salt_size}   || 16,
		output_size => $args{output_size} || 16,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	my $hash = scrypt_b64($password, $salt, 1 << $self->{cost}, $self->{block_size}, $self->{parallel}, $self->{output_size});
	return sprintf '$scrypt$ln=%d,r=%d,p=%d$%s$%s', $self->{cost}, $self->{block_size}, $self->{parallel}, encode_base64($salt), $hash;
}

my $decode_regex = qr/ \A \$ scrypt \$ ln=(\d+),r=(\d+),p=(\d+) \$ ([^\$]+) \$ ([^\$]*) \z /x;

sub needs_rehash {
	my ($self, $hash) = @_;
	my ($cost, $block_size, $parallel, $salt64, $hash64) = $hash =~ $decode_regex or return 1;
	return 1 if $cost < $self->{cost} or $block_size < $self->{block_size} or $parallel < $self->{parallel};
	return 1 if length decode_base64($salt64) < $self->{salt_size} or length decode_base64($hash64) < $self->{output_size};
	return 0;
}

sub crypt_subtypes {
	return 'scrypt';
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	my ($cost, $block_size, $parallel, $salt64, $hash64) = $hash =~ $decode_regex or return 0;
	my $old_hash = decode_base64($hash64);
	my $new_hash = scrypt_raw($password, decode_base64($salt64), 1 << $cost, $block_size, $parallel, length $old_hash);
	return $class->secure_compare($new_hash, $old_hash);
}

1;

#ABSTRACT: A scrypt encoder for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Scrypt - A scrypt encoder for Crypt::Passphrase

=head1 VERSION

version 0.003

=head1 DESCRIPTION

This class implements an scrypt encoder for Crypt::Passphrase. If one wants a memory-hard password scheme Argon2 is recommended instead.

=head1 METHODS

=head2 new(%args)

This creates a new scrypt encoder, it takes named parameters that are all optional. Note that some defaults are likely to change at some point in the future, as computers get progressively more powerful and cryptoanalysis gets more advanced.

=over 4

=item * cost

This is the cost factor that is used to hash passwords, it scales exponentially. It currently defaults to C<16>, but this may change in any future version.

=item * block_size

This defaults to 8, you probably have no need for changing this.

=item * parallelism

The number of threads used for the hash. This defaults to C<1>, but this number may change in any future version.

=item * output_size

The size of a hashed value. This defaults to 16 bytes, increasing it only makes sense if your passwords actually contain more than 128 bits of entropy.

=item * salt_size

The size of the salt. This defaults to 16 bytes, which should be more than enough for any use-case.

=back

=head2 hash_password($password)

This hashes the passwords with scrypt according to the specified settings and a random salt (and will thus return a different result each time).

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher, or if any of the cost is lower that desired by the encoder.

=head2 crypt_types()

This class supports the following crypt type: C<scrypt>

=head2 verify_password($password, $hash)

This will check if a password matches a scrypt hash.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
