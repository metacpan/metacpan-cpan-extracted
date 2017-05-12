package Business::OnlinePayment::StoredTransaction::Unstore;

use 5.008004;
use strict;
use warnings;
use Carp;
use Crypt::OpenSSL::RSA;
use Crypt::CBC;
use Storable;
use MIME::Base64;

our @ISA = qw();

our @EXPORT_OK = ();

our @EXPORT = ();

our $VERSION = '0.01';

#takes private RSA key and string returned by StoredTransaction->authorization
#takes arguments (private_key => $privkey, authorization => $auth)
sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {
        @_,
    };
    bless $self, $class;

    croak "missing 'private_key'" unless $self->{'private_key'};
    my $privkey = $self->{'private_key'};
    croak "missing 'authorization'" unless $self->{'authorization'};
    croak "bad authorization" unless $self->{'authorization'} =~ /:/;
    my ($seckey, $ciphertext) = split /:/, $self->{'authorization'};
    $seckey = decode_base64($seckey);
    $ciphertext = decode_base64($ciphertext);
    my $rsa_priv;
    eval {$rsa_priv = Crypt::OpenSSL::RSA->new_private_key($privkey)};
    croak $@ if $@;
    eval {$seckey = $rsa_priv->decrypt($seckey)};
    croak $@ if $@;
    my $cipher = Crypt::CBC->new( {'key' => $seckey,
                                   'cipher' => 'Blowfish',
                                });
    my $plaintext = $cipher->decrypt($ciphertext);
    croak "no plaintext" unless $plaintext;
    my $data = Storable::thaw($plaintext);
    $self->{data} = $data;
    return $self;
}

#returns hash containing content or single value from hash if given a key
sub get {
    my $self = shift;
    my $key = shift;
    my %data = %{$self->{data}};
    return $data{$key} if defined $key;
    return %data;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Business::OnlinePayment::StoredTransaction::Unstore - Perl extension for
retrieval of credit card details stored using 
Business::OnlinePayment::StoredTransaction

=head1 SYNOPSIS

  use Business::OnlinePayment::StoredTransaction::Unstore;
  my $bitz = Business::OnlinePayment::StoredTransaction::Unstore->new(
      private_key => '-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQDqCih9AmZurFhxoOEsoIpL7wHnA0vi8eopVGfJiFSXldnemIxC
UY8tdk0hXSUwtEogQ2yeFB8+Wsl4S0oStFb2kGPrH2cDF9UjWTWFMjvE+4GO0Asz  
q3Ek0gnAQazVs89AjFlDuaDiCGHryhIprbA7wbZVWmCQKyXcCavSgf0Y0QIDAP//
AoGABlQEpEXw4vbz6yZwvRGkTunpSxRV5ZzIHZ4x3JjYQmGDoZRpf0SLz5p+eGFp
HtY+x1YaCfA9OIDU62GUhk3+l+QIuhjV0/2cnAQ8x81r82zmbioWcmkAyLYKrkgS
mKJHfWB2u7YRnTJLTPQ03GnTTNSJvxCRm9ns3xCJbe4dig8CQQD9ZMYMSRynzRXT
ri/yvEepml/Evs7M1aRsnGW19VddPi2HEFlbuHUiHxN661wH14fovMQfHyLHjRa4
GL9HovzLAkEA7HJsI1YTixoyjz4BXPLGksToA77EbZQIBA8f+p+4K/gRJXM1lkPb
LQlAMkVmpW3wWI23iqKdTqVRypZXUYYJUwJASNd7wc3aGZqOy8tTNdMTULVgEveI
e+w50y58b124/de4gBbUNrDp5Lvhnmw8fcGTpBu/YE2clgeFumtfj6BK2QJBAMPB
qpqX0LvdRzLwJ28MCUPxuos8TbmJ5IDIymF29p+Vej98dhzCgEn0T5MuGh4Vd623
2Wjm86Tc8Ojqimrvo80CQQC0hUQn1Qc3giMkxdBfBfmAgaOMUnGZ2LQ/xjc+6o3i
qkO/USX24l9TfRa0S+zPCnvgjnzEjBTsH6eF2S/wK2K5
-----END RSA PRIVATE KEY-----',
     authorization => $auth );  # $auth is the string returned from the 
                                # authorization method of
                                # Business::OnlinePayment::StoredTransaction
  my $cardnumber = $bitz->get('cardnumber');
  my %content = $bitz->get();

=head1 DESCRIPTION

Decrypts stored transactions from Business::OnlinePayment::StoredTransaction
using the associated private RSA key.  It has two methods: new(), which returns
an unencrypted object, and takes the RSA private key and the string returned
by Business::OnlinePayment::StoredTransaction::authorization() as arguments, 
and get, which either returns a hash of all the content, or an individual
value if provided a key.  See the synopsis for details of usage.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Business::OnlinePayment::StoredTransaction
Crypt::CBC
Crypt::Blowfish
Crypt::OpenSSL::RSA
Storable
MIME::Base64

=head1 AUTHOR

mock, E<lt>mock@obscurity.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by mock 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
