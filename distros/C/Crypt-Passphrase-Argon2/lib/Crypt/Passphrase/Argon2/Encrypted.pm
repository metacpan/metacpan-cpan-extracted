package Crypt::Passphrase::Argon2::Encrypted;
$Crypt::Passphrase::Argon2::Encrypted::VERSION = '0.010';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Encoder';
use Crypt::Passphrase::Argon2;

use Carp 'croak';
use Crypt::Argon2 0.017 qw/argon2_raw argon2_verify argon2_types/;
use MIME::Base64 qw/encode_base64 decode_base64/;

my %multiplier = (
	k => 1024,
	M => 1024 * 1024,
	G => 1024 * 1024 * 1024,
);

sub new {
	my ($class, %args) = @_;
	my $self = bless Crypt::Passphrase::Argon2::_settings_for(%args), $class;
	$self->{memory_cost} =~ s/ \A (\d+) ([kMG]) \z / $1 * $multiplier{$2} /xe;
	$self->{cipher} = $args{cipher};
	$self->{active} = $args{active};
	return $self;
}

my $format = '$%s-encrypted-%s$v=19$m=%d,t=%d,p=%d,keyid=%s$%s$%s';

sub _pack_hash {
	my ($subtype, $cipher, $id, $m_cost, $t_cost, $parallel, $salt, $hash) = @_;
	my $encoded_salt = encode_base64($salt, '') =~ tr/=//dr;
	my $encoded_hash = encode_base64($hash, '') =~ tr/=//dr;
	return sprintf $format, $subtype, $cipher, $m_cost / 1024, $t_cost, $parallel, $id, $encoded_salt, $encoded_hash;
}

my $regex = qr/ ^ \$ ($Crypt::Argon2::type_regex)-encrypted-([^\$]+) \$ v=19 \$ m=(\d+), t=(\d+), p=(\d+), keyid=([^\$,]+)  \$ ([^\$]+) \$ (.*) $ /x;

sub _unpack_hash {
	my ($pwhash) = @_;
	my ($subtype, $alg, $m_cost, $t_cost, $parallel, $id, $encoded_salt, $encoded_hash) = $pwhash =~ $regex or return;
	my $salt = decode_base64($encoded_salt);
	my $hash = decode_base64($encoded_hash);
	return ($subtype, $alg, $id, $m_cost * 1024, $t_cost, $parallel, $salt, $hash);
}

my $unencrypted_regex = qr/ ^ \$ ($Crypt::Argon2::type_regex) \$ v=19 \$ m=(\d+), t=(\d+), p=(\d+) \$ ([^\$]+) \$ (.*) $ /x;
sub recode_hash {
	my ($self, $input) = @_;
	local $SIG{__DIE__} = \&Carp::croak;
	if (my ($subtype, $alg, $id, $m_cost, $t_cost, $parallel, $salt, $hash) = _unpack_hash($input)) {
		return $input if $id eq $self->{active} and $alg eq $self->{cipher};
		my $decrypted = eval { $self->decrypt_hash($alg, $id, $salt, $hash) } or return $input;
		my $encrypted = $self->encrypt_hash($self->{cipher}, $self->{active}, $salt, $decrypted);
		return _pack_hash($subtype, $self->{cipher}, $self->{active}, $m_cost, $t_cost, $parallel, $salt, $encrypted);
	}
	elsif (($subtype, $m_cost, $t_cost, $parallel, my $encoded_salt, my $encoded_hash) = $input =~ $unencrypted_regex) {
		my $salt = decode_base64($encoded_salt);
		my $hash = decode_base64($encoded_hash);
		my $encrypted = $self->encrypt_hash($self->{cipher}, $self->{active}, $salt, $hash);
		return _pack_hash($subtype, $self->{cipher}, $self->{active}, $m_cost * 1024, $t_cost, $parallel, $salt, $encrypted);
	}
	else {
		return $input;
	}
}

sub hash_password {
	my ($self, $password) = @_;

	my $salt = $self->random_bytes($self->{salt_size});
	local $SIG{__DIE__} = \&Carp::croak;
	my $raw = argon2_raw($self->{subtype}, $password, $salt, @{$self}{qw/time_cost memory_cost parallelism output_size/});
	my $encrypted = $self->encrypt_hash($self->{cipher}, $self->{active}, $salt, $raw);

	return _pack_hash(@{$self}{qw/subtype cipher active memory_cost time_cost parallelism/}, $salt, $encrypted);
}

sub needs_rehash {
	my ($self, $pwhash) = @_;
	my ($subtype, $alg, $id, $m_cost, $t_cost, $parallel, $salt, $hash) = _unpack_hash($pwhash) or return 1;
	return 1 if $pwhash ne _pack_hash(@{$self}{qw/subtype cipher active memory_cost time_cost parallelism/}, $salt, $hash);
	return length $salt != $self->{salt_size} || length $hash != $self->{output_size};
}

sub crypt_subtypes {
	my $self = shift;
	my @result;
	my @supported = $self->supported_ciphers;
	for my $argon2 (argon2_types) {
		push @result, $argon2, map { "$argon2-encrypted-$_" } @supported
	}
	return @result;
}

sub verify_password {
	my ($self, $password, $pwhash) = @_;
	if (my ($subtype, $alg, $id, $m_got, $t_got, $parallel_got, $salt, $hash) = _unpack_hash($pwhash)) {
		my $raw = eval { argon2_raw($subtype, $password, $salt, $t_got, $m_got, $parallel_got, length $hash) } or return !!0;
		my $decrypted = eval { $self->decrypt_hash($alg, $id, $salt, $hash) } or return !!0;

		return $self->secure_compare($decrypted, $raw);
	}
	elsif ($pwhash =~ $unencrypted_regex) {
		return argon2_verify($pwhash, $password);
	}
}

#ABSTRACT: A base-class for encrypting/peppered Argon2 encoders for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Argon2::Encrypted - A base-class for encrypting/peppered Argon2 encoders for Crypt::Passphrase

=head1 VERSION

version 0.010

=head1 DESCRIPTION

This is a base-class for pre-peppering implementations. You probably want to use Crypt::Passphrase::Argon2::AES instead.

=head1 METHODS

=head2 new()

This constructor takes all arguments also taken by L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2>, with the following additions: C<cipher> (the name of the used cipher) and C<active> (the identifier of the active pepper).

=head2 hash_password($password)

This hashes the passwords with argon2 according to the specified settings and a random salt (and will thus return a different result each time).

=head2 verify_password($password, $hash)

This will check if a password matches an encrypted or unencrypted argon2 hash.

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, or if any of the parameters is lower that desired by the encoder.

=head2 recode_hash($input)

This recrypts the hash in C<$input> to the active key, if it's not already.

=head2 crypt_subtypes()

This class supports at all types supported by L<Crypt::Argon2>, with and without a C<'-encrypted'> postfix.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
