package Business::OnlinePayment::BankOfAmerica;

# $Id: BankOfAmerica.pm,v 1.3 2002/11/19 23:41:24 ivan Exp $

use strict;
use Carp qw(croak);
use Business::OnlinePayment;
use Net::SSLeay qw/make_form post_https make_headers/;
#use Text::CSV;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader Business::OnlinePayment);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '1.02';

sub set_defaults {
    my $self = shift;

    $self->server('cart.bamart.com');
    $self->port('443');

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

sub get_fields {
    my($self,@fields) = @_;

    my %content = $self->content();
    my %new = ();
    foreach( grep defined $content{$_}, @fields) { $new{$_} = $content{$_}; }
    return %new;
}

sub order_number {
    my $self = shift;
    if (@_) {
      $self->{order_number} = shift;
    }
    return $self->{order_number};
}

sub submit {
    my($self) = @_;

    my %content = $self->content;

    my $action = lc($content{'action'});

    die 'Normal Authorization not supported'
      if $action eq 'normal authorization';

    my @fields;
    my $ioc_indicator = '';

    if ( $action eq 'authorization only' ) {
      $self->path('/payment.mart');
      @fields = qw(
          ioc_merchant_id ioc_order_total_amount ioc_merchant_shopper_id
          ioc_merchant_order_id ecom_billto_postal_name_first
          ecom_billto_postal_name_last ecom_billto_postal_street_line1
          ecom_billto_postal_street_line2 ecom_billto_postal_city
          ecom_billto_postal_stateprov ecom_billto_postal_postalcode
          ecom_billto_postal_countrycode ecom_billto_telecom_phone_number
          ecom_billto_online_email ecom_payment_card_name
          ecom_payment_card_number ecom_payment_card_expdate_month
          ecom_payment_card_expdate_year
      );
    } elsif ( $action eq 'credit' ) {
      $self->path('/Settlement.mart');
      $ioc_indicator = 'R';
      @fields = qw(
          ioc_handshake_id ioc_merchant_id ioc_user_name ioc_password
          ioc_order_number ioc_indicator ioc_settlement_amount
          ioc_authorization_code ioc_email_flag
      );
      #    ioc_email_flag ioc_close_flag ioc_invoice_notes ioc_email_notes_flag
    } elsif ( $action eq 'post authorization' ) {
      $self->path('/Settlement.mart');
      $ioc_indicator = 'S';
      @fields = qw(
          ioc_handshake_id ioc_merchant_id ioc_user_name ioc_password
          ioc_order_number ioc_indicator ioc_settlement_amount
          ioc_authorization_code ioc_email_flag
      );
      #    ioc_email_flag ioc_close_flag ioc_invoice_notes ioc_email_notes_flag
    } else {
      die "unknown action $action";
    }

#        $self->required_fields(qw/type login password action amount last_name
#                                  first_name card_number expiration/);

    my($month, $year);
    unless ( $action eq 'post authorization' ) {

        if (  $self->transaction_type() =~
                /^(cc|visa|mastercard|american express|discover)$/i
           ) {
        } else {
            Carp::croak("BankOfAmerica can't handle transaction type: ".
                        $self->transaction_type());
        }

      $content{'expiration'} =~ /^(\d+)\D+(\d+)$/
        or croak "unparsable expiration $content{expiration}";

      ( $month, $year ) = ( $1, $2 );
      $year += 2000 if $year < 2000; #not y4k safe, oh shit

    }

    $self->revmap_fields(
        ioc_merchant_id                  => \($self->merchant_id()),
        ioc_user_name                    => 'login',
        ioc_password                     => 'password',
        ioc_invoice_notes                => 'description',
        ioc_order_total_amount           => 'amount',
        ioc_settlement_amount            => 'amount',
        ioc_merchant_order_id            => 'invoice_number',
        ioc_order_number                 => 'order_number',
        ioc_merchant_shopper_id          => 'customer_id',
        ecom_billto_postal_name_last     => 'last_name',
        ecom_billto_postal_name_first    => 'first_name',
        ecom_billto_postal_street_line1  => 'address',
#!!!        ecom_billto_postal_street_line2 => 'address',
        ecom_billto_postal_city          => 'city',
        ecom_billto_postal_stateprov     => 'state',
        ecom_billto_postal_postalcode    => 'zip',
        ecom_payment_card_number         => 'card_number',
        ecom_billto_postal_countrycode   => 'country',
        ecom_billto_telecom_phone_number => 'phone',
        ecom_billto_online_email         => 'email',

        ecom_payment_card_name =>
          \( $content{'name'} || "$content{first_name} $content{last_name}" ),

        ecom_payment_card_expdate_month => \$month,
        ecom_payment_card_expdate_year  => \$year,

        ioc_authorization_code           => 'authorization',
        ioc_indicator                    => \$ioc_indicator,
        ioc_handshake_id                 => 'order_number',
        ioc_email_flag                   => \'No',

    );

    my %post_data = $self->get_fields( @fields );

#    warn "$_ => $post_data{$_}\n" for keys %post_data;
#    warn "\n";
    my $pd = make_form(%post_data);
    my $s = $self->server();
    my $p = $self->port();
    my $t = $self->path();
    my $headers = make_headers('Referer' => $content{'referer'} )
      unless $action eq 'post authorization';
    my($page,$server_response,%headers) = post_https($s,$p,$t,$headers,$pd);

    my %response;
    if ( $action eq 'post authorization' ) {
#      warn $page;
      #$page =~ s/<HTML>.*//s;
      #$page =~ s/\n+$//g;
      $page =~ s/\r//g;
      %response =
        map { /^(\w+)\=(.*)$/ or /^()()$/ or die "unparsable response: $_";
              lc($1) => $2 }
          #split(/\r/, $page);
          split(/\n/, $page);
    } else {
      %response =
        map { /^(\w+)\=(.*)$/ or die "unparsable response: $_";
              lc($1) => $2 }
          split(/\<BR\>/i, $page);
    }

    #warn "$_ => $response{$_}\n" for keys %response;

    $self->server_response($page);

    if ( $response{'ioc_response_code'} eq '0' ) {
        $self->is_success(1);
        $self->result_code($response{'ioc_response_code'});
        $self->authorization($response{'ioc_authorization_code'});
        $self->order_number($response{'ioc_order_id'});
    } else {
        $self->is_success(0);
        $self->result_code($response{'ioc_response_code'});
        my $error =
          $action eq 'post authorization'
            ? $response{'ioc_response_desc'}
            : $response{'ioc_reject_description'};
        $error .= ': '. $response{'ioc_missing_fields'}
          if $response{'ioc_missing_fields'};
        $error .= ': '. $response{'ioc_invalid_fields'}
          if $response{'ioc_invalid_fields'};
        $self->error_message($error);
    }

}

1;
__END__

=head1 NAME

Business::OnlinePayment::BankOfAmerica - Bank of America backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment("BankOfAmerica", 'merchant_id' => 'YOURMERCHANTID');
  $tx->content(
      type           => 'VISA',
      action         => 'Authorization Only',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      invoice_number => '100100',
      customer_id    => 'jsk',
      first_name     => 'Jason',
      last_name      => 'Kohles',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      email          => 'ivan-bofa@420.am',
      card_number    => '4007000000027',
      expiration     => '09/99',
      referer        => 'http://cleanwhisker.420.am/',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

 if($tx->is_success()) {

      $auth = $tx->authorization;
      $ordernum = $tx->order_number;

      my $capture = new Business::OnlinePayment("BankOfAmerica", 'merchant_id' => 'YOURMERCHANTID' );

      $capture->content(
          action         => 'Post Authorization',
          login          => 'YOURLOGIN
          password       => 'YOURPASSWORD',
          order_number   => $ordernum,
          amount         => '0.01',
          authorization  => $auth,
          description    => 'Business::OnlinePayment::BankOfAmerica visa test',
      );

      $capture->submit();

      if($capture->is_success()) { 
          print "Card captured successfully: ".$capture->authorization."\n";
      } else {
          print "Card was rejected: ".$capture->error_message."\n";
      }

  }

=head1 SUPPORTED TRANSACTION TYPES

=head2 Visa, MasterCard, American Express, JCB, Discover/Novus, Carte blanche/Diners Club

Content required for `Authorization Only': type, action, amount,
invoice_number, customer_id, first_name, last_name, address, city, state, zip,
email, card_number, expiration, referer

Content required for `Post Authorization': action, login, password,
order_number, amount, authorization, description

`Normal Authorization' is not supported by the Bank of America gateway.

`Credit' is untested.

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 NOTE

Unlike Business::OnlinePayment or early verisons of
Business::OnlinePayment::AuthorizeNet, Business::OnlinePayment::BankOfAmerica
requires separate I<first_name> and I<last_name> fields.

An additional I<name> field is optional.  By default the I<first_name> and
I<last_name> fields will be concatenated.

=head1 NOTE

Business::OnlinePayment::BankOfAmerica does not support the
B<Normal Authorization> mode which combines authorization and capture into a
single tranaction.  You must use the B<Authorization Only> mode followed by the
B<Post Authorization> mode.  The B<Credit> mode is supported.

=head1 COMPATIBILITY

This module implements the interface documented at
http://www.bankofamerica.com/merchantservices/index.cfm?template=merch_ic_estores_developer.cfm

The settlement API is documented at
https://manager.bamart.com/welcome/SettlementAPI.pdf

=head1 BUGS

No login and password are required for B<Authorization Only> mode.  Access
is restricted only by the merchant id (available in any public store webpage
which passes off to the backend system) and HTTP referer header.

There is no way to run test transactions against the settlement API.

=head1 AUTHOR

Ivan Kohler <ivan-bofa@420.am>

Based on Business::OnlinePayment::AuthorizeNet written by Jason Kohles.

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=cut

