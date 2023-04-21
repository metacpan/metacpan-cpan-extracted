package Crypt::Passphrase::HSM;

use strict;
use warnings;

our $VERSION = '0.003';

use Crypt::Passphrase -encoder;

use Carp 'croak';
use Crypt::HSM;
use MIME::Base64;

sub new {
	my ($class, %args) = @_;

	my $active = delete $args{active} // die 'No active pepper specified';
	my $algorithm = delete $args{algorithm} // 'sha512-hmac';
	my @subtypes = ($algorithm, @{ delete $args{subtypes} || [] });
	my $prefix = delete $args{prefix} // 'pepper-';
	my $salt_size = delete $args{salt_size} // 16;

	my $session = $args{session} // do {
		my $provider = ref $args{provider} ? delete $args{provider} : Crypt::HSM->load(delete $args{provider});
		my $slot = delete $args{slot} // ($provider->slots)[0];
		$provider->open_session($slot);
	};
	my $user_type = delete $args{user_type} // 'user';
	$session->login($user_type, delete $args{pin}) if $args{pin};

	my $label = "$prefix$active";
	my ($key) = $session->find_objects({ label => $label, sign => 1 });
	croak "No such key $label" if not defined $key;

	return bless {
		active    => $active,
		algorithm => $algorithm,
		subtypes  => \@subtypes,
		prefix    => $prefix,
		session   => $session,
		salt_size => $salt_size,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;

	my $label = "$self->{prefix}$self->{active}";
	my ($key) = $self->{session}->find_objects({ label => $label, sign => 1 });
	croak "No such key $label" if not defined $key;

	my $salt = $self->random_bytes($self->{salt_size});
	my $encoded_salt = encode_base64($salt, '') =~ tr/=//dr;
	my $raw = $self->{session}->sign($self->{algorithm}, $key, $password . $salt);
	my $encoded_hash = encode_base64($raw, '') =~ tr/=//dr;
	return "\$$self->{algorithm}\$v=2,id=$self->{active}\$$encoded_salt\$$encoded_hash";
}

sub crypt_subtypes {
	my $self = shift;
	return @{ $self->{subtypes} }
}

my $regex = qr/ \A \$ ([^\$]+) \$ v=2, id=([^\$,]) \$ ([^\$]*) \$ (.*) /x;

sub needs_rehash {
	my ($self, $hash) = @_;
	my ($algorithm, $id) = $hash =~ $regex or return !!1;
	return $algorithm ne $self->{algorithm} || $id ne $self->{active};
}

sub verify_password {
	my ($self, $password, $hash) = @_;
	my ($algorithm, $id, $encoded_salt, $encoded_hmac) = $hash =~ $regex or die "Fail!";
	my $salt = decode_base64($encoded_salt);
	my $hmac = decode_base64($encoded_hmac);

	my $label = "$self->{prefix}$id";
	my ($key) = $self->{session}->find_objects({ label => $label, verify => 1 });
	return !!0 if not defined $key;

	return $self->{session}->verify($algorithm, $key, $password . $salt, $hmac);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Passphrase::HSM - A hasher using hardware for Crypt::Passphrase

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder => {
         module   => 'HSM',
         provider => '/usr/lib/pkcs11/some-pkcs11.so',
         active   => '3',
     },
 );

=head1 DESCRIPTION

This module wraps hashes the password using an hmac. By using identifiers for the peppers, it allows for easy rotation of peppers. Unlike traditional mechanisms it relies fully depends on the secrecy of the peppers in the HSM instead of computational difficulty, as such the key size should probably equal the output size.

=head1 METHODS

=head2 new(%args)

This creates a new encoder. It takes the following named arguments:

=over 4

=item * provider

The path to the PKCS11 provider. This is mandatory.

=item * slot

The slot used on the provider, this defaults to the first listed slot.

=item * active

This is the identifier of the active pepper. This is mandatory.

=item * prefix

The prefix that is used when looking up keys in the HSM. It defaults to C<'pepper-'>.

=item * pin

The PIN that is used for logging in, if any.

=item * user_type

The type of user you're logging in with. This defaults to 'user', and you're unlikely to want to change that.

=item * algorithm

This is the algorithm that's used for hashing. It supports any mechanism on your HSM that can sign and verify, common values are C<'sha1-hmac'>, C<'sha224-hmac'>, C<'sha256-hmac'>, C<'sha384-hmac'>, and C<'sha512-hmac'> (the default).

=back

=head2 hash_password($password)

This hashes the C<$password> in the HSM using the given algorithm.

=head2 verify_password($password, $hash)

Verify a password with the HSM.

=head2 needs_rehash($hash)

This will check if the hash needs a rehash.

=head2 crypt_subtypes

This returns the chosen algorithm.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
