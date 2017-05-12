
package Business::GestPayCrypt;

#
# Business::GestPayCrypt is Copyright (C) 2002-2004 Open2b Software S.r.l. All Rights Reserved.
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

  Business::GestPayCrypt - Perl interface to the italian online payment system GestPay

=head1 SYNOPSIS

  #
  # Request
  #

  use Business::GestPayCrypt;
  my $obj = new Business::GestPayCrypt;

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

  use Business::GestPayCrypt;
  my $obj = new Business::GestPayCrypt;

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
  of Banca Sella, in the cryptography version.

  The class crypts the data of the transaction and returns the data as an encrypted string
  to send to the GestPay server for payment.
  The communication from shop server and the GestPay server is not encrypted
  and is send with the HTTP protocol.

  For more information see the reference manual of Banca Sella at http://www.sellanet.it.

=cut

use Socket;
use strict;

sub new {
    my $class = shift;
    my $self = {
        # public methods
        AlertCode          => '',
        AlertDescription   => '',
        Amount             => '',
        AuthorizationCode  => '',
        BankTransactionID  => '',
        BuyerEmail         => '',
        BuyerName          => '',
        CardNumber         => '',
        Country            => '', # add 0.30
        Currency           => '',
        CustomInfo         => '',
        CVV                => '', # add 0.30
        EncryptedString    => '',
        Encryption         => '', # add 0.30
        ErrorCode          => '',
        ErrorDescription   => '',
        ExpMonth           => '',
        ExpYear            => '',
        Language           => '',
        MIN                => '', # add 0.30
        PasswordEncrypt    => '', # add 0.30
        ShopLogin          => '',
        ShopTransactionID  => '',
        TransactionResult  => '',
        VBV                => '', # add 0.30
        VBVrisp            => '', # add 0.30
        # private methods
        Decripted          => '',
        DomainName         => 'ecomm.sella.it',
        ScriptEncrypt      => '/CryptHTTP/Encrypt.asp',
        ScriptDecrypt      => '/CryptHTTP/Decrypt.asp',
        ToBeEncript        => '',
    };
    return bless $self, $class;
}

#
# implements the Get<Attribute> and Set<Attribute> methods
#
sub AUTOLOAD {
    my ($self,$value) = @_;
    my %permission = (
        AlertCode          => 'g',
        AlertDescription   => 'g',
        Amount             => 'gs',
        AuthorizationCode  => 'g',
        BankTransactionID  => 'g',
        BuyerEmail         => 'gs',
        BuyerName          => 'gs',
        CardNumber         => 's',
        Currency           => 'gs',
        Country            => 'g', # add 0.30
        CustomInfo         => 'gs',
        CVV                => 's', # add 0.30
        EncryptedString    => 'gs',
        Encryption         => 's', # add 0.30
        ErrorCode          => 'g',
        ErrorDescription   => 'g',
        ExpMonth           => 's',
        ExpYear            => 's',
        Language           => 's',
        MIN                => 's', # add 0.30
        PasswordEncrypt    => 's', # add 0.30
        ShopLogin          => 'gs',
        ShopTransactionID  => 'gs',
        TransactionResult  => 'g',
        VBV                => 'g', # add 0.30
        VBVrisp            => 'g', # add 0.30
    );
#    my $method = $GestPayCrypt::AUTOLOAD;          # add comment 0.40
    my $method = $Business::GestPayCrypt::AUTOLOAD; # add 0.40
    $method =~ /::(Get|Set)(.*)$/;
    if ( $1 eq 'Get' && ( $permission{$2} eq 'g' || $permission{$2} eq 'gs' )  ) {
        return $self->{$2};
    } elsif ( $1 eq 'Set' && ( $permission{$2} eq 's' || $permission{$2} eq 'gs' ) ) {
        $self->{$2} = $value;
        return;
    } else {
        my ($package,$filename,$line) = caller(); # add 0.40
        die "The method $method don't exists at $filename line $line\n";
    }
}

# add 0.30
sub SetWithoutEncryption {
    my $self = shift;
    $self->{'Encryption'} = 0;
    return;
}

# add 0.30
sub SetShopTransactionID {
    my ($self,$string) = @_;
    $self->{'ShopTransactionID'} = url_encode(trim($string));
    return;
}

# add 0.30
sub SetBuyerName {
    my ($self,$string) = @_;
    $self->{'BuyerName'} = url_encode(trim($string));
    return;
}

# add 0.30
sub SetBuyerEmail {
    my ($self,$string) = @_;
    $self->{'BuyerEmail'} = trim($string);
    return;
}

# add 0.30
sub SetLanguage {
    my ($self,$string) = @_;
    $self->{'Language'} = trim($string);
    return;
}

# add 0.30
sub SetCustomInfo {
    my ($self,$string) = @_;
    $self->{'CustomInfo'} = url_encode(trim($string));
    return;
}

