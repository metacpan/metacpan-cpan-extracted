# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl eWay.t'

use Test;
require "t/lib/test_account.pl";

BEGIN { plan tests => 404 };
use Business::OnlinePayment::USAePay;

my %auth = test_account();

# a test transaction
my ($tx, $txnum, $res);
ok($tx = new Business::OnlinePayment("USAePay"));
$tx->test_transaction(2);
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4005562233445564',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($res = $tx->server_response());
ok($txnum = $res->{UMauthCode});
ok($res->{UMavsResultCode}, "YYY");
ok($res->{UMresult}, "A");
ok($res->{UMcvv2Result}, "Not Processed");
ok($res->{UMversion}, "2.9");
ok($res->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($res->{UMrefNum}, qr/^\d+/);
ok($res->{UMbatch}, qr/^\d+/);
ok($res->{UMerrorcode}, "00000");
ok($res->{UMvpasResultCode}, "");
ok($res->{UMcvv2ResultCode}, "P");

#resubmit test
ok($tx->submit());
ok(($tx->server_response->{UMauthCode} - $txnum) > 0);

# a test transaction with cvn
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4005562233445564',
        expiration     => expiration_date(),
	cvv2           => '123',
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMcvv2Result}, "No Match"); #"Not Processed");

# a failing transaction
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        first_name     => 'Tofu',
        last_name      => 'Beast',
        email          => 'tofu@example.com',
        address        => '1234 Bean Curd Lane, Sydney',
        zip            => '2034',
        card_number    => '4646464646464646',
        expiration     => expiration_date(),
	cvv2           => '123',
    )
);

#ok($tx->test_transaction(0),0);
ok($tx->test_transaction(2),2);

ok($tx->submit());
ok($tx->is_success(),0);
ok($tx->error_message(), 'Invalid Card Number (3)');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMcvv2Result}, "No CVV2/CVC data available for transaction.");

#various test cards; semi-useful testing
#Full match avs, zip9 & cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100011112224',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);

#Full match avs, zip9 & cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100111112223',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYX");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 9 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

#no match avs, match zip5 & cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100211112222',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "NYZ");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: No Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# no match address, match zip9 & cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100311112221',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "NYW");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: No Match & 9 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# match address, no match zip5 & match cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100411112220',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YNA");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: No Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# no match address, zip5 & match cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100511112229',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "NNN");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: No Match & 5 Digit Zip: No Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# card number not on avs file
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100611112228',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "XXW");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Card Number Not On File");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# not verified
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100711112227',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "XXU");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address Information not verified for domestic transaction");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# retry avs   
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100811112226',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "XXR");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Retry / System Unavailable");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# avs not supported
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000100911112225',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "XXS");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Service Not Supported");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# avs not allowed for card type
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000101011112222',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "XXE");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address Verification Not Allowed For Card Type");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# global non-avs participant
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000101111112221',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "XXG");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Global Non-AVS participant");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# international address match, zip incompat
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000101211112220',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYG");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "International Address: Match & Postal: Not Compatible");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# international address match, zip 
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000101311112229',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "GGG");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "International Address: Match & Postal: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# international address Not compat & match, zip 
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000101411112228',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YGG");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "International Address: No Compatible & Postal: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# full match, avs & match, zip 
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000200011112222',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "M");

# match avs & no match cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000200111112221',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "No Match");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "N");

# match avs & not processed cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000200211112220',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Not Processed");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "P");

# match avs & fault in cvv2 database
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000200311112229',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success(),0);
ok($tx->error_message(), 'Card Declined (00)');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "D");
ok($tx->server_response->{UMcvv2Result}, "Should be on card but not so indicated");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "10127");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "S");

# match avs & issuer not certified for cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000200411112228',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "Issuer Not Certified");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "U");

# match avs & no response for cvv2
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000200511112227',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), 'Approved');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "A");
ok($tx->server_response->{UMcvv2Result}, "No response from association");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "X");

# hard decline
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000300011112220',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success(),0);
ok($tx->error_message(), 'Card Declined (00)');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "D");
ok($tx->server_response->{UMcvv2Result}, "No Match"); #"Not Processed");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "10127");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "N");

# referral
ok(
    $tx->content(
        type           => 'CC',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        card_number    => '4000300111112229',
        expiration     => expiration_date(),
        address        => '1234 Bean Curd Lane, San Francisco',
        zip            => '94102',
        cvv2           => '102',
    )
);
ok($tx->submit());
ok($tx->is_success(),0);
ok($tx->error_message(), 'Transaction Requires Voice Authentication. Please Call-In.');
ok($tx->authorization(), '/\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "YYY");
ok($tx->server_response->{UMresult}, "E");
ok($tx->server_response->{UMcvv2Result}, "No Match"); #"Not Processed");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "Address: Match & 5 Digit Zip: Match");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00043");
ok($tx->server_response->{UMbatch}, qr/^\d+/);
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "N");

# good check
ok(
    $tx->content(
        type           => 'ECHECK',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '49.95',
        invoice_number => '100100',
        name           => 'Tofu Beast',
        routing_code   => '400020001',
        account_number => '1112222',
        customer_ssn   => '999999999',
        address        => '1234 Bean Curd Lane, San Francisco',
    )
);
ok($tx->submit());
ok($tx->is_success());
ok($tx->error_message(), ''); #'Approved');
ok($tx->authorization(), '/^\w{6}/'); #\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "");
ok($tx->server_response->{UMresult}, "A"); #good check
ok($tx->server_response->{UMcvv2Result}, "No CVV2/CVC data available for transaction.");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "No AVS response (Typically no AVS data sent or swiped transaction)"); #"n/a");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "");


# bad check
ok(
    $tx->content(
        type           => 'ECHECK',
        %auth,
        action         => 'Normal Authorization',
        description    => 'Business::OnlinePayment test',
        amount         => '5.99', #5.99 	Decline 
        invoice_number => '100100',
        name           => 'Tofu Beast',
        routing_code   => '400020001',
        account_number => '1112222',
        customer_ssn   => '999999999',
        address        => '1234 Bean Curd Lane, San Francisco',
    )
);
ok($tx->submit());
ok($tx->is_success(),0); #393
ok($tx->error_message(), 'VC: Returned check for this account'); 
ok($tx->authorization(), '/^\w{6}/'); #\d{6}/');
ok($tx->server_response->{UMavsResultCode}, "");
ok($tx->server_response->{UMresult}, "D"); #bad check
ok($tx->server_response->{UMcvv2Result}, "No CVV2/CVC data available for transaction.");
ok($tx->server_response->{UMversion}, "2.9");
ok($tx->server_response->{UMavsResult}, "No AVS response (Typically no AVS data sent or swiped transaction)"); #"n/a");
ok($tx->server_response->{UMrefNum}, qr/^\d+/);
ok($tx->server_response->{UMerrorcode}, "00000");
ok($tx->server_response->{UMvpasResultCode}, "");
ok($tx->server_response->{UMcvv2ResultCode}, "");

