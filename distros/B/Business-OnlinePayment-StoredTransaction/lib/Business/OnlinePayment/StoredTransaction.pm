package Business::OnlinePayment::StoredTransaction;

use 5.008004;
use strict;
use warnings;
use Carp;
use Business::OnlinePayment;
use Crypt::OpenSSL::RSA;
use Crypt::CBC;
use Storable;
use MIME::Base64;
use Digest::MD5;

our @ISA = qw(Business::OnlinePayment);

our @EXPORT_OK = ();

our @EXPORT = ();

our $VERSION = '0.01';


# Preloaded methods go here.

sub set_defaults {
    my $self = shift;
    $self->build_subs(qw(public_key));
}

sub map_fields {
    my $self = shift;
    my %content = $self->content();
    $content{'type'} = lc($content{'type'});
    $content{'action'} =lc($content{'action'});
    $self->transaction_type($content{'type'});
    $self->public_key($content{'password'});
    $content{'password'} = '';
    $content{'name'} = $content{'first_name'}.' '.$content{'last_name'} 
        unless defined $content{'name'};
    $content{'expiration'} =~ /(\d\d)\D*(\d\d)/ if $content{'expiration'};
    $content{'expiration_month'} = $1 
        unless defined $content{'expiration_month'};
    $content{'expiration_year'} = $2 
        unless defined $content{'expiration_year'};
    $content{'currency'} = 'USD $' 
        unless defined $content{'currency'};
    $self->content(%content);
}

sub submit {
    my $self = shift;
    my %actions = ('normal authorization' => 1, 
                'authorization only' => 1,
                'credit' => 1, 
                'post authorization' => 1,
                'void' => 1);
    $self->map_fields();
    my %content = $self->content();
    my $public_key = $self->public_key();
    croak "No public key found in 'password'" unless $public_key;
    if ($actions{$content{action}}) {
        my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($public_key);
        my $plaintext = Storable::nfreeze(\%content);
        my $seckey = Digest::MD5::md5_hex(rand());
        my $encseckey;
        eval { $encseckey = $rsa_pub->encrypt($seckey) };
        my $cipher = Crypt::CBC->new( {'key'  => $seckey,
                                       'cipher'  => 'Blowfish',
                           });
        my $ciphertext = $cipher->encrypt($plaintext);
        $ciphertext = encode_base64($ciphertext);
        $ciphertext =~ s/\s+//g;
        $encseckey = encode_base64($encseckey);
        $encseckey =~ s/\s+//g;
        $ciphertext = "$encseckey:$ciphertext";
        if ($ciphertext and !$@) {
            $self->is_success(1);
            $self->authorization($ciphertext);
            $self->error_message("success");
        }
        else {
            $self->is_success(0);
            $self->error_message("failed to encrypt $@");
        }
    }
    else {
        croak "Bad Action >$content{action}< - That action is not supported";
    }
}

1;
__END__

=head1 NAME

Business::OnlinePayment::StoredTransaction - Perl extension using the 
Business::OnlinePayment interface to store credit card transactions safely
for later billing.

=head1 SYNOPSIS

  use Business::OnlinePayment;
  my $tx = new Business::OnlinePayment('StoredTransaction');
  $tx->content( type => 'Visa',
                amount => '1.00',
                cardnumber => '1234123412341238',
                expiration => '0100',
                action => 'normal authorization',
                name => 'John Doe',
                password => '-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAOoKKH0CZm6sWHGg4SygikvvAecDS+Lx6ilUZ8mIVJeV2d6YjEJRjy12
TSFdJTC0SiBDbJ4UHz5ayXhLShK0VvaQY+sfZwMX1SNZNYUyO8T7gY7QCzOrcSTS
CcBBrNWzz0CMWUO5oOIIYevKEimtsDvBtlVaYJArJdwJq9KB/RjRAgMA//8=
-----END RSA PUBLIC KEY-----' );

  $tx->submit();
  if ($tx->is_success()) {
      my $auth = $tx->authorization();
      open FH, '>> /some/file' # don't do this it's stupid
      print FH $auth;
  }
  else {
      warn $tx->error_message();
  }


=head1 DESCRIPTION

This module stores uses the Business::OnlinePayment interface to store credit
card details in a (hopefully) secure manner.  It uses Storable to store the
content, encrypts the content with a random Blowfish key, then encrypts the
key with a programmer supplied public RSA key.  The encrypted key, and content
is base64 encoded and concatenated together and returned by the authorization()
method as a string, which can then be stored in a database or on disk, to be
retrieved by the Business::OnlinePayment::StoredTransaction::Unstore module
using the corresponding private key (which should not be kept on the same
server).  Hopefully, if my implementation doesn't suck, this means that once
the credit card information is encrypted, there is no way to get it back 
without the correct private key, which of course should be stored somewhere
safe.  I am however not a cryptographer, so it is up to you as the user of
this module to determine if this is safe enough for you.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Business::OnlinePayment
Crypt::OpenSSL::RSA
Crypt::Blowfish
Crypt::CBC
Business::OnlinePayment::StoredTransaction::Unstore

=head1 AUTHOR

mock, E<lt>mock@obscurity.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by mock 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
