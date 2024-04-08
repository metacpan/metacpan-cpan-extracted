package Crypt::Passphrase::Bcrypt::AES;

use 5.014;
use warnings;

our $VERSION = '0.002';

use parent 'Crypt::Passphrase::Bcrypt::Encrypted';
use Crypt::Passphrase 0.019 -encoder;

use Carp 'croak';
use Crypt::Rijndael 1.16;

my %mode = (
	'aes-cfb' => Crypt::Rijndael::MODE_CFB,
	'aes-ofb' => Crypt::Rijndael::MODE_OFB,
	'aes-ctr' => Crypt::Rijndael::MODE_CTR,
	'aes-ecb-pad' => Crypt::Rijndael::MODE_ECB,
	'aes-cbc-pad' => Crypt::Rijndael::MODE_CBC,
);

sub new {
	my ($class, %args) = @_;
	my $peppers = $args{peppers} or croak('No peppers given');
	$args{active} //= (sort {; no warnings 'numeric'; $b <=> $a || $b cmp $a } keys %{ $peppers })[0];
	my $mode = delete $args{mode} // 'ctr';
	my $cipher = "aes-$mode";
	croak("No such mode $mode") if not exists $mode{$cipher};
	my $self = $class->SUPER::new(%args, cipher => $cipher);
	for my $key (keys %{$peppers}) {
		my $length = length $peppers->{$key};
		croak "Pepper $key has invalid length $length" if $length != 16 && $length != 24 && $length != 32;
		$self->{peppers}{$key} = $peppers->{$key};
	}
	return $self;
}

sub encrypt_hash {
	my ($self, $cipher, $id, $iv, $raw) = @_;
	if ($cipher =~ /-pad$/) {
		my $pad_length = 16 - length($raw) % 16;
		$raw .= chr($pad_length) x $pad_length;
	}
	my $mode = $mode{$cipher} or croak "No such cipher $cipher";
	my $secret = $self->{peppers}{$id} or croak "No such pepper $id";
	return Crypt::Rijndael->new($secret, $mode)->encrypt($raw, $iv);
}

sub decrypt_hash {
	my ($self, $cipher, $id, $iv, $raw) = @_;
	my $mode = $mode{$cipher} or croak "No such cipher $cipher";
	my $secret = $self->{peppers}{$id} or croak "No such pepper $id";
	my $plaintext = Crypt::Rijndael->new($secret, $mode)->decrypt($raw, $iv);
	if ($cipher =~ /-pad$/) {
		my $pad_length = ord substr $plaintext, -1;
		substr($plaintext, -$pad_length, $pad_length, '') eq chr($pad_length) x $pad_length or croak 'Incorrectly padded';
	}
	return $plaintext;
}

sub supported_ciphers {
	return keys %mode;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Passphrase::Bcrypt::AES - A peppered AES-encrypted Bcrypt encoder for Crypt::Passphrase

=head1 SYNOPSIS

 my $passphrase = Crypt::Passphrase->new(
     encoder => {
         module  => 'Bcrypt::AES',
         peppers => {
             1 => pack('H*', '0123456789ABCDEF...'),
             2 => pack('H*', 'FEDCBA9876543210...'),
         },
     },
 );

=head1 DESCRIPTION

This class implements peppering by encrypting the hash using AES (unlike L<Crypt::Passphrase::Pepper::Simple|Crypt::Passphrase::Pepper::Simple> which hashes the input instead).

=head2 Configuration

This module takes all arguments also taken by L<Crypt::Passphrase::Bcrypt|Crypt::Passphrase::Bcrypt>, with the following additions:

=over 4

=item * peppers

This is a map of identifier to pepper value. The identifiers should be (probably small) numbers, the values should be random binary strings that must be either 16, 24 or 32 bytes long. This argument is mandatory.

=item * active

This is the identifier of the active pepper. By default it will be the identifier with the highest (numerical) value.

=item * mode

This is the mode that will be used with C<AES>. Valid values are C<'ctr'> (the default), C<'cfb'>, C<'ofb'>, C<'cbc-pad'> or C<'ecb-pad'>.

=back

The C<hash> parameter will default to C<'sha384'>.

=head2 Supported crypt types

This supports any sequence of C<bcrypt->, C<(sha256 | sha384 | sha512)>, C<-encrypted-aes->, C<(ctr | cfb | ofb | cbc-pad | ecb-pad)>. E.g. C<bcrypt-sha384-encrypted-aes-ctr>

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
