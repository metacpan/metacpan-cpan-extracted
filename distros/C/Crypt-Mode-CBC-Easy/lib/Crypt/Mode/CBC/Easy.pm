use strict;
package Crypt::Mode::CBC::Easy;
#ABSTRACT: Encrypts/decrypts text and verifies decrypted text with a checksum and a random initialization vector.
$Crypt::Mode::CBC::Easy::VERSION = '0.006';
use Mouse;
use Crypt::CBC;
use Digest::SHA;
use MIME::Base64;
use Bytes::Random::Secure qw//;
use Crypt::Mode::CBC;
use Carp;




has key => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);


has crypt_mode_cbc => (
    isa => 'Crypt::Mode::CBC',
    is => 'ro',
    required => 1,
    default => sub { Crypt::Mode::CBC->new('Twofish') },
);


has block_size => (
    isa => 'Int',
    is => 'ro',
    required => 1,
    default => 16,
);


has checksum_digest_hex => (
    isa => 'CodeRef',
    is => 'ro',
    required => 1,
    default => sub { \&Digest::SHA::sha512_hex },
);


has bytes_random_secure => (
    isa => 'Bytes::Random::Secure',
    is => 'ro',
    required => 1,
    default => sub { Bytes::Random::Secure->new(NonBlocking => 1) },
);


has separator => (
    isa => 'Str',
    is => 'ro',
    required => 1,
    default => '::~;~;~::',
);


sub encrypt {
    my ($self, @plain_texts) = @_;

    croak "must pass in text to be encrypted" unless @plain_texts;

    my $iv = $self->bytes_random_secure->bytes($self->block_size);

    my $digest = $self->_get_digest($iv, \@plain_texts);
    push @plain_texts, $digest;
    
    my $plain_texts_str = join($self->separator, @plain_texts);    
    my $encrypted = $iv . $self->separator . $self->crypt_mode_cbc->encrypt($plain_texts_str, $self->key, $iv);    
    my $cipher_text = MIME::Base64::encode($encrypted);

    return $cipher_text;
}


sub decrypt { 
    my ($self, $cipher_text) = @_;

    croak "must pass in text to be decrypted" unless $cipher_text;

    my $separator = $self->separator;
    my ($iv, $to_decrypt) = split $separator, MIME::Base64::decode($cipher_text);

    croak "invalid cipher text" unless $iv and $to_decrypt;

    my $plain_text_with_checksum = $self->crypt_mode_cbc->decrypt($to_decrypt, $self->key, $iv);
    
    my @decrypted_values = split $separator, $plain_text_with_checksum;
    my $digest = pop @decrypted_values;
    my $confirm_digest = $self->_get_digest($iv, \@decrypted_values);

    if ($confirm_digest eq $digest) {
        if (wantarray) { 
            return @decrypted_values;
        }
        else {
            return join($separator , @decrypted_values);
        } 
    }
    else {
        croak "invalid encrypted text";
    }
}

sub _get_digest {
    my ($self, $iv, $texts) = @_;
    return $self->checksum_digest_hex->($iv . join('', @$texts));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::Mode::CBC::Easy - Encrypts/decrypts text and verifies decrypted text with a checksum and a random initialization vector.

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    my $crypt = Crypt::Mode::CBC::Easy->new(key => $bytes);
    my $cipher_text = $crypt->encrypt("hello");

    print "Cipher text: $cipher_text\n";

    my $plain_text = $crypt->decrypt($cipher_text);

    print "Plain text: $plain_text\n";

    # encrypt and decrypt an array of values
    my $cipher_text = $crypt->encrypt(@texts);

    print "Cipher text: $cipher_text\n";

    my @plain_texts = $crypt->decrypt($cipher_text);

    for my $plain_text (@plain_texts) {
        print "plain text: $plain_text\n";
    }

    # or get plain texts as one string separated by separator
    my $plain_text = $crypt->decrypt($cipher_text);

    print "Plain text: $plain_text\n";

=head1 DESCRIPTION

A convenience class that wraps L<Crypt::Mode::CBC> and adds random initialization vector support along with
a checksum to make sure that all decrypted text has not been tampered with. 

=head1 METHODS

=head2 key

The key that will be used for encrypting and decrypting. The key should be the appropriate length for the L<Crypt::Cipher> used with
L</crypt_mode_cbc>. For the default L<Crypt::Cipher> used, Twofish, the key should be 128/192/256 bits.

=head2 crypt_mode_cbc

Sets the L<Crypt::Mode::CBC> that will be used for encryption. Make sure if you change this that you set L</block_size> to the
correct value for the L<Crypt::Cipher> you have chosen. The default value uses L<Crypt::Cipher::Twofish>.

=head2 block_size

Sets the block size for the L<Crypt::Cipher> that is used. Default is 16, because this is the block size for L<Crypt::Cipher::Twofish>.

=head2 checksum_digest_hex

This is a subroutine reference to the digest hex that will be used for the checksum.

    my $crypt = Crypt::Mode::CBC::Easy->new(key => $bytes, checksum_digest_hex => \&Digest::SHA::sha256_hex);

Default is L<Digest::SHA::sha512_hex|Digest::SHA>.

=head2 bytes_random_secure

A L<Bytes::Random::Secure> instance that is used to generate the initialization vector for each encryption. Default is a L<Bytes::Random::Secure> instance with NonBlocking set to true.

=head2 separator

Sets the separator between the initialization vector, the encrypted text, and the checksum. This should not need to be changed, and is only available for backwards
compatability with L<DBIx::Raw> which used to use L<DBIx::Raw::Crypt>. Default value is '::~;~;~::'. If you need to change this for backwards
compatability, use ':;:'.

=head2 encrypt

Encrypts plain texts or an array of plain texts.

    my $cipher_text = $crypt->encrypt($text);

    # OR
    
    my $cipher_text = $crypt->encrypt(@texts);

=head2 decrypt

Decrypts cipher text into one plain text or an array of plain texts.

    my $plain_text = $crypt->encrypt($cipher_text);

    # OR
    
    my @plain_texts = $crypt->decrypt($cipher_text);

If you previously encrypted an array of values and ask for a result in a scalar context, you will be returned the 
the decrypted values separated by L</separator>.

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
