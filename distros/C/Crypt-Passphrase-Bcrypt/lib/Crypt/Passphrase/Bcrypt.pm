package Crypt::Passphrase::Bcrypt;
$Crypt::Passphrase::Bcrypt::VERSION = '0.006';
use strict;
use warnings;

use Crypt::Passphrase 0.010 -encoder;

use Carp 'croak';
use Crypt::Bcrypt 0.011 qw/bcrypt bcrypt_prehashed bcrypt_check_prehashed bcrypt_needs_rehash bcrypt_supported_prehashes/;

my %supported_prehash = map { $_ => 1 } bcrypt_supported_prehashes();

sub new {
	my ($class, %args) = @_;
	my $subtype = $args{subtype} // '2b';
	croak "Unknown subtype $subtype" unless $subtype =~ / \A 2 [abxy] \z /x;
	my $hash = $args{hash} // '';
	croak 'Invalid hash' if length $args{hash} and not $supported_prehash{ $args{hash} };
	return bless {
		cost    => $args{cost} // 14,
		subtype => $subtype,
		hash    => $hash,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes(16);
	return bcrypt_prehashed($password, $self->{subtype}, $self->{cost}, $salt, $self->{hash});
}

sub needs_rehash {
	my ($self, $hash) = @_;
	return bcrypt_needs_rehash($hash, @{$self}{qw/subtype cost hash/});
}

sub crypt_subtypes {
	return (qw/2a 2b 2x 2y/, map { "bcrypt-$_" } bcrypt_supported_prehashes());
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	return bcrypt_check_prehashed($password, $hash);
}

1;

#ABSTRACT: A bcrypt encoder for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Bcrypt - A bcrypt encoder for Crypt::Passphrase

=head1 VERSION

version 0.006

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
   encoder => {
     module => 'Bcrypt',
     cost   => 14,
     hash   => 'sha256',
   },
 );

=head1 DESCRIPTION

This class implements a bcrypt encoder for Crypt::Passphrase. For high-end parameters L<Crypt::Passphrase::Argon2|Crypt::Passphrase::Argon2> is recommended over this module as an encoder, as that provides memory-hardness and more easily allows for long passwords.

=head1 METHODS

=head2 new(%args)

=over 4

=item * cost

This is the cost factor that is used to hash passwords. It currently defaults to C<14>, but this may change in the future.

=item * subtype

=over 4

=item * C<2b>

This is the subtype everyone has been using since 2014.

=item * C<2y>

This type is considered equivalent to C<2b>. It is common on php but not elsewhere.

=item * C<2a>

This is an old and subtly buggy version of bcrypt. This is mainly useful for Crypt::Eksblowfish compatibility.

=item * C<2x>

This is a very broken version that is only useful for compatibility with ancient php versions.

=back

This is C<2b> by default, and you're unlikely to want to change this.

=item * hash

Pre-hash the password using the specified hash. It will support any hash supported by L<Crypt::Bcrypt|Crypt::Bcrypt>, which is currently C<'sha256'>, C<'sha384'> and C<'sha512'>. This is mainly useful because plain bcrypt is not null-byte safe and only supports 72 characters of input. This uses a salt-keyed hash to prevent password shucking.

=back

=head2 hash_password($password)

This hashes the passwords with bcrypt according to the specified settings and a random salt (and will thus return a different result each time).

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher or subtype, if any of the cost is lower that desired by the encoder or if the prehashing doesn't match.

=head2 crypt_types()

This returns the above described subtypes, as well as C<bcrypt-sha256> for prehashed bcrypt.

=head2 verify_password($password, $hash)

This will check if a password matches a bcrypt hash.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
