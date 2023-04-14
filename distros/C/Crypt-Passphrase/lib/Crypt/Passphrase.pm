package Crypt::Passphrase;
$Crypt::Passphrase::VERSION = '0.015';
use strict;
use warnings;

use mro ();

use Carp ();
use Scalar::Util ();
use Encode ();
use Unicode::Normalize ();

our @CARP_NOT;
sub import {
	my ($class, @args) = @_;
	for my $arg (@args) {
		my $caller = caller;
		if ($arg eq '-encoder') {
			require Crypt::Passphrase::Encoder;
			no strict 'refs';
			no warnings 'once';
			push @{"$caller\::ISA"}, 'Crypt::Passphrase::Encoder' unless $caller->isa('Crypt::Passphrase::Encoder');
			push @{"$caller\::CARP_NOT"}, __PACKAGE__, mro::get_linear_isa($caller);
		}
		elsif ($arg eq '-validator') {
			require Crypt::Passphrase::Validator;
			no strict 'refs';
			no warnings 'once';
			push @{"$caller\::ISA"}, 'Crypt::Passphrase::Validator' unless $caller->isa('Crypt::Passphrase::Validator');
			push @{"$caller\::CARP_NOT"}, __PACKAGE__, mro::get_linear_isa($caller);
		}
		elsif ($arg eq '-integration') {
			push @CARP_NOT, $caller;
		}
		else {
			Carp::croak("Unknown import argument $arg");
		}
	}
}

sub _load_extension {
	my $short_name = shift;
	my $module_name = $short_name =~ s/^(\+)?/$1 ? '' : 'Crypt::Passphrase::'/re;
	my $file_name = "$module_name.pm" =~ s{::}{/}gr;
	require $file_name;
	return $module_name;
}

sub _load_encoder {
	my $encoder = shift;
	if (Scalar::Util::blessed($encoder)) {
		return $encoder;
	}
	elsif (ref $encoder) {
		my %encoder_conf = %{ $encoder };
		my $encoder_module = _load_extension(delete $encoder_conf{module});
		return $encoder_module->new(%encoder_conf);
	}
	else {
		return _load_extension($encoder)->new;
	}
}

sub _load_validator {
	my $validator = shift;
	if (Scalar::Util::blessed($validator)) {
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
		return _load_extension($validator)->new;
	}
}

my %valid = map { $_ => 1 } qw/C D KC KD/;
sub new {
	my ($class, %args) = @_;
	Carp::croak('No encoder given to Crypt::Passphrase->new') if not $args{encoder};
	my $encoder = _load_encoder($args{encoder});
	my @validators = map { _load_validator($_) } @{ $args{validators} };
	my $normalization = $args{normalization} || 'C';
	Carp::croak("Invalid normalization form $normalization") if not $valid{$normalization};

	my $self = bless {
		encoder       => $encoder,
		validators    => [ $encoder, @validators ],
		normalization => $normalization,
	}, $class;

	return $self;
}

