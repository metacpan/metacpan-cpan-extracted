package Crypt::Passphrase::Pepper::Simple;
$Crypt::Passphrase::Pepper::Simple::VERSION = '0.019';
use strict;
use warnings;

use parent 'Crypt::Passphrase::Pepper::Base';
use Crypt::Passphrase -encoder;

use Carp 'croak';
use Digest::SHA;

my %algorithms = (
	'sha1-hmac'   => \&Digest::SHA::hmac_sha1,
	'sha224-hmac' => \&Digest::SHA::hmac_sha224,
	'sha256-hmac' => \&Digest::SHA::hmac_sha256,
	'sha384-hmac' => \&Digest::SHA::hmac_sha384,
	'sha512-hmac' => \&Digest::SHA::hmac_sha512,
);

sub new {
	my ($class, %args) = @_;

	my $peppers = $args{peppers} or croak('No peppers given');
	$args{active} //= (sort {; no warnings 'numeric'; $b <=> $a || $b cmp $a } keys %{ $peppers })[0];
	$args{algorithm} //= 'sha512-hmac';

	return $class->SUPER::new(%args);
}

sub prehash_password {
	my ($self, $password, $algorithm, $id) = @_;
	my $secret = $self->{peppers}{$id} or croak "No such pepper $id";
	my $func = $algorithms{$algorithm} or croak "No such algorithm $algorithm";
	return $func->($password, $secret);
}

sub supported_hashes {
	my $self = shift;
	return keys %algorithms;
}

1;

#ABSTRACT: A pepper-wrapper for Crypt::Passphrase

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Passphrase::Pepper::Simple - A pepper-wrapper for Crypt::Passphrase

=head1 VERSION

version 0.019

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder => {
         module  => 'Pepper::Simple',
         inner   => 'Bcrypt',
         peppers => {
             1 => pack('H*', '0123456789ABCDEF...'),
             2 => pack('H*', 'FEDCBA9876543210...'),
         },
     },
 );

=head1 DESCRIPTION

This module wraps another encoder to pepper the input to the hash. By using identifiers for the peppers, it allows for easy rotation of peppers. Much like password their function relies entirely on their secrecy, and they should be treated similarly.

It will be able to validate both peppered and unpeppered hashes.

=head1 CONFIGURATION

It takes the following configuration arguments:

=over 4

=item * inner

This contains an encoder specification identical to the C<encoder> field of C<Crypt::Passphrase>. C<It is mandatory>.

=item * peppers

This is a map of identifier to pepper value. The identifiers should be (probably small) numbers, the values should be random binary strings that are long enough to not be brute-forcable (the output size of the hash is a good choice). B<This is mandatory>.

=item * active

This is the active pepper. It must be one of the keys in C<peppers>, and by default it will be the key highest (numerical) value.

=item * algorithm

This is the algorithm that's used for peppering. Supported values are C<'sha1-hmac'>, C<'sha224-hmac'>, C<'sha256-hmac'>, C<'sha384-hmac'>, and C<'sha512-hmac'> (the default).

=back

=head2 Supported types

The supported peppered types are a the inner encoders types cross joined with the algorithms with C<"-pepper-"> (e.g. C<"argon2id-pepper-sha512-hmac">), as well as the underlaying types themselves (e.g. C<"argon2id">.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