# add 0.30
sub GetShopTransactionID {
    my $self = shift;
    return url_decode($self->{'ShopTransactionID'});
}

# add 0.30
sub GetBuyerName {
    my $self = shift;
    return url_decode($self->{'BuyerName'});
}

# add 0.30
sub GetCustomInfo {
    my $self = shift;
    return url_decode($self->{'CustomInfo'});
}

sub Encrypt {
    my $self = shift;

    $self->{'ErrorCode'} = '0';
    $self->{'ErrorDescription'} = '';

    # verify the attributes
    if ( $self->{'ShopLogin'} eq '' ) {
        $self->{'ErrorCode'} = '546';
        $self->{'ErrorDescription'} = 'IDshop not valid';
        return 0;
    }
    if ( $self->{'Currency'} eq '' ) {
        $self->{'ErrorCode'} = '552';
        $self->{'ErrorDescription'} = 'Currency not valid';
        return 0;
    }
    if ( $self->{'Amount'} eq '' ) {
        $self->{'ErrorCode'} = '553';
        $self->{'ErrorDescription'} = 'Amount not valid';
        return 0;
    }
    if ( $self->{'ShopTransactionID'} eq '' ) {
        $self->{'ErrorCode'} = '551';
        $self->{'ErrorDescription'} = 'Shop Transaction ID not valid';
        return 0;
    }

    # prepare the string to crypt
    my @to_be_encript = ();
    push @to_be_encript, ("PAY1_CVV=$self->{'CVV'}") if $self->{'CVV'} ne ''; # add 0.30
    push @to_be_encript, ("PAY1_MIN=$self->{'MIN'}") if $self->{'MIN'} ne ''; # add 0.30
    push @to_be_encript, ("PAY1_UICCODE=$self->{'Currency'}") if $self->{'Currency'} ne '';
    push @to_be_encript, ("PAY1_AMOUNT=$self->{'Amount'}") if $self->{'Amount'} ne '';
    push @to_be_encript, ("PAY1_SHOPTRANSACTIONID=$self->{'ShopTransactionID'}") if $self->{'ShopTransactionID'} ne '';
    push @to_be_encript, ("PAY1_CHNAME=$self->{'BuyerName'}") if $self->{'BuyerName'} ne '';
    push @to_be_encript, ("PAY1_CHEMAIL=$self->{'BuyerEmail'}") if $self->{'BuyerEmail'} ne '';
    push @to_be_encript, ("PAY1_IDLANGUAGE=$self->{'Language'}") if $self->{'Language'} ne '';
    push @to_be_encript, ($self->{'CustomInfo'}) if $self->{'CustomInfo'} ne '';
    $self->{'ToBeEncript'} = join('*P1*',@to_be_encript);
#    $self->{'ToBeEncript'} =~ s/ /§/g; # add comment 0.30

    # crypt the string
    return $self->query_server();
}

sub Decrypt {
    my $self = shift;

    $self->{'ErrorCode'} ='';
    $self->{'ErrorDescription'} = '';

    # verify the attributes
    if ( $self->{'ShopLogin'} eq '' ) {
        $self->{'ErrorCode'} = '546';
        $self->{'ErrorDescription'} = 'IDshop not valid';
        return 0;
    }
    if ( $self->{'EncryptedString'} eq '' ) {
        $self->{'ErrorCode'} = '1009';
        $self->{'ErrorDescription'} = 'String to Decrypt not valid';
        return 0;
    }

    # decrypt the string
    unless ( $self->query_server() ) {
        return 0;
    }

    # get the attributes from the string
#    $self->{'Decripted'} =~ s/§/ /g; # add comment 0.30
#    if ( $self->{'Decripted'} eq '' ) {
    if ( trim($self->{'Decripted'}) eq '' ) { # set 0.30
        $self->{'ErrorCode'} = '99999';
        $self->{'ErrorDescription'} = 'Void String';
        return 0;
    }
    my %fields = (
        PAY1_ALERTCODE         => 'AlertCode',
        PAY1_ALERTDESCRIPTION  => 'AlertDescription',
        PAY1_AMOUNT            => 'Amount',
        PAY1_AUTHORIZATIONCODE => 'AuthorizationCode',
        PAY1_BANKTRANSACTIONID => 'BankTransactionID',
        PAY1_CARDNUMBER        => 'CardNumber',
        PAY1_CHEMAIL           => 'BuyerEmail',
        PAY1_CHNAME            => 'BuyerName',
        PAY1_COUNTRY           => 'Country',  # add 0.30
        PAY1_ERRORCODE         => 'ErrorCode',
        PAY1_ERRORDESCRIPTION  => 'ErrorDescription',
        PAY1_EXPMONTH          => 'ExpMonth',
        PAY1_EXPYEAR           => 'ExpYear',
        PAY1_IDLANGUAGE        => 'Language',
        PAY1_SHOPTRANSACTIONID => 'ShopTransactionID',
        PAY1_TRANSACTIONRESULT => 'TransactionResult',
        PAY1_UICCODE           => 'Currency',
        PAY1_VBV               => 'VBV', #add 0.30
        PAY1_VBVRISP           => 'VBVrisp', #add 0.30
    );
    foreach my $field ( keys %fields ) {
        if ( $self->{'Decripted'} =~ s/(^|\*P1\*)$field=(.*?)(\*P1\*|$)/$1 && $3 ? '*P1*' : ''/e ) {
            $self->{$fields{$field}} = $2;
        }
    }
    $self->{'CustomInfo'} = trim($self->{'Decripted'});
    return 1;
}

