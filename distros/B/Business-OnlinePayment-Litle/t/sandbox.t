#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More qw(no_plan);
use Test::MockObject::Extends;

## grab info from the ENV
my $login = $ENV{'BOP_USERNAME'} ? $ENV{'BOP_USERNAME'} : 'TESTMERCHANT';
my $password = $ENV{'BOP_PASSWORD'} ? $ENV{'BOP_PASSWORD'} : 'TESTPASS';
my $merchantid = $ENV{'BOP_MERCHANTID'} ? $ENV{'BOP_MERCHANTID'} : 'TESTMERCHANTID';
my @opts = ('default_Origin' => 'RECURRING' );

use_ok 'Business::OnlinePayment';

my %orig_content = (
    type           => 'CC',
    login          => $login,
    password       => $password,
    merchantid     =>  $merchantid,
    action         => 'Authorization Only', #'Normal Authorization',
    description    => 'BLU*BusinessOnlinePayment',
    affiliate      => '123',
    recycle_by     => 'Merchant',
    recycle_id     => '1',
#    card_number    => '4007000000027',
    card_number    => '4457010000000009',
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
    company_phone  => '801.123-4567',
    url            =>  'support.foo.com',
    invoice_number => '1234',
    ip             =>  '127.0.0.1',
    ship_name      =>  'Tofu Beast, Co.',
    ship_address   =>  '123 Anystreet',
    ship_city      => 'Anywhere',
    ship_state     => 'UT',
    ship_zip       => '84058',
    ship_country   => 'US',      # will be forced to USA
    tax            => 0,
    products        =>  [
    {   description =>  'First Product',
        quantity    =>  1,
        units       =>  'Months',
        amount      =>  500,
        discount    =>  0,
        code        =>  1,
        cost        =>  500,
        tax         =>  0,
        totalwithtax => 500,
    },
    {   description =>  'Second Product',
        quantity    =>  1,
        units       =>  'Months',
        amount      =>  1500,
        discount    =>  0,
        code        =>  2,
        cost        =>  500,
        tax         =>  0,
        totalwithtax => 1500,
    }

    ],
);

my $tx = Business::OnlinePayment->new("Litle", @opts);
my %content = %orig_content;
$tx->content(%content);
tx_check(
	$tx,
	desc          => "Auth Only",
	is_success    => '1',
	result_code   => '000',
	error_message => 'Approved',
	approved_amount => undef,
);

