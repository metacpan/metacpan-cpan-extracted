#!/usr/bin/perl -w

use Test::More;
require "t/lib/test_account.pl";

my($login, $password, %opt) = test_account_or_skip('check');
plan tests => 11;

use_ok 'Business::OnlinePayment';

my %content = (
    type           => 'CHECK',
    login          => $login,
    password       => $password,
    action         => 'Normal Authorization',
    amount         => '49.95',
    customer_id    => 'jsk',
    name           => 'Tofu Beast',
    account_number => '12345',
    routing_code   => '111000025',  # BoA in Texas taken from Wikipedia
    bank_name      => 'First National Test Bank',
    account_type   => 'Business Checking',
);

my $voidable;

#check test
{
  my $ctx = Business::OnlinePayment->new("IPPay", %opt);
  $ctx->content(%content);
  tx_check(
    $ctx,
    desc          => 'normal ACH transaction',
    is_success    => 1,
    result_code   => '000',
    error_message => 'CHECK ACCEPTED',
    authorization => qr/^000000$/,
    name          => 'Tofu Beast',
  );
  $voidable = $ctx->order_number if $ctx->is_success;
}

#VOIDACH transactions are no longer supported.  Please contact support@ippay.com for questions.
##check void test
#{
#  my $ctx = Business::OnlinePayment->new("IPPay", %opt);
#  $ctx->content(%content, action => 'void', order_number => $voidable);
#  tx_check(
#    $ctx,
#    desc          => 'ACH void transaction',
#    is_success    => 1,
#    result_code   => '000',
#    error_message => 'CHECK ACCEPTED',
#    authorization => qr/^000000$/,
#  );
#}

#check credit test
{
  my $ctx = Business::OnlinePayment->new("IPPay", %opt);
  $ctx->content(%content, action => 'credit');
  tx_check(
    $ctx,
    desc          => 'ACH credit transaction',
    is_success    => 1,
    result_code   => '000',
    error_message => 'CHECK ACCEPTED',
    authorization => qr/^000000$/,
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
        )
    );
}

