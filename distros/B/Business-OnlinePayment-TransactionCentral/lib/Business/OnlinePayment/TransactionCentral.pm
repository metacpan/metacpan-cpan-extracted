package Business::OnlinePayment::TransactionCentral;

use 5.005;
use strict;
use Carp;
use Business::OnlinePayment 3;
use Business::OnlinePayment::HTTPS 0.02;
use vars qw($VERSION @ISA $DEBUG);

@ISA = qw(Business::OnlinePayment::HTTPS);
$VERSION = '0.06';
$DEBUG = 0;

sub set_defaults {
    my $self = shift;

    $self->server('webservices.primerchants.com');
    $self->port('443');
    $self->path('/billing/TransactionCentral/');

    $self->build_subs(qw( order_number avs_code cvv2_response
                          response_page response_code response_headers
                     ));
}

sub submit {
  my($self) = @_;

  $self->revmap_fields(
    'MerchantID'    => 'login',
    'RegKey'        => 'password',
    'Amount'        => 'amount',
#    'CreditAmount'  => 'amount',
    'AccountNo'     => 'card_number',
    'NameonAccount' => 'name',
    'AVSADDR'       => 'address',
    'AVSZIP'        => 'zip',
    'Email'         => 'email',
    'CCRURL'        => \'',
    'CVV2'          => 'cvv2',
    'TransID'       => 'order_number',
    'TRANSROUTE'    => 'routing_code',
  );

  #XXX also set required fields here...

  my @required_fields = qw(login password);
  my %content = $self->content();
  my $action = $content{'action'};
  my $url = $self->path;
  if (
    $content{'type'} =~ /^(cc|visa|mastercard|american express|discover)$/i
  ) {

    if ( $action =~ /^\s*normal\s*authorization\s*$/i ) {
      $url .= 'processCC.asp';

      #REFID
      $content{'REFID'} = int(rand(2**31));

      #CCMonth & CCYear
      $content{'expiration'} =~ /^(\d+)\D+\d*(\d{2})$/
        or croak "unparsable expiration ". $content{'expiration'};
      my( $month, $year ) = ( $1, $2 );
      $month = '0'. $month if $month =~ /^\d$/;
      $content{'CCMonth'} = $month;
      $content{'CCYear'} = $year;

      push @required_fields, qw( amount card_number expiration
                                 name address zip
                               );

    } elsif ( $action =~ /^\s*authorization\s*only\s*$/i ) {
      croak "Authorizaiton Only is not supported by Transaction Central";
    } elsif ( $action =~ /^\s*post\s*authorization\s*$/i ) {
      croak "Post Authorizaiton is not supported by Transaction Central";
    } elsif ( $action =~ /^\s*(void|credit)\s*$/i ) {
      $url .= 'voidcreditcconline.asp';

      $content{'CreditAmount'} = delete $content{'Amount'};

    } else {
      croak "Unknown action $action";
    }

  } elsif ( $content{'type'} =~ /^e?check$/i ) {

    if ( $action =~ /^\s*normal\s*authorization\s*$/i ) {
      $url .= 'processcheckonline.asp';
      $content{'AccountNo'} = $content{'account_number'};
      $content{'TRANSTYPE'} =
        ( exists($content{account_type}) && $content{account_type} =~ /^s/i )
        ? 'SA'
        : 'CK';

      push @required_fields, qw( amount account_number routing_code
                                 name
                               );

    } elsif ( $action =~ /^\s*authorization\s*only\s*$/i ) {
      croak "Authorizaiton Only is not supported by Transaction Central";
    } elsif ( $action =~ /^\s*post\s*authorization\s*$/i ) {
      croak "Post Authorizaiton is not supported by Transaction Central";
    } elsif ( $action =~ /^\s*(void|credit)\s*$/i ) {
      $url .= 'addckcreditupdtonline.asp';
    } else {
      croak "Unknown action $action";
    }

  } else {
    croak 'Unknown type: '. $content{'type'};
  }
  $self->path($url);
  $self->content(%content);

  $self->required_fields(@required_fields);

  my @fields = qw(
    MerchantID RegKey Amount REFID AccountNo CCMonth CCYear NameonAccount
    AVSADDR AVSZIP CCRURL CVV2 USER1 USER2 USER3 USER4 TrackData
    TransID CreditAmount
    DESCRIPTION DESCDATE TRANSTYPE TRANSROUTE
  );

  my( $page, $response, %reply_headers ) =
    $self->https_post( $self->get_fields( @fields ) );

  $self->response_code( $response );
  $self->response_page( $page );
  $self->response_headers( \%reply_headers );

  #trim off <html><body> </body></html> around the response we want
  $page =~ s/^[\s\n]*<html>[\s\n]*<body>[\s\n]*//;
  $page =~ s/[\s\n]*<\/body>[\s\n]*<\/html>[\s\n]*$//;

  my %return = map { /^(\w+)=(.*)$/ ? ( $1 => $2 ) : () } split(/&/, $page);

  if ( $DEBUG ) { warn "$_ => $return{$_}\n" foreach keys %return; }

  #$self->result_code(   $return{'AVSCode'} );
  $self->avs_code(      $return{'AVSCode'} );
  $self->cvv2_response( $return{'CVV2ResponseMsg'} );

  if ( $return{'Auth'} =~ /^\s*(\w+)\s*$/ && lc($1) ne 'declined' ) {

    $self->is_success(1);
    $self->authorization( $return{'Auth'}   );
    $self->order_number(  $return{'TransID'} );

  } else {

    $self->is_success(0);
    $self->error_message( $return{'Notes'} );

  }

}

sub revmap_fields {
    my($self, %map) = @_;
    my %content = $self->content();
    foreach(keys %map) {
#    warn "$_ = ". ( ref($map{$_})
#                         ? ${ $map{$_} }
#                         : $content{$map{$_}} ). "\n";
        $content{$_} = ref($map{$_})
                         ? ${ $map{$_} }
                         : $content{$map{$_}};
    }
    $self->content(%content);
}

1;

__END__

=head1 NAME

Business::OnlinePayment::TransactionCentral - Transaction Central backend module for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = new Business::OnlinePayment("TransactionCentral");
  $tx->content(
      type           => 'CC',
      login          => '10011', #MerchantID
      password       => 'KK48NPYEJHMAH6DK', #Regkey
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      phone          => '420-867-5309',
      email          => 'tofu.beast@example.com',
      card_number    => '4012000000001',
      expiration     => '08/06',
      cvv2           => '1234', #optional
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }
=head1 DESCRIPTION

This is a Business::OnlinePayment backend module for the Transaction Central
(MerchantAnywhere, PRIMerchants) gateway.  It is only useful if you have a
merchant account with MerchantAnywhere / PRIMerchants:

http://www.merchantanywhere.com/
http://www.merchantanywhere.com/ecshop/TC_elink.htm

http://www.primerchants.com/
http://www.primerchants.com/info/transactioncentral.asp

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, password, action, amount, card_number, expiration, name, address, zip.

=head2 ECHECK

Content required: type, login, password, action, amount, account_number, routing_code, name

=head1 PREREQUISITES

  URI::Escape

  Net::SSLeay _or_ ( Crypt::SSLeay and LWP )

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

The newest publicly available documentation is available at:

http://www.merchantanywhere.com/ecshop/TC%20Interface%20NEW.pdf

It is somewhat out-of-date and contains a few discrepancies.  Google
"TCInterfaceGuide" for current documentation.

=head1 AUTHOR

Ivan Kohler <ivan-transactioncentral@420.am>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Ivan Kohler
Copyright (C) 2007 Freeside Internet Services, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut
