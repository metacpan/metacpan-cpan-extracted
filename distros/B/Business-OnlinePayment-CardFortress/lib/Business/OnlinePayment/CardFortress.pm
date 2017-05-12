package Business::OnlinePayment::CardFortress;

use base qw( Business::OnlinePayment::HTTPS );

use warnings;
use strict;
#use vars qw( $DEBUG $me );
use File::Slurp;
use MIME::Base64;
use Crypt::OpenSSL::RSA;

our $VERSION = '0.04';

sub _info {
  my $self = shift;

  my $info = {
    'info_compat'       => '0.01',
    'module_version'    => $VERSION,
    'gateway_name'      => 'Card Fortress',
    'gateway_url'       => 'http://www.cardfortress.com/',
    'supported_types'   => [ 'CC' ],
    'supported_actions' => { 'CC' => [
                                       'Normal Authorization',
                                       'Authorization Only',
                                       'Post Authorization',
                                       'Void',
                                       'Credit',
                                       'Tokenize',
                                     ],
                           },
    'token_support'     => 1,
  };

  my $cf_info = $self->cf_info;

  use Data::Dumper;
  warn Dumper($cf_info);

  $info->{$_} = $cf_info->{$_}
    for qw( CC_void_requires_card ECHECK_void_requires_account partial_auth );

  $info;
}

sub set_defaults {
  my $self = shift;
  my %opts = @_;
  
  $self->server('gw.cardfortress.com') unless $self->server;

  $self->port('443') unless $self->port;
  $self->path('/bop/index.html') unless $self->path;

  $self->build_subs(qw( order_number avs_code cvv2_response
                        response_page response_code response_headers
                        card_token private_key txn_date
                   ));
}

sub submit {
  my $self = shift;

  $self->server('test.cardfortress.com') if $self->test_transaction;

  my %content = $self->content;
  $content{$_} = $self->$_() for qw( gateway gateway_login gateway_password );

  $content{$_} = $self->$_() for grep $self->can($_), qw( bop_options );

  my ($page,$server_response,%headers) = $self->https_post(%content);

  die "$server_response\n" unless $server_response =~ /^200/;

  my %response = ();
  #this encoding good enough?  wfm... if something's easier for other
  #languages they can always use a different URL
  foreach my $line ( grep /^\w+=/, split(/\n/, $page) ) {
    $line =~ /^(\w+)=(.*)$/ or next;
    $response{$1} = $2;
  }

  foreach (qw( is_success error_message failure_status
               authorization order_number
               fraud_score fraud_transaction_id
               result_code avs_code cvv2_response
               card_token
               txn_date
             )) {
    $self->$_($response{$_});
  }

  #map these to gateway_response_code, etc?
  # response_code()
  # response_headers()
  # response_page()

  #handle the challenge/response handshake
  if ( $self->error_message eq '_challenge' ) { #XXX infinite loop protection?

    my $private_key = $self->private_key
      or die "no private key available";

    $private_key = read_file($private_key)
      if $private_key !~ /-----BEGIN/ && -r $private_key;

    #decrypt the challenge with the private key
    my $challenge = decode_base64($response{'card_challenge'});

    #here is the hardest part to implement at each client side
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($private_key);
    my $response = $rsa_priv->decrypt($challenge);

    #try the transaction again with the challenge response
    # (B:OP could sure use a better way to alter one value)
    my %content = $self->content;
    $content{'card_response'} = encode_base64($response, '');
    $self->content(%content);
    $self->submit;
  }

}

sub cf_info {
  my $self = shift;

  $self->server('test.cardfortress.com') if $self->test_transaction;

  my %content = ( 'gateway_info' => $self->gateway(), );

  my ($page,$server_response,%headers) = $self->https_post(%content);

  die "$server_response\n" unless $server_response =~ /^200/;

  my %response = ();
  #this encoding good enough?  wfm... if something's easier for other
  #languages they can always use a different URL
  foreach my $line ( grep /^\w+=/, split(/\n/, $page) ) {
    $line =~ /^(\w+)=(.*)$/ or next;
    $response{$1} = $2;
  }

  \%response;

}

1;

__END__

=head1 NAME

Business::OnlinePayment::CardFortress - CardFortress backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  my $tx = new Business::OnlinePayment(
    'CardFortress',
      'gateway'          => 'ProcessingGateway',
      'gateway_login'    => 'gwlogin',
      'gateway_password' => 'gwpass',
      #private_key not necessary
  );

  $tx->content(
      type           => 'VISA',
      login          => 'cardfortress_login',
      password       => 'cardfortress_pass',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      customer_id    => 'tfb',
      name           => 'Tofu Beast',
      address        => '123 Anystreet',
      city           => 'Anywhere',
      state          => 'UT',
      zip            => '84058',
      card_number    => '4007000000027',
      expiration     => '09/02',
      cvv2           => '1234', #optional (not stored)
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
      $token = $tx->card_token;
      print "Card token is: $token\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

  # ... time slips by ...

  my $rx = new Business::OnlinePayment(
    'CardFortress',
      'gateway'          => 'ProcessingGateway',
      'gateway_login'    => 'gwlogin',
      'gateway_password' => 'gwpass',
      'private_key'      => $private_key_string, #or filename
      'bop_options'      => join('/', map "$_=".$options{$_}, keys %options),
  );

  $rx->content(
      type           => 'VISA',
      login          => 'cardfortress_login',
      password       => 'cardfortress_pass',
      action         => 'Normal Authorization',
      description    => 'Business::OnlinePayment test',
      amount         => '49.95',
      card_token     => $card_token
      cvv2           => '1234', #optional, typically not necessary w/followup tx
  );
  $rx->submit();

=head1 DESCRIPTION

This is a Business::OnlinePayment backend module for the gateway-independent
CardFortress storage service (http://cardfortress.com/).

=head1 SUPPORTED TRANSACTION TYPES

=head2 CC, Visa, MasterCard, American Express, Discover

Content required: type, login, action, amount, card_number, expiration.

=head1 METHODS AND FUNCTIONS

See L<Business::OnlinePayment> for the complete list. The following methods either override the methods in L<Business::OnlinePayment> or provide additional functions.  

=head2 card_token

Returns the card token for any transaction.  The card token can be used in
a subsequent transaction as a replacement for the card number and expiration
(as well as customer/AVS data).

=head2 result_code

Returns the response error code.

=head2 error_message

Returns the response error description text.

=head2 server_response

Returns the complete response from the server.

=head1 AUTHOR

Ivan Kohler C<< <ivan-bop-cardfortress at freeside.biz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2016 Freeside Internet Services, Inc. (http://freeside.biz/)
All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
