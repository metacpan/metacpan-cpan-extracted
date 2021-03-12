package Crypt::Passphrase;
$Crypt::Passphrase::VERSION = '0.003';
use strict;
use warnings;

use Carp 'croak';
use Scalar::Util 'blessed';
use Encode 'encode';
use Unicode::Normalize 'NFC';

sub _load_extension {
	my $name = shift;
	$name =~ s/^(?!\+)/Crypt::Passphrase::/;
	$name =~ s/^\+//;
	(my $filename = "$name.pm") =~ s{::}{/}g;
	require $filename;
	return $name;
}

sub _load_encoder {
	my $encoder = shift;
	if (blessed $encoder) {
		return $encoder;
	}
	elsif (ref $encoder) {
		my %encoder_conf = %{ $encoder };
		my $encoder_module = _load_extension(delete $encoder_conf{module});
		return $encoder_module->new(%encoder_conf);
	}
	elsif ($encoder) {
		my $encoder_module = _load_extension($encoder);
		return $encoder_module->new;
	}
	else {
		croak 'No encoder given to Crypt::Passphrase->new';
	}
}

sub _load_validator {
	my $validator = shift;
	if (blessed $validator) {
		return $validator;
	}
	elsif (ref($validator) eq 'HASH') {
		my %validator_conf = %{ $validator };
		my $validator_module = _load_extension(delete $validator_conf{module});
		return $validator_module->new(%validator_conf);
	}
	elsif (ref($validator) eq 'CODE') {
		require Crypt::Passphrase::Fallback;
		return Crypt::Passphrase::Fallback->new(callback => $validator);
	}
	else {
		return _load_extension($validator);
	}
}

sub new {
	my ($class, %args) = @_;
	my $encoder = _load_encoder($args{encoder});
	my @validators = map { _load_validator($_) } @{ $args{validators} };

	my $self = bless {
		encoder  => $encoder,
		validators => [ $encoder, @validators ],
	}, $class;

	return $self;
}

sub _normalize_password {
	my $password = shift;
	return encode('utf-8-strict', NFC($password));
}

sub hash_password {
	my ($self, $password) = @_;
	return $self->{encoder}->hash_password(_normalize_password($password));
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return 1 if $hash !~ / \A \$ (\w+) \$ /x;
	return $self->{encoder}->needs_rehash($hash);
}

sub verify_password {
	my ($self, $password, $hash) = @_;

	for my $validator (@{ $self->{validators} }) {
		if ($validator->accepts_hash($hash)) {
			return $validator->verify_password(_normalize_password($password), $hash);
		}
	}

	return;
}

1;

# ABSTRACT: A module for managing passwords in a cryptographically agile manner

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase - A module for managing passwords in a cryptographically agile manner

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $authenticator = Crypt::Passphrase->new(
     encoder    => 'Argon2',
     validators => [ 'Bcrypt' ],
 );

 my $hash = get_hash($user);
 if (!$authenticator->verify_password($password, $hash)) {
     die "Invalid password";
 }
 elsif ($authenticator->needs_rehash($hash)) {
     update_hash($user, $authenticator->hash_password($password));
 }

=head1 DESCRIPTION

This module manages the passwords in a cryptographically agile manner. Following Postel's principle, it allows you to define a single scheme that will be used for new passwords, but several schemes to check passwords with. It will be able to tell you if you should rehash your password, not only because the scheme is outdated, but also because the desired parameters have changed.

=head1 METHODS

=head2 new(%args)

This creates a new C<Crypt::Passphrase> object. It takes two named arguments:

=over 4

=item * encoder

A C<Crypt::Passphrase> object has a single encoder. This can be passed in three different ways:

=over 4

=item * A simple string

The name of the encoder class. If the value starts with a C<+>, the C<+> will be removed and the remainder will be taken as a fully-qualified package name. Otherwise, C<Crypt::Passphrase::> will be prepended to he value.

The class will be loaded, and constructed without arguments.

=item * A hash

The C<module> entry will be used to load a new Crypt::Passphrase module as described above, the other arguments will be passed to the constructor. This is the recommended option, as it gives you full control over the password parameters.

=item * A Crypt::Passphrase::Encoder object

This will be used as-is.

=back

This argument is mandatory.

=item * validators

This is a list of additional validators for passwords. These values can each either be the same an encoder value, except that the last entry may also be a coderef that takes the password and the hash as its arguments and returns a boolean value.

The encoder is always considered as a validator and thus doesn't need to be explicitly specified.

=back

=head2 hash_password($password)

This will hash a password with the encoder cipher, and return it (in crypt format). This will generally use a salt, and as such will return a different value each time even when called with the same password.

=head2 verify_password($password, $hash)

This will check a password satisfies a certain hash.

=head2 needs_rehash($hash)

This will check if a hash needs to be rehashed, either because it's in the wrong cipher or because the parameters are insufficient.

Calling this only ever makes sense after a password has been verified.

=head1 TIPS AND TRICKS

=head2 Custom configurations

While encoders generally allow for a default configuration, I would strongly encourage anyone to research what settings work for your application. It is generally a trade-off between usability/resources and security.

=head2 Unicode

C<Crypt::Password> considers passwords to be text, and as such you should ensure any password input is decoded if it contains any non-ascii characters. C<Crypt::Password> will take care of both normalizing and encoding such input.

=head2 DOS attacks

Hashing passwords is by its nature a heavy operations. It can be abused by malignant actors who want to try to DOS your application. It may be wise to do some form of DOS protection such as a proof-of-work schemei or a captcha.

=head2 Levels of security

In some situations, it may be appropriate to have different password settings for different users (e.g. set them more strict for administrators than for ordinary users).

=head1 SEE ALSO

=over 4

=item * L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2>

=item * L<Crypt::Passphrase::Bcrypt|Crypt::Passphrase::Bcrypt>

=item * L<Crypt::Passphrase::Scrypt|Crypt::Passphrase::Scrypt>

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
