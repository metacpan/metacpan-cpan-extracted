package Crypt::Passphrase::Encoder;
$Crypt::Passphrase::Encoder::VERSION = '0.015';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Validator';

use Crypt::URandom;

sub random_bytes {
	my ($self, $count) = @_;
	return Crypt::URandom::urandom($count);
}

sub crypt_subtypes;

sub accepts_hash {
	my ($self, $hash) = @_;
	return 0 if not defined $hash;
	$self->{accepts_hash} //= do {
		my $string = join '|', $self->crypt_subtypes or return;
		qr/ \A \$ (?: $string ) \$ /x;
	};
	return $hash =~ $self->{accepts_hash};
}

sub binary_safe {
	return 1;
}

1;

#ABSTRACT: Base class for Crypt::Passphrase encoders

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Encoder - Base class for Crypt::Passphrase encoders

=head1 VERSION

version 0.015

=head1 DESCRIPTION

This is a base class for password encoders. It is a subclass of C<Crypt::Passphrase::Validator>.

=head1 METHODS

=head2 hash_password($password)

This hashes a password. Note that this will return a new value each time since it uses a unique hash every time.

=head2 needs_rehash($hash)

This method will return true if the password needs a rehash. This may either mean it's using a different hashing algoritm, or because it's using different parameters. This should be overloaded in your subclass.

=head2 crypt_subtypes()

This method returns the types of crypt entries this validator supports. This is used to implement C<accepts_hash>.

=head2 binary_safe()

This method returns true if the encoder can take arbitrary binary inputs.

=head2 random_bytes($count)

This is a utility method provided by the base class to aid in generating a good salt.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
