package Crypt::Passphrase::Linux;
$Crypt::Passphrase::Linux::VERSION = '0.003';
use strict;
use warnings;

use Crypt::Passphrase 0.010 -encoder;

use Carp 'croak';
use Crypt::Passwd::XS 'crypt';
use MIME::Base64 qw/encode_base64/;

my %identifier_for = (
	md5        => '1',
	apache_md5 => 'apr1',
	sha256     => '5',
	sha512     => '6',
);

my %salt_size = (
	md5        => 6,
	apache_md5 => 6,
	sha256     => 12,
	sha512     => 12,
);

sub new {
	my ($class, %args) = @_;
	my $type_name = $args{type} // 'sha512';
	my $type = $identifier_for{$type_name} // croak "No such crypt type $type_name";
	my $salt_size = $salt_size{$type_name};
	my $rounds = $args{rounds} // 656_000;

	return bless {
		type      => $type,
		rounds    => $rounds + 0,
		salt_size => $salt_size,
	}, $class;
}

sub hash_password {
	my ($self, $password) = @_;
	my $salt = $self->random_bytes($self->{salt_size});
	(my $encoded_salt = encode_base64($salt, "")) =~ tr{A-Za-z0-9+/=}{./A-Za-z0-9}d;
	my $settings = sprintf '$%s$rounds=%d$%s', $self->{type}, $self->{rounds}, $encoded_salt;
	return Crypt::Passwd::XS::crypt($password, $settings);
}

sub accepts_hash {
	my ($self, $hash) = @_;
	return $hash =~ / \A [.\/A-Za-z0-9]{13} \z /x || $self->SUPER::accepts_hash($hash);
}

sub crypt_subtypes {
	return values %identifier_for;
}

my $regex = qr/ ^ \$ (1|5|6|apr1) \$ (?: rounds= ([0-9]+) \$ )? ([^\$]*) \$ [^\$]+ $ /x;

sub needs_rehash {
	my ($self, $hash) = @_;
	my ($type, $rounds, $salt) = $hash =~ $regex or return 1;
	$rounds = 5000 if $rounds eq '';
	return $type ne $self->{type} || $rounds != $self->{rounds} || length $salt != $self->{salt_size} * 4 / 3;
}

sub verify_password {
	my ($class, $password, $hash) = @_;
	my $new_hash = Crypt::Passwd::XS::crypt($password, $hash);
	return $class->secure_compare($hash, $new_hash);
}

#ABSTRACT: An linux crypt encoder for Crypt::Passphrase

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Linux - An linux crypt encoder for Crypt::Passphrase

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(encoder => {
   module => 'Linux',
   type   => 'sha512',
   rounds => 656_000,
 });

=head1 DESCRIPTION

This class implements a Crypt::Passphrase encoder compatible with Linux' crypt.

=head1 METHODS

=head2 new(%args)

This creates a new crypt encoder, it takes named parameters that are all optional. Note that some defaults are likely to change at some point in the future, as computers get progressively more powerful and cryptoanalysis gets more advanced.

=over 4

=item * type

This choses the crypt type. It supports the following crypt types: C<sha512> (default), C<sha256>, C<md5>, and C<apache_md5>

=item * rounds

The number of rounds using by the crypt implementation. This defaults to C<656000>, but may change at any time in the future.

=back

=head2 hash_password($password)

This hashes the passwords with argon2 according to the specified settings and a random salt (and will thus return a different result each time).

=head2 needs_rehash($hash)

This returns true if the hash uses a different cipher, or if any of the parameters are different than desired by the encoder.

=head2 crypt_types()

This class supports the following crypt types: C<1>, C<5>, C<6>, C<apr1>.

=head2 verify_password($password, $hash)

This will check if a password matches a linux crypt hash.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
