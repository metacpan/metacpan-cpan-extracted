package Crypt::Passphrase::PassphraseHash;
$Crypt::Passphrase::PassphraseHash::VERSION = '0.006';
use strict;
use warnings;

sub new {
	my ($class, $crypt_passphrase, $hash) = @_;

	return bless {
		validator => $crypt_passphrase,
		raw_hash  => $hash,
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

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::PassphraseHash

=head1 VERSION

version 0.006

=head1 DESCRIPTION

This class can be useful for plugging C<Crypt::Passphrase> into some frameworks (e.g. ORMs).

=head1 METHODS

=head2 new($crypt_passphrase, $hash)

This takes a Crypt::Passphrase object, and a hash string.

=head2 verify_password($password)

Verify that the password matches the hash in this object.

=head2 needs_rehash()

Check if the hash needs to be rehashed.

=head2 raw_hash()

This returns the hash of this object as a string.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
