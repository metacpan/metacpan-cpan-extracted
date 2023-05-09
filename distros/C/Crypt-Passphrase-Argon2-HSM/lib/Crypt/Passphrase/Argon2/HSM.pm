package Crypt::Passphrase::Argon2::HSM;

use strict;
use warnings;

our $VERSION = '0.003';

use parent 'Crypt::Passphrase::Argon2::Encrypted';
use Crypt::Passphrase 0.010 -encoder;

use Carp 'croak';
use Crypt::HSM 0.010;

sub new {
	my ($class, %args) = @_;

	$args{cipher} //= 'aes-cbc';
	my $prefix = $args{prefix} // 'pepper-';

	my $session = $args{session} // do {
		my $provider = ref $args{provider} ? $args{provider} : Crypt::HSM->load(delete $args{provider});
		my $slot = delete $args{slot} // ($provider->slots)[0];
		$provider->open_session($slot);
	};
	my $user_type = delete $args{user_type} // 'user';
	$session->login($user_type, delete $args{pin}) if $args{pin};

	my $self = $class->SUPER::new(%args);
	$self->{session} = $session;
	$self->{prefix} = $prefix;
	return $self;
}

sub encrypt_hash {
	my ($self, $algorithm, $id, $iv, $raw) = @_;

	croak 'No active pepper given' if not defined $id;
	my $label = "$self->{prefix}$id";
	my ($key) = $self->{session}->find_objects({ label => $label, encrypt => 1 });
	croak "No such key $label" if not defined $key;

	return $self->{session}->encrypt($algorithm, $key, $raw, $iv);
}

sub decrypt_hash {
	my ($self, $algorithm, $id, $iv, $raw) = @_;

	croak 'No active pepper given' if not defined $id;
	my $label = "$self->{prefix}$id";
	my ($key) = $self->{session}->find_objects({ label => $label, decrypt => 1 });
	croak "No such key $label" if not defined $key;

	return $self->{session}->decrypt($algorithm, $key, $raw, $iv);
}

sub supported_ciphers {
	my $self = shift;
	return map { $_->name } grep { $_->has_flags('encrypt', 'decrypt') } $self->{session}->slot->mechanisms;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Passphrase::Argon2::HSM - HSM encrypted Argon2 hashes for Crypt::Passphrase

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder => {
         module   => 'Argon2::HSM',
         provider => '/usr/lib/pkcs11/some-pkcs11.so',
         active   => '3',
     },
 );

=head1 DESCRIPTION

This class implements peppering by encrypting the hash using HSM. Note that it does not do the argon2 computation in the HSM.

=head1 METHODS

=head2 new

This constructor takes all arguments also taken by L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2>, with the following additions:

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

=item * cipher

This is the cipher that's used for peppering. This can be any mechanism supporting encrypt/decrypt. The default is C<'aes-cbc'>.

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


