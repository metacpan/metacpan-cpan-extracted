package Crypt::Passphrase::PassphraseHash;
$Crypt::Passphrase::PassphraseHash::VERSION = '0.019';
use strict;
use warnings;

sub new {
	my ($class, $validator, $raw_hash) = @_;

	return bless {
		validator => $validator,
		raw_hash  => $raw_hash,
	}, $class;
}

sub verify_password {
	my ($self, $password) = @_;
	return $self->{validator}->verify_password($password, $self->{raw_hash});
}

sub needs_rehash {
	my $self = shift;
	return $self->{validator}->needs_rehash($self->{raw_hash});
}

sub raw_hash {
	my $self = shift;
	return $self->{raw_hash};
}

1;

# ABSTRACT: An object representing a hash for password checking

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::PassphraseHash - An object representing a hash for password checking

=head1 VERSION

version 0.019

=head1 DESCRIPTION

This class can be useful for plugging C<Crypt::Passphrase> into some frameworks (e.g. ORMs) that require a singular object to contain everything you need to match passwords against. Effectively it's little more or less than currying the C<$hash> parameter to C<verify_password> and C<needs_rehash>.

=head1 METHODS

=head2 new

 Crypt::Passphrase::PassphraseHash->new($crypt_passphrase, $raw_hash)

This takes a C<Crypt::Passphrase> object, and a hash string. You probably want to use the C<curry_with_hash> or C<curry_with_password> methods on C<Crypt::Passphrase> instead of calling this directly. Typically called by C<< Crypt::Passphrase->curry_with_hash($hash) >> instead of directly.

=head2 verify_password

 $hash->verify_password($password)

Verify that the password matches the hash in this object.

=head2 needs_rehash

 $hash->needs_rehash

Check if the hash needs to be rehashed.

=head2 raw_hash

 $hash->raw_hash

This returns the hash contained in this object as a string.

=head1 SEE ALSO

=over 4

=item * L<DBIx::Class::CryptColumn|DBIx::Class::CryptColumn>

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
