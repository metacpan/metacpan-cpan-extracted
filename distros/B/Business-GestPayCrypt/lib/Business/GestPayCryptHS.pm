
package Business::GestPayCryptHS;

#
# Business::GestPayCryptHS is Copyright (C) 2002-2004 Open2b Software S.r.l. All Rights Reserved.
#
# This code is distributed under the same license as Perl 5; you can
# redistribute it and/or modify it under the terms of either:
#
#     a) the GNU General Public License
#
#     b) the Artistic License
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either
# the GNU General Public License or the Artistic License for more details.
#

$VERSION = '0.41';

=head1 NAME

  Business::GestPayCryptHS - Perl interface to the italian online payment system GestPay

=head1 SYNOPSIS

  #
  # Request
  #

  use Business::GestPayCryptHS;
  my $obj = new Business::GestPayCryptHS;

  $obj->SetShopLogin($ShopLogin);
  $obj->SetCurrency($Currency);
  $obj->SetAmount($Amount);
  $obj->SetShopTransactionID($ShopTransationID);
  $obj->SetLanguage($Language);

  $obj->Encrypt();

  if ( $obj->GetErrorCode() ) {
      print 'Error: ', $obj->GetErrorCode(), ' ',
          $objCrypt->GetErrorDescription();
  } else {
      my $a = $obj->GetShopLogin();
      my $b = $obj->GetEncryptedString();
      print qq~
          <form action="https://ecomm.sella.it/gestpay/pagam.asp">
            <input type="hidden" name="a" value="$a">
            <input type="hidden" name="b" value="$b">
            <input type="submit" value="Payment">
          </form>~;
  }

  #
  # Response
  #

  $obj->SetShopLogin($ShopLogin);
  $obj->SetEncryptedString($b);

  $obj->Decrypt();

  if ( $objCrypt->GetErrorCode() ) {
      print 'Error: ', $obj->GetErrorCode() , ' ',
          $objCrypt->GetErrorDescription();
  } else {
      print 'ShopLogin : ', $obj->GetShopLogin(), "\n";
      print 'Currency :', $obj->GetCurrency(), "\n";
      print 'Amount : ', $obj->GetAmount(), "\n";
      print 'ShopTransactionID : ', $obj->GetShopTransactionID(), "\n";
      print 'BuyerName : ', $obj->GetBuyerName(), "\n";
      print 'BuyerEmail : ', $obj->GetBuyerEmail(), "\n";
      print 'TransactionResult : ', $obj->GetTransactionResult(), "\n";
      print 'AuthorizationCode : ', $obj->GetAuthorizationCode(), "\n";
      print 'BankTransactionID : ', $obj->GetBankTransactionID(), "\n";
      print 'ErrorCode : ', $obj->GetErrorCode(), "\n";
      print 'ErrorDescription : ', $obj->GetErrorDescription(), "\n";
      print 'AlertCode : ', $obj->GetAlertCode(), "\n";
      print 'AlertDescription : ', $obj->GetAlertDescription(), "\n";
      print 'CustomInfo : ', $obj->GetCustomInfo(), "\n";
  }

=head1 DESCRIPTION

  This class implements the italian system for on-line payments GestPay,
  of Banca Sella, in the cryptography version and with server to server
  SSL crypted communication.

  The class crypts the data of the transaction and returns the data as an encrypted string
  to send to the GestPay server for payment.
  The communication from shop server and the GestPay server is encrypted
  with SSL.

  For more information see the reference manual of Banca Sella at http://www.sellanet.it.

=head1 REQUIRED MODULES

L<Business::GestPayCrypt|Business::GestPayCrypt>

L<Net::SSLeay|Net::SSLeay>

  OpenSSH

=cut

use strict;
use Net::SSLeay;

use Business::GestPayCrypt;
our @ISA = ( 'Business::GestPayCrypt' );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{'ScriptEnCrypt'} = '/CryptHTTPS/Encrypt.asp';
    $self->{'ScriptDecrypt'} = '/CryptHTTPS/Decrypt.asp';
    return $self;
}

sub cat_server {
    my ($self,$request) = @_;
    $Net::SSLeay::slowly = 1;
    my $response = Net::SSLeay::sslcat($self->{'DomainName'},8080,"GET $request \n\r\n");
    if ( $! ) {
        $self->{'ErrorCode'} = '9999';
        $self->{'ErrorDescription'} = "Error: $!";
        return;
    }
    return $response;
}

=head1 AUTHOR

  Marco Gazerro <gazerro@open2b.com>

=head1 SEE ALSO

  Business::GestPayCrypt
  Business::BancaSella

=head1 COPYRIGHT

  Copyright (c) 2002-2004 Open2b Software S.r.l. ( www.open2b.com )

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