sub query_server {
    my $self = shift;

    my $type = $self->{'ToBeEncript'} ne '' ? 'encrypt' : 'decrypt';
    my $urlString = $type eq 'encrypt'
#        ? "$self->{'ScriptEncrypt'}?a=$self->{'ShopLogin'}&b=$self->{'ToBeEncript'}"
#        : "$self->{'ScriptDecrypt'}?a=$self->{'ShopLogin'}&b=$self->{'EncryptedString'}";
        ? "$self->{'ScriptEncrypt'}?a=$self->{'ShopLogin'}&b=$self->{'ToBeEncript'}&c=2.0" # set 0.30
        : "$self->{'ScriptDecrypt'}?a=$self->{'ShopLogin'}&b=$self->{'EncryptedString'}&c=2.0";
           
    my $response = $self->cat_server($urlString);
    return 0 if $response eq '';

    if ( $type eq 'encrypt' && $response =~ /#cryptstring#(.*?)#\/cryptstring#/ ) {
        $self->{'EncryptedString'} = $1 if ( $1 ne '' );
    }
    if ( $type eq 'decrypt' && $response =~ /#decryptstring#(.*?)#\/decryptstring#/ ) {
        $self->{'Decripted'} = $1 if ( $1 ne '' );
    }
    if ( $response =~ /#error#(.*?)-(.*?)#\/error#/ ) {
        close(Server);
        $self->{'ErrorCode'} = $1;
        $self->{'ErrorDescription'} = $2;
        return 0;
    }

    close(Server);
    return 1;
}

sub cat_server {
    my ($self,$request) = @_;

    my $response = '';

    unless ( socket(Server,PF_INET,SOCK_STREAM,getprotobyname('tcp')) ) {
         $self->{'ErrorCode'} = '9999';
         $self->{'ErrorDescription'} = "Unable to open a socket: $!";
         return;
    }

    my $ip_addr = inet_aton($self->{'DomainName'});
    unless ( defined $ip_addr ) {
        $self->{'ErrorCode'} = '9999';
        $self->{'ErrorDescription'} = "The name of GestPay server is unknown: $!";
        return;
    }

    unless ( connect(Server,sockaddr_in(80,$ip_addr)) ) {
        $self->{'ErrorCode'} = '9999';
        $self->{'ErrorDescription'} = "Unable to connect to GestPay server: $!";
        return;
    }

    # enable command buffering
    select((select(Server),$|=1)[0]);

    # send the request
    unless ( print Server "GET $request HTTP/1.0\r\n\r\n" ) {
        close(Server);
        $self->{'ErrorCode'} = '9999';
        $self->{'ErrorDescription'} = "Unable to send the request to GestPay server: $!";
        return;
    }

    # get the response
    my $buffer;
    while ( read(Server,$buffer,4096) ) {
        $response .= $buffer;
    }
    if ( $response eq '' || $! ) {
        close(Server);
        $self->{'ErrorCode'} = '9999';
        $self->{'ErrorDescription'} = "Unable to get the response from GestPay server: $!";
        return;
    }

    # close the connection
    close(Server);

    return $response;
}

# add 0.30
sub trim {
    my $string = shift;
    $string =~ s/^ +//;
    $string =~ s/ +$//;
    return $string;
}

# add 0.30
my %escape;
for my $char ( 0..255 ) {
    $escape{chr($char)} = sprintf("%%%02X",$char);
}

# add 0.30
sub url_encode {
    my $string = shift;
    $string =~ s/([^A-Za-z0-9\-_.* ])/$escape{$1}/g;
    $string =~ tr/ /+/;
    return $string;
}

# add 0.300
sub url_decode {
    my $string = shift;
    $string =~ tr/+/ /;
    $string =~ s/%([0-9a-fA-F]{2})/chr(hex($1))/eg;
    return $string;
}

sub DESTROY { } # add 0.40

=head1 AUTHOR

  Marco Gazerro <gazerro@open2b.com>

=head1 SEE ALSO

  Business::GestPayCryptHS
  Business::BancaSella

=head1 COPYRIGHT

  Copyright (c) 2002-2004 Open2b Software S.r.l. ( www.open2b.com )

=head1 LICENSE

  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
