package Authen::Htpasswd::Util;
use strict;
use Digest;
use Carp;

use vars qw{@ISA @EXPORT};
BEGIN {
    require Exporter;
    @ISA = qw/ Exporter /;
    @EXPORT = qw/ htpasswd_encrypt /;
}

my @CRYPT_CHARS = split(//, './0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz');

=head1 NAME

Authen::Htpasswd::Util - performs encryption of supported .htpasswd formats

=head1 METHODS

=head2 htpasswd_encrypt

    htpasswd_encrypt($hash,$password,$hashed_password);

Encrypts a cleartext $password given the specified $hash (valid values are C<md5>, C<sha1>, C<crypt>, or C<plain>).
For C<crypt> and C<md5> it is sometimes necessary to pass the old encrypted password as $hashed_password 
to be sure that the new one uses the correct salt. Exported by default.

=cut

sub htpasswd_encrypt {
    my ($hash,$password,$hashed_password) = @_;
    my $meth = __PACKAGE__->can("_hash_$hash");
    croak "don't know how to handle $hash hash" unless $meth;
    return &$meth($password,$hashed_password);
}

=head2 supported_hashes

    my @hashes = Authen::Htpasswd::Util::supported_hashes();

Returns an array of hash types available. C<crypt> and C<plain> are always available. C<sha1> is checked by
attempting to load it via L<Digest>. C<md5> requires L<Crypt::PasswdMD5>.

=cut

sub supported_hashes {
    my @supported = qw/ crypt plain /;
    eval { Digest->new("SHA-1") };
    unshift @supported, 'sha1' unless $@;
    eval { require Crypt::PasswdMD5 };
    unshift @supported, 'md5' unless $@;
    return @supported;    
}

sub _hash_plain {
    my ($password) = @_;
    return $password;
}

sub _hash_crypt {
    my ($password,$salt) = @_;
    $salt = join('', @CRYPT_CHARS[int rand 64, int rand 64]) unless $salt;
    return crypt($password,$salt); 
}

sub _hash_md5 {
    my ($password,$salt) = @_;
    require Crypt::PasswdMD5;
    return Crypt::PasswdMD5::apache_md5_crypt($password,$salt);
}

sub _hash_sha1 {
    my ($password) = @_;
    my $sha1 = Digest->new("SHA-1");
    $sha1->add($password);
    return '{SHA}' . $sha1->b64digest . '=';
}

=head1 AUTHOR

David Kamholz C<dkamholz@cpan.org>

Yuval Kogman

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2005 - 2007 the aforementioned authors.
    
    This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut

1;
