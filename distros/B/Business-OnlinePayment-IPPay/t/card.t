#!/usr/bin/perl -w

use Test::More;
require "t/lib/test_account.pl";

my($login, $password, %opt) = test_account_or_skip('card');
plan tests => 50;
  
use_ok 'Business::OnlinePayment';

my %content = (
    type           => 'VISA',
    login          => $login,
    password       => $password,
    action         => 'Normal Authorization',
    description    => 'Business::OnlinePayment visa test',
#    card_number    => '4007000000027',
    card_number    => '4111111111111111',
    cvv2           => '123',
    expiration     => expiration_date(),
    amount         => '49.95',
    name           => 'Tofu Beast',
    email          => 'ippay@weasellips.com',
    address        => '123 Anystreet',
    city           => 'Anywhere',
    state          => 'UT',
    zip            => '84058',
    country        => 'US',      # will be forced to USA
    customer_id    => 'tfb',
);

my $voidable;
my $voidable_auth;
my $voidable_amount = 0;

# valid card number test
{
  my $tx = Business::OnlinePayment->new("IPPay", %opt);
  $tx->content(%content);
  tx_check(
    $tx,
    desc          => "valid card_number",
    is_success    => 1,
    result_code   => '000',
    error_message => 'APPROVED',
    authorization => qr/TEST\d{2}/,
#    avs_code      => 'U',          # so rather pointless :\
    avs_code      => 'Y',          # so very pointless :\
    cvv2_response => 'P',          # ...
  );
  $voidable = $tx->order_number if $tx->is_success;
  $voidable_auth = $tx->authorization if $tx->is_success;
  $voidable_amount = $content{amount} if $tx->is_success;
}

# invalid card number test
{
  my $tx = Business::OnlinePayment->new("IPPay", %opt);
  $tx->content(%content, card_number => "4111111111111112" );
  tx_check(
    $tx,
    desc          => "invalid card_number",
    is_success    => 0,
    result_code   => '900', #'912' with old jetpay gw
    error_message => 'Invalid card number.  ', #'INVALID CARD NUMBER' w/old gw
    authorization => qr/^$/,
    avs_code      => '',           # so rather pointless :\
    cvv2_response => '',           # ...
  );
}

# authorization only test
{
  my $tx = Business::OnlinePayment->new("IPPay", %opt);
  $tx->content(%content, action => 'authorization only',  amount => '3.00' );
  tx_check(
    $tx,
    desc          => "authorization only",
    is_success    => 1,
    result_code   => '000',
    error_message => 'APPROVED',
    authorization => qr/TEST\d{2}/,
#    avs_code      => 'U',          # so rather pointless :\
    avs_code      => 'Y',          # so very pointless :\
    cvv2_response => 'P',          # ...
  );
  $postable = $tx->order_number if $tx->is_success;
  $postable_auth = $tx->authorization if $tx->is_success;
  $postable_amount = $content{amount} if $tx->is_success;
}

# authorization void test
SKIP: {
  #XXX void is returning "The transaction type is not a valid transaction type."
  # with current IPPay.  did something change about the API, is this broken?
  skip 'Reverse Authorization not currently working (against test account?)', 7;

  my $tx = Business::OnlinePayment->new("IPPay", %opt);
  $tx->content(%content, action => 'authorization only',  amount => '3.00' );
  $tx->test_transaction(1);
  $tx->submit;

  if ($tx->is_success) {
    my $void_tx = Business::OnlinePayment->new("IPPay", %opt );

    $tx->content(%content, action       => 'reverse authorization',
                           order_number => $tx->order_number );
    tx_check(
      $tx,
      desc          => "reverse authorization",
      is_success    => 1,
      result_code   => '000',
      error_message => 'APPROVED',
      authorization => qr/TEST\d{2}/,
      avs_code      => '',          # so rather pointless :\
      cvv2_response => '',          # ...
    );
  }
  else {
    
  }
}

# post authorization test
SKIP: {
  my $tx = new Business::OnlinePayment( "IPPay", %opt );
  $tx->content( %content, 'action'       => "post authorization", 
                          'amount'       => $postable_amount,    # not required
                          'order_number' => $postable,
              );
  tx_check(
    $tx,
    desc          => "post authorization",
    is_success    => 1,
    result_code   => '000',
    error_message => 'APPROVED',
    authorization => qr/^$postable_auth$/,
    avs_code      => '',
    cvv2_response => '',
    );
}

# void test
SKIP: {
  my $tx = new Business::OnlinePayment( "IPPay", %opt );
  $tx->content( %content, 'action' => "Void",
                          'order_number' => $voidable,
                          'authorization' => $voidable_auth,
              );
  tx_check(
    $tx,
    desc          => "void",
    is_success    => 1,
    result_code   => '000',
    error_message => 'VOID PROCESSED',
    authorization => qr/^$voidable_auth$/,
    avs_code      => '',
    cvv2_response => '',
    );
}

# credit test
SKIP: {
  my $tx = new Business::OnlinePayment( "IPPay", %opt );
  $tx->content( %content, 'action' => "credit");
  tx_check(
    $tx,
    desc          => "credit",
    is_success    => 1,
    result_code   => '000',
    error_message => 'RETURN ACCEPTED',
    authorization => qr/\d{6}/,
    avs_code      => '',
    cvv2_response => '',
    );
}


sub tx_check {
    my $tx = shift;
    my %o  = @_;

    $tx->test_transaction(1);
    $tx->submit;

    is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
    is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
    is( $tx->error_message, $o{error_message}, "error_message() / RESPMSG" );
    like( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
    is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
    is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
    like( $tx->order_number, qr/^\w{18}/, "order_number() / PNREF" );
}

sub tx_info {
    my $tx = shift;

    no warnings 'uninitialized';

    return (
        join( "",
            "is_success(",     $tx->is_success,    ")",
            " order_number(",  $tx->order_number,  ")",
            " error_message(", $tx->error_message, ")",
            " result_code(",   $tx->result_code,   ")",
            " auth_info(",     $tx->authorization, ")",
            " avs_code(",      $tx->avs_code,      ")",
            " cvv2_response(", $tx->cvv2_response, ")",
        )
    );
}

