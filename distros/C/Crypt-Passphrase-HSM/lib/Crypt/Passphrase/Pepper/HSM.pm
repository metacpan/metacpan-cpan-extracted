package Crypt::Passphrase::Pepper::HSM;

use strict;
use warnings;

our $VERSION = '0.006';

use parent 'Crypt::Passphrase::Pepper::Base';
use Crypt::Passphrase 0.016 -encoder;

use Carp 'croak';
use Crypt::HSM 0.010;

sub new {
	my ($class, %args) = @_;

	$args{algorithm} //= 'sha512-hmac';
	$args{prefix} //= 'pepper-';

	$args{session} //= do {
		if (ref $args{slot}) {
			(delete $args{slot})->open_session;
		} else {
			my $provider = ref $args{provider} ? delete $args{provider} : Crypt::HSM->load(delete $args{provider});
			my $slot = defined $args{slot} ? $provider->slot(delete $args{slot}) : ($provider->slots)[0];
			$slot->open_session;
		}
	};
	my $user_type = delete $args{user_type} // 'user';
	$args{session}->login($user_type, delete $args{pin}) if $args{pin};
	$args{supported_hashes} //= [ map { $_->name } grep { $_->has_flags('sign') && $_->min_key_size <= 64 } $args{session}->slot->mechanisms ];

	return $class->SUPER::new(%args);
}

sub prehash_password {
	my ($self, $password, $algorithm, $id) = @_;

	croak 'No active pepper given' if not defined $id;
	my $label = "$self->{prefix}$id";
	my ($key) = $self->{session}->find_objects({ class => 'secret-key', label => $label, sign => 1 });
	croak "No such key $label" if not defined $key;

	return $self->{session}->sign($algorithm, $key, $password);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Passphrase::Pepper::HSM - A pepper-wrapper using hardware for Crypt::Passphrase

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder => {
         module   => 'Pepper::HSM',
         provider => '/usr/lib/pkcs11/some-pkcs11.so',
         active   => '3',
         inner    => {
             module      => 'Argon2',
             output_size => 32,
         },
     },
 );

=head1 DESCRIPTION

This module wraps another encoder to pepper the input to the hash. By using identifiers for the peppers, it allows for easy rotation of peppers. Unlike L<Crypt::Passphrase::Pepper::Simple|Crypt::Passphrase::Pepper::Simple> it stores the peppers in a hardware security module (or some other PKCS11 implementation of choice) to ensure their confidentiality.

It will be able to validate both peppered and unpeppered hashes but only create the former.

=head1 METHODS

=head2 new(%args)

This creates a new pepper encoder. It takes the following named arguments:

=over 4

=item * inner

This contains an encoder specification identical to the C<encoder> field of C<Crypt::Passphrase>. It is mandatory.

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

This is the algorithm that's used for peppering. Supported values are C<'sha1-hmac'>, C<'sha224-hmac'>, C<'sha256-hmac'>, C<'sha384-hmac'>, and C<'sha512-hmac'> (the default).

=back

=head2 prehash_password($password, $algorithm, $identifier)

This prehashes the C<$password> using the given C<$algorithm> and C<$identifier>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
