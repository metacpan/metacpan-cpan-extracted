package Crypt::Passphrase::Bcrypt::Encrypted;
$Crypt::Passphrase::Bcrypt::Encrypted::VERSION = '0.009';
use 5.014;
use warnings;

use Crypt::Passphrase 0.019 -encoder;
use Crypt::Passphrase::Bcrypt;

use Carp 'croak';
use Crypt::Bcrypt 0.011 qw/bcrypt_prehashed bcrypt_check_prehashed bcrypt_supported_prehashes/;
use MIME::Base64 qw/encode_base64 decode_base64/;

sub new {
	my ($class, %args) = @_;
	$args{hash} //= 'sha384';
	my $self = Crypt::Passphrase::Bcrypt->new(%args);
	$self->{cipher} = $args{cipher};
	$self->{active} = $args{active};
	return bless $self, $class;
}

my $format = '$bcrypt-%s-encrypted-%s$t=%s,r=%d,keyid=%s$%s$%s';

sub _pack_hash {
	my ($hash_alg, $cipher, $subtype, $id, $cost, $salt, $hash) = @_;
	my $encoded_salt = encode_base64($salt, '') =~ tr/=//dr;
	my $encoded_hash = encode_base64($hash, '') =~ tr/=//dr;
	return sprintf $format, $hash_alg, $cipher, $subtype, $cost, $id, $encoded_salt, $encoded_hash;
}

my $regex = qr/ ^ \$ bcrypt-(sha\d{3})-encrypted-([^\$]+) \$ t=(\w+), r=(\d+), keyid=([^\$,]+)  \$ ([^\$]+) \$ (.*) $ /x;

sub _unpack_hash {
	my $pwhash = shift;
	my ($hash_type, $alg, $subtype, $cost, $id, $encoded_salt, $encoded_hash) = $pwhash =~ $regex or return;
	my $salt = decode_base64($encoded_salt);
	my $hash = decode_base64($encoded_hash);
	return ($hash_type, $alg, $subtype, $id, $cost, $salt, $hash);
}

my $unencrypted_format = '$bcrypt-%s$v=2,t=%s,r=%d$%s$%s';

sub _pack_raw {
	my ($hash_type, $subtype, $cost, $salt, $hash) = @_;
	my $encoded_salt = encode_base64($salt, '') =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}dr;
	my $encoded_hash = encode_base64($hash, '') =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}dr;
	return sprintf $unencrypted_format, $hash_type, $subtype, $cost, $encoded_salt, $encoded_hash;
}

my $unencrypted_regex = qr/ ^ \$ bcrypt-(sha\d{3}) \$ v=2, t=(\w+), r=(\d+)\$ ([^\$]+) \$ (.*) $ /x;

sub _unpack_raw {
	my $input = shift;
	my ($hash_type, $subtype, $cost, $encoded_salt, $encoded_hash) = $input =~ $unencrypted_regex or return;
	my $salt = decode_base64($encoded_salt =~ tr{./A-Za-z0-9}{A-Za-z0-9+/}r);
	my $hash = decode_base64($encoded_hash =~ tr{./A-Za-z0-9}{A-Za-z0-9+/}r);
	return ($hash_type, $subtype, $cost, $salt, $hash);
}

sub recode_hash {
	my ($self, $input, $to) = @_;
	$to //= $self->{active};
	if (my ($hash_type, $alg, $subtype, $id, $cost, $salt, $hash) = _unpack_hash($input)) {
		return $input if $id eq $to and $alg eq $self->{cipher};
		return eval {
			my $decrypted = $self->decrypt_hash($alg, $id, $salt, $hash);
			my $encrypted = $self->encrypt_hash($self->{cipher}, $to, $salt, $decrypted);
			_pack_hash($hash_type, $self->{cipher}, $subtype, $to, $cost, $salt, $encrypted);
		} // $input;
	}
	elsif (($hash_type, $subtype, $cost, $salt, $hash) = _unpack_raw) {
		my $encrypted = $self->encrypt_hash($self->{cipher}, $to, $salt, $hash);
		return _pack_hash($hash_type, $self->{cipher}, $subtype, $to, $cost, $salt, $encrypted);
	}
	else {
		return $input;
	}
}

sub hash_password {
	my ($self, $password) = @_;

	my $salt = $self->random_bytes(16);
	my $raw = bcrypt_prehashed($password, $self->{subtype}, $self->{cost}, $salt, $self->{hash});
	my ($hash_type, $subtype, $cost, $salt2, $hash) = _unpack_raw($raw);

	my $encrypted = $self->encrypt_hash($self->{cipher}, $self->{active}, $salt, $hash);

	return _pack_hash(@{$self}{qw/hash cipher subtype active cost/}, $salt2, $encrypted);
}

sub needs_rehash {
	my ($self, $pwhash) = @_;
	my ($hash_type, $alg, $subtype, $id, $cost, $salt, $encrypted_hash) = _unpack_hash($pwhash) or return 1;
	return $pwhash ne _pack_hash(@{$self}{qw/hash cipher subtype active cost/}, $salt, $encrypted_hash);
}

sub crypt_subtypes {
	my $self = shift;
	my @result;
	my @supported = $self->supported_ciphers;
	for my $hash_alg (bcrypt_supported_prehashes) {
		push @result, "bcrypt-$hash_alg", map { "bcrypt-$hash_alg-encrypted-$_" } @supported
	}
	return @result;
}

sub verify_password {
	my ($self, $password, $pwhash) = @_;
	if (my ($hash_type, $alg, $subtype, $id, $cost, $salt, $encrypted_hash) = _unpack_hash($pwhash)) {
		my $hash = eval { $self->decrypt_hash($alg, $id, $salt, $encrypted_hash) } or return !!0;
		my $primary = _pack_raw($hash_type, $subtype, $cost, $salt, $hash);
		return bcrypt_check_prehashed($password, $primary);
	}
	elsif ($pwhash =~ $unencrypted_regex) {
		return bcrypt_check_prehashed($password, $pwhash);
	}
	else {
		return !!0;
	}
}

1;

#ABSTRACT: A base-class for encrypting/peppered Argon2 encoders for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Bcrypt::Encrypted - A base-class for encrypting/peppered Argon2 encoders for Crypt::Passphrase

=head1 VERSION

version 0.009

=head1 DESCRIPTION

This is a base-class for Bcrypt with port-peppering. You probably want to use L<Crypt::Passphrase::Bcrypt::AES|Crypt::Passphrase::Bcrypt::AES> instead.

=head2 Configuration

This takes all arguments also taken by L<Crypt::Passphrase::Bcrypt|Crypt::Passphrase::Bcrypt>, with the following additions: C<cipher> (the name of the used cipher) and C<active> (the identifier of the active pepper).

=head2 SUPPORTED CRYPT TYPES

This class supports at all types supported by L<Crypt::Bcrypt>, with and without a C<'-encrypted'> postfix.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