sub _normalize_password {
	my ($self, $password) = @_;
	my $normalized = Unicode::Normalize::normalize($self->{normalization}, $password // '');
	return Encode::encode('utf-8-strict', $normalized);
}

sub hash_password {
	my ($self, $password) = @_;
	my $normalized = $self->_normalize_password($password);
	return $self->{encoder}->hash_password($normalized);
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return $self->{encoder}->needs_rehash($hash);
}

sub verify_password {
	my ($self, $password, $hash) = @_;

	for my $validator (@{ $self->{validators} }) {
		if ($validator->accepts_hash($hash)) {
			my $normalized = $self->_normalize_password($password);
			return $validator->verify_password($normalized, $hash);
		}
	}

	return 0;
}

sub curry_with_hash {
	my ($self, $hash) = @_;
	require Crypt::Passphrase::PassphraseHash;
	return Crypt::Passphrase::PassphraseHash->new($self, $hash);
}

sub curry_with_password {
	my ($self, $password) = @_;
	my $hash = $self->hash_password($password);
	return $self->curry_with_hash($hash);
}

1;

# ABSTRACT: A module for managing passwords in a cryptographically agile manner

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase - A module for managing passwords in a cryptographically agile manner

=head1 VERSION

version 0.015

=head1 SYNOPSIS

 my $authenticator = Crypt::Passphrase->new(
     encoder    => 'Argon2',
     validators => [ 'Bcrypt', 'SHA1::Hex' ],
 );

 my ($hash) = $dbh->selectrow_array("SELECT password FROM users WHERE name = ?", {}, $user);
 if (!$authenticator->verify_password($password, $hash)) {
     die "Invalid password";
 }
 elsif ($authenticator->needs_rehash($hash)) {
     my $new_hash = $authenticator->hash_password($password);
     $dbh->do("UPDATE users SET password = ? WHERE name = ?", {}, $new_hash, $user);
 }

=head1 DESCRIPTION

This module manages the passwords in a cryptographically agile manner. Following Postel's principle, it allows you to define a single scheme that will be used for new passwords, but several schemes to check passwords with. It will be able to tell you if you should rehash your password, not only because the scheme is outdated, but also because the desired parameters have changed.

Note that this module doesn't depend on any backend, your application will have to depend on one or more of the backends listed under L</SEE ALSO>

=head1 METHODS

=head2 new(%args)

This creates a new C<Crypt::Passphrase> object. It takes two named arguments:

=over 4

=item * encoder

A C<Crypt::Passphrase> object has a single encoder. This can be passed in three different ways:

=over 4

=item * A simple string

The name of the encoder class. If the value starts with a C<+>, the C<+> will be removed and the remainder will be taken as a fully-qualified package name. Otherwise, C<Crypt::Passphrase::> will be prepended to the value.

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

=item * normalization

This sets the unicode normalization form used for the password. Valid values are C<'C'> (the default), C<'D'>, C<'KC'> and C<'KD'>. You should probably not change this unless it's necessary for compatibility with something else, you should definitely not change this on an existing database as that will break passwords affected by normalization.

=back

=head2 hash_password($password)

This will hash a password with the encoder cipher, and return it (in crypt format). This will generally use a salt, and as such will return a different value each time even when called with the same password.

=head2 verify_password($password, $hash)

This will check a password satisfies a certain hash.

=head2 needs_rehash($hash)

This will check if a hash needs to be rehashed, either because it's in the wrong cipher or because the parameters are insufficient.

Calling this only ever makes sense after a password has been verified.

=head2 curry_with_hash($hash)

This creates a C<Crypt::Passphrase::PassphraseHash> object for the hash, effectively currying C<Crypt::Passphrase> with that hash. This can be useful for plugging C<Crypt::Passphrase> into some frameworks (e.g. ORMs) that require a singular object to contain everything you need to match passwords against.

=head1 TIPS AND TRICKS

=head2 Custom configurations

While encoders generally allow for a default configuration, I would strongly encourage anyone to research what settings work for your application. It is generally a trade-off between usability/resources and security.

If your application is deployed by different people than it's developed by it may be helpful to have the configuration for C<Crypt::Passphrase> part of your application configuration file and not be hardcoded so that your users can choose the right settings for them.

=head2 Unicode

C<Crypt::Passphrase> considers passwords to be text, and as such you should ensure any password input is decoded if it contains any non-ascii characters. C<Crypt::Passphrase> will take care of both normalizing and encoding such input.

=head2 DOS attacks

Hashing passwords is by its nature a heavy operations. It can be abused by malignant actors who want to try to DOS your application. It may be wise to do some form of DOS protection such as a proof-of-work schemei or a captcha.

=head2 Levels of security

In some situations, it may be appropriate to have different password settings for different users (e.g. set them more strict for administrators than for ordinary users).

=head1 BACKENDS

The following encoders are currently available on CPAN:

=over 4

=item * L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2>

This is a state-of-the-art memory-hard password hashing algorithm, recommended for higher-end parameters. Winner of the Password Hash Competition of 2015.

=item * L<Crypt::Passphrase::Bcrypt|Crypt::Passphrase::Bcrypt>

And older but still safe password hashing algorithm, recommended for lower-end parameters or if you need to be compatible with BSD system passwords.

=item * L<Crypt::Passphrase::Yescrypt|Crypt::Passphrase::Yescrypt>

Another state-of-the-art memory-hard password hashing algorithm. Finalist of the Password Hash Competition of 2015 and used in some recent Linux distributions for user passwords.

=item * L<Crypt::Passphrase::PBKDF2|Crypt::Passphrase::PBKDF2>

A FIPS-standardized hashing algorithm. Only recommended when FIPS-compliance is required.

=item * L<Crypt::Passphrase::Linux|Crypt::Passphrase::Linux>

An implementation of SHA-512, SHA256 and MD5 based C<crypt()>. Recommended if you need to be compatible with standard Linux system passwords.

=item * L<Crypt::Passphrase::Scrypt|Crypt::Passphrase::Scrypt>

A first-generation memory-hard algorithm, Argon2 is recommended instead if you want a memory-hard algorithm.

=item * L<Crypt::Passphrase::System|Crypt::Passphrase::System>

Your system's C<crypt> implementation. Support for various algorithms varies between platforms and platform versions, and while on some platforms it's a good backend one should not rely on this for a portable result.

=item * L<Crypt::Passphrase::Pepper::Simple|Crypt::Passphrase::Pepper::Simple>

A meta-encoder that adds peppering to your passwords by pre-hashing the inputs.

=back

=head1 INTEGRATIONS

A number of integrations of Crypt::Passphrase exist:

=over 4

=item * L<DBIx::Class::CryptColumn|DBIx::Class::CryptColumn>

=item * L<Mojolicious::Plugin::Passphrase|Mojolicious::Plugin::Passphrase>

=item * L<Dancer2::Plugin::CryptPassphrase|Dancer2::Plugin::CryptPassphrase>

=back

=for Pod::Coverage curry_with_password

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
