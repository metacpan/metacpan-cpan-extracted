#!/usr/bin/perl

package Crypt::EAX;
use Moose;

our $VERSION = "0.04";

use Carp qw(croak);

use Digest::CMAC;
use Crypt::Ctr::FullWidth;

use namespace::clean -except => [qw(meta)];

has key => (
	isa => "Str",
	is  => "ro",
	required => 1,
);

has [qw(header nonce)] => (
	isa => "Str",
	is  => "ro",
	default => '',
);

has mode => (
	isa => "Str",
	is  => "rw",
);

has N => (
	isa => "Str",
	is  => "rw",
	lazy => 1,
	default => sub {
		my $self = shift;
		$self->omac_t( $self->n_omac, 0, $self->nonce );
	},
);

has cipher => (
	#isa => "ClassName|Object",
	is  => "rw",
	default => "Crypt::Rijndael",
);

has fatal => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has ctr => (
	isa => "Crypt::Ctr::FullWidth",
	is  => "ro",
	lazy => 1,
	default => sub {
		my $self = shift;
		Crypt::Ctr::FullWidth->new( $self->key, $self->cipher );
	},
);

has [qw(c_omac n_omac h_omac)] => (
	isa => "Digest::CMAC",
	is  => "ro",
	lazy => 1,
	default => sub {
		my $self = shift;
		Digest::CMAC->new( $self->key, $self->cipher );
	},
);

sub BUILDARGS {
	my ( $class, @args ) = @_;

	if ( @args == 1 ) {
		return { key => $args[0] }
	} elsif ( @args == 2 and $args[0] ne 'key' ) {
		return { key => $args[0], cipher => $args[1] }
	} else {
		return $class->SUPER::BUILDARGS(@args);
	}
};

sub _cbc_k {
	my ( $self, $m ) = @_;
	return;
}

sub reset {
	my $self = shift;

	$self->ctr->reset;
	$self->c_omac->reset;
	$self->h_omac->reset;

	$self->ctr->set_nonce($self->N);

	$self->omac_t( $self->c_omac, 2 );
	if ( length ( my $header = $self->header ) ) {
		$self->omac_t( $self->h_omac, 1, $header );
	}
}

sub BUILD {
	my ( $self, $args ) = @_;
	$self->omac_t( $self->h_omac, 1 );
	$self->reset;
}

sub start {
	my ( $self, $mode ) = @_;
	$self->mode($mode);
}

sub encrypt_parts {
	my ( $self, $plain ) = @_;

	$self->start('encrypting');

   	return ( $self->add_encrypt($plain), $self->finish );
}

sub encrypt {
	my ( $self, $plain ) = @_;
	return join('', $self->encrypt_parts($plain) );
}

sub decrypt_parts {
	my ( $self, $ciphertext, $tag ) = @_;

	$self->start('decrypting');

	my $plain = $self->add_decrypt( $ciphertext );

	if ( $self->finish($tag) ) {
		return $plain;
	} else {
		$self->verification_failed($ciphertext, $plain, $tag);
	}
}

sub decrypt {
	my ( $self, $ciphertext ) = @_;

	my $blocksize = $self->blocksize;

	$ciphertext =~ s/(.{$blocksize})$//s;
	my $tag = $1;

	$self->decrypt_parts( $ciphertext, $tag );
}

sub verification_failed {
	my $self = shift;

	if ( $self->fatal ) {
		croak "Verification of ciphertext failed";
	} else {
		return;
	}
}

sub add_header {
	my ( $self, $plain ) = @_;

	$self->h_omac->add( $plain );

	return;
}

sub add_encrypt {
	my ( $self, $plain ) = @_;

	my $ciphertext = $self->ctr->encrypt($plain) || '';

	$self->c_omac->add( $ciphertext );

	return $ciphertext;
}

sub add_decrypt {
	my ( $self, $ciphertext ) = @_;

	$self->c_omac->add( $ciphertext );

	my $plain = $self->ctr->decrypt($ciphertext);

	return $plain;
}

sub finish {
	my ( $self, @args ) = @_;

	die "No current mode. Did you forget to call start()?" unless $self->mode;

	my $tag = $self->tag;

	if ( $self->mode eq 'encrypting' ) {
		return $tag;
	} elsif ( $self->mode eq 'decrypting' ) {
		return 1 if $tag eq $args[0];
		return;
	} else {
		croak "Unknown mode: " . $self->mode;
	}
}

sub tag {
	my $self = shift;

	my $N = $self->N;
	my $H = $self->h_omac->digest;
	my $C = $self->c_omac->digest;

	$self->reset;

	return $N ^ $H ^ $C;
}