{
    my $tx_dupe = Business::OnlinePayment->new("Litle", @opts);
    $tx_dupe = Test::MockObject::Extends->new($tx_dupe);
    $tx_dupe->mock('https_post', sub {
        return ("<litleOnlineResponse version='8.17' response='0' message='Valid Format' xmlns='http://www.litle.com/schema'>
    <saleResponse id='1234' reportGroup='BOP' customerId='tfb' duplicate='true'>
        <litleTxnId>898289134615584000</litleTxnId>
        <orderId>1234</orderId>
        <response>000</response>
        <responseTime>2013-04-23T14:41:51</responseTime>
        <message>Approved</message>
        <authCode>65099</authCode>
    </saleResponse>
</litleOnlineResponse>", '200', ());
    });
    %content = %orig_content;
    $content{'action'} = 'Normal Authorization';
    $tx_dupe->content(%content);
    tx_check(
        $tx_dupe,
        desc          => "Normal Auth",
        is_success    => '1',
        result_code   => '000',
        error_message => 'Approved',
        approved_amount => undef,
        is_duplicate => 1,
    );
}
{
    my $tx_token = Business::OnlinePayment->new("Litle", @opts);
    $tx_token = Test::MockObject::Extends->new($tx_token);
    $tx_token->mock('https_post', sub {
        return ("<litleOnlineResponse version='8.17' response='0' message='Valid Format' xmlns='http://www.litle.com/schema'>
    <saleResponse id='1234' reportGroup='BOP' customerId='tfb' duplicate='true'>
        <litleTxnId>898289134615584000</litleTxnId>
        <orderId>1234</orderId>
        <response>000</response>
        <responseTime>2013-04-23T14:41:51</responseTime>
        <message>Approved</message>
        <authCode>65099</authCode>
        <tokenResponse>
            <litleToken>99999</litleToken>
            <tokenResponseCode>999</tokenResponseCode>
            <tokenMessage>Wrong!</tokenMessage>
        </tokenResponse>
    </saleResponse>
</litleOnlineResponse>", '200', ());
    });
    %content = %orig_content;
    $content{'action'} = 'Normal Authorization';
    $tx_token->content(%content);
    tx_check(
        $tx_token,
        desc          => "Normal Auth",
        is_success    => '1',
        result_code   => '000',
        error_message => 'Approved',
        approved_amount => undef,
        is_duplicate => 1,
        card_token => '99999',
        card_token_response => '999',
        card_token_message => 'Wrong!'
    );
}

$orig_content{'action'} = 'Normal Authorization';
%content = %orig_content;
$tx->content(%content);
tx_check(
	$tx,
	desc          => "Normal Auth",
	is_success    => '1',
	result_code   => '000',
	error_message => 'Approved',
	approved_amount => undef,
);

$orig_content{'action'} = 'Normal Authorization';
%content = %orig_content;
$content{'card_number'} = '';
$content{'card_token'} = '0000000000000';
$tx->content(%content);
tx_check(
	$tx,
	desc          => "Normal Auth",
	is_success    => '1',
	result_code   => '000',
	error_message => 'Approved',
	approved_amount => undef,
);

$orig_content{'action'} = 'Normal Authorization';
%content = %orig_content;
$content{'card_number'} = '';
$content{'card_token'} = '';
$tx->content(%content);
$tx->test_transaction('sandbox');
eval {
    $tx->submit;
};
like( $@ , qr/missing card_token or card_number/, 'Check for missing card_token or card_number error' );

sub tx_check {
    my $tx = shift;
    my %o  = @_;

    SKIP: {
        $tx->test_transaction('sandbox');
        eval { $tx->submit; };
        skip $@, 1 if $@ =~ /503/i; # 503 Service Temporarily Unavailable

        is( $tx->is_success,    $o{is_success},    "$o{desc}: " . tx_info($tx) );
        is( $tx->result_code,   $o{result_code},   "result_code(): RESULT" );
        is( $tx->error_message, $o{error_message}, "error_message() / RESPMSG" );
        if( $o{authorization} ){
            is( $tx->authorization, $o{authorization}, "authorization() / AUTHCODE" );
        }
        if( $o{avs_code} ){
            is( $tx->avs_code,  $o{avs_code},  "avs_code() / AVSADDR and AVSZIP" );
        }
        if( $o{cvv2_response} ){
            is( $tx->cvv2_response, $o{cvv2_response}, "cvv2_response() / CVV2MATCH" );
        }
        if( defined $o{is_duplicate} ){
            is( $tx->is_duplicate, $o{is_duplicate}, "is_duplicate() / " . $o{is_duplicate} );
        }
        foreach my $field (qw/card_token card_token_response card_token_message/) {
            if( defined $o{$field} ) {
                is( $tx->$field, $o{$field}, "$field() / " . $o{$field} );
            }
        }
        if( $o{approved_amount} ){
            is( $tx->{_response}->{approvedAmount}, $o{approved_amount}, "approved_amount() / Partial Approval Amount" );
        }
        like( $tx->order_number, qr/^\w{5,19}/, "order_number() / PNREF" );
    }; # END SKIP
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
            " is_duplicate(",  $tx->is_duplicate,  ")",
        )
    );
}

sub expiration_date {
    my($month, $year) = (localtime)[4,5];
    $year++;       # So we expire next year.
    $year %= 100;  # y2k?  What's that?

    return sprintf("%02d%02d", $month, $year);
}