sub omac_t {
	my ( $self, $omac, $t, @msg ) = @_;

	my $blocksize = $self->blocksize;
	my $padsize = $blocksize -1;

	my $num = pack("x$padsize C", $t);

	$omac->add( $num );

	$omac->add( $_ ) for @msg;

	return $omac->digest if defined wantarray;
}

sub blocksize {
	my $self = shift;

	$self->c_omac->{cipher}->blocksize;
}

__PACKAGE__->meta->make_immutable if __PACKAGE__->meta->can("make_immutable");

__PACKAGE__;

__END__

=pod

=head1 NAME

Crypt::EAX - Encrypt and authenticate data in EAX mode

=head1 SYNOPSIS

	use Crypt::EAX;

	my $c = Crypt::EAX->new(
		key => $key,
		cipher => "Crypt::Rijndael",
		header => $header, # optional
		nonce => $nonce, # optional but reccomended
		fatal => 1,
	);

	my $ciphertext = $c->encrypt( $message );

	$ciphertext ^= "moose"; # corrupt it

	$c->decrypt( $ciphertext ); # dies

	$ciphertext ^= "moose"; # xor is reversible

	is( $c->decrypt( $ciphertext ), $msg );

=head1 DESCRIPTION

EAX is a cipher chaining mode with integrated message authentication. This type
of encryption mode is called AEAD, or Authenticated Encryption with Associated
Data.

The purpuse of AEAD modes is that you can safely encrypt and sign a value with
a shared key. The message will not decrypt if it has been tampered with.

There are various reasons why just C<encrypt(mac($message))> is not safe, but I
don't exactly know them since I'm not a crptographer. For more info use The
Oracle Google.

Read more about EAX AEAD here:

=over 4

=item L<http://en.wikipedia.org/wiki/EAX_mode>

=item L<http://en.wikipedia.org/wiki/AEAD_block_cipher_modes_of_operation>

=back

=head1 CONFIGURATION

=over 4

=item key

The key used to encrypt/decrypt and authenticate. Passed verbatim to
L<Crypt::Ctr::FullWidth> and L<Digest::CMAC>.

=item cipher

Defaults to L<Crypt::Rijndael>. Likewise passed verbatim.

=item fatal

Whether or not failed verification dies or returns a false value.

=item header

Additional data to be authenticated but not encrypted.

Note that it's also possible to incrementally add the header using
C<add_header>.

If the C<header> option is passed instead then C<add_header> will be called
with it as an argument every time C<reset> is called.

This will not be included in the resulting ciphertext, but the ciphertext must
be authenticated against it.

Presumably you are supposed to encode the ciphertext and header together in
your message.

This is the Associated Data part of AEAD.

Be careful if you deconstruct the message naively, like this:

	my ( $header, $ciphertext ) = unpack("N/a a*", $message);

since you are inherently trusting the input data already, before it's been
verified (the N/ part can be altered, and though knowing Perl this is probably
safe, I wouldn't count on it). The specific attack in this case is if a large
number is encoded by the attacker in the N field then it could trick your
program into trying allocate 4GB of memory in this particular example.

At any rate do not trust the header till the ciphertext has been successfully
decrypted.

=item nonce

The nonce to use for authentication. Should be unique. See
L<http://en.wikipedia.org/wiki/Cryptographic_nonce>.

It is OK to pass this along with the ciphertext, much like the salt bit in
C<crypt>.

An empty value is allowed and is in fact the default, but this is not safe
against replay attacks.

=back

=head1 METHODS

=over 4

=item new %args

Instantiate a new L<Crypt::EAX> object.

See L</CONFIGURATION>.

=item encrypt $plaintext

=item decrypt $ciphertext

Single step encryption/decryption.

The tag is appended to the ciphertext.

=item encrypt_parts $plaintext

Returns the ciphertext and tag as separate tags.

=item decrypt_parts $ciphertext, $tag

Decrypts and verifies the message.

=item start $mode

Takes either C<encrypting> or C<decrypting>.

=item finish ?$tag

If encrypting, returns the tag.

If decrypting, checks that $tag is equal to the calculated tag.

Used by C<encrypt_parts> and C<decrypt_parts>.

=item add_encrypt $text

=item add_decrypt $ciphertext

Streaming mode of operation. Requires a call to C<start> before and C<finish>
after. Used by C<decrypt_parts> and C<encrypt_parts>.

=item add_header $header

Add header data that will be authenticated as well. See C<header> for more
details.

=item verification_failed

Called when verification fails. Dies when C<fatal> is set, returns a false
value otherwise.

=back

=head1 TODO

=over 4

=item *

Consider disallowing an empty nonce.

Can anyone advise on this?

=back

=head1 SEE ALSO

L<Digest::CMAC>, L<Crypt::Ctr>, L<Crypt::Ctr::FullWidth>, L<Crypt::Util>

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute it and/or modify it
	under the terms of the MIT license or the same terms as Perl itself.

=cut


