use 5.010001;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use File::Spec;
use LWP::UserAgent;
use URI;
use POSIX qw/strftime/;


use Business::OnlinePayment::IPayment;
use Business::OnlinePayment::IPayment::Return;
use Business::OnlinePayment::IPayment::Response;

my $ua = LWP::UserAgent->new;
$ua->max_redirect(0);

plan tests => 79;



my %account = (
               accountid => 99999,
               trxuserid => 99998,
               trxpassword => 0,
               adminactionpassword => '5cfgRT34xsdedtFLdfHxj7tfwx24fe',
               app_security_key => 'testtest',
               wsdl_file => File::Spec->catfile("t", "ipayment.wsdl"),
               success_url => "http://linuxia.de/ipayment/success",
               failure_url => "http://linuxia.de/ipayment/failure",
              );

my $secbopi = Business::OnlinePayment::IPayment->new(%account);

my $amount = int(rand(5000)) * 100 + 2;

my $shopper_id = int(rand(5000));

$secbopi->transaction(transactionType => 'preauth',
                      trxAmount       => "$amount",
                      shopper_id      => $shopper_id);

my $response = $ua->post($secbopi->ipayment_cgi_location,
                      { ipayment_session_id => $secbopi->session_id,
                        addr_name => "Mario Pegula",
                        addr_street => "via del piffero 10",
                        addr_city => "Trieste",
                        addr_zip => "34100",
                        addr_country => "IT",
                        addr_telefon => "041-311234",
                        addr_email => 'melmothx@gmail.com',
                        silent => 1,
                        cc_number => "4111111111111111",
                        cc_checkcode => "",
                        cc_expdate_month => "02",
                        trx_securityhash => $secbopi->trx_securityhash,
                        cc_expdate_year => next_year() });

# ok($secbopi->debug->request->content, "We can inspect the SOAP request");

# print $secbopi->debug->response->content;

my $ipayres = $secbopi->get_response_obj($response->header('location'));

ok($ipayres->is_valid);
ok($ipayres->is_success);
is($ipayres->address_info, 'Mario Pegula via del piffero 10 34100 Trieste IT melmothx@gmail.com 041-311234',
   "Address OK: " . $ipayres->address_info);

diag $ipayres->ret_trx_number, " ", $ipayres->trx_amount, " ", $ipayres->trx_currency, "\n";

my $res = $secbopi->capture($ipayres->ret_trx_number, $amount - 200, "EUR",
                            { shopperId => $shopper_id });

ok($res->is_success, "Charging the amount minus 2 euros works");
is($res->status, "SUCCESS");
diag Dumper($secbopi->debug->request->content);
like($secbopi->debug->request->content,
     qr{<shopperId>\Q$shopper_id\E</shopperId}, "Shopper id passed");

is(ref($res->successDetails), "HASH");
diag Dumper($res->successDetails);
is($res->paymentMethod, "VisaCard", "Payment method ok");
is($res->trx_paymentmethod, "VisaCard", "Payment method ok (alternate)");
ok($res->trxRemoteIpCountry, "ip ok");
ok($res->trx_remoteip_country, "ip ok (alternate)");
is($res->trx_paymentdata_country, "US", "country ok");
is($res->trxPaymentDataCountry, "US", "country ok");
is($res->address_info, 'via del piffero 10 34100 Trieste IT melmothx@gmail.com 041-311234', "Address OK");
is(ref($res->addressData), "HASH");
ok($res->trx_timestamp, "timestamp ok: " . $res->trx_timestamp);
ok($res->ret_transtime =~ m/\d\d:\d\d:\d\d/, "time ok: " . $res->ret_transtime);
ok($res->ret_transdate =~ m/\d\d\.\d\d.\d\d/, "date ok: " . $res->ret_transdate);
is($res->ret_errorcode, 0, "No error");

ok(defined $res->ret_authcode,
   "authcode is defined:" . $res->ret_authcode);

ok($res->ret_trx_number,
   "Trx number is returned: " . $res->ret_trx_number);

$res = $secbopi->capture($ipayres->ret_trx_number, 200 , "EUR",
                         { shopperId => $shopper_id });

like($secbopi->debug->request->content,
     qr{<shopperId>\Q$shopper_id\E</shopperId}, "Shopper id passed");

is($res->address_info, 'via del piffero 10 34100 Trieste IT melmothx@gmail.com 041-311234', "Address OK");

ok($res->is_success, "Charging the remaining 2 euros works");

diag Dumper($res->successDetails);

sleep 1;

$res = $secbopi->capture($ipayres->ret_trx_number, 500000 , "EUR",
                         { shopperId => $shopper_id });
# print Dumper($secbopi->debug);

like($secbopi->debug->request->content,
     qr{<shopperId>\Q$shopper_id\E</shopperId}, "Shopper id passed");


diag Dumper($res->successDetails);

is($res->address_info, '', "Empty address on failure");

ok(!$res->is_success, "More charging fails");
diag Dumper ($res);
ok($res->is_error, "And we have an error");

ok($res->ret_errorcode, "with code " . $res->ret_errorcode);

like $res->error_info,  qr/Not enough funds left \(\d+\) for this capture. 10031/, "Not funds left error ok";

$res = $secbopi->capture("828939234", 500000, "EUR",
                         { shopperId => $shopper_id });

like($secbopi->debug->request->content,
     qr{<shopperId>\Q$shopper_id\E</shopperId}, "Shopper id passed");


ok($res->is_error, "Charging a random number with 50.000 fails");

is($res->error_info, "FATAL: Die Initialisierung der Transaktion ist fehlgeschlagen. 1002", "Fatal error displayed correctly");

ok(!$res->trx_timestamp, "timestamp empty: " . $res->trx_timestamp);
ok(!$res->ret_transtime, "time empty: " . $res->ret_transtime);
ok(!$res->ret_transdate, "date empty: " . $res->ret_transdate);

my $empty = Business::OnlinePayment::IPayment::Return->new(successDetails => {});
foreach my $method (qw/status ret_status trx_remoteip_country trxRemoteIpCountry trx_paymentdata_country trxPaymentDataCountry address_info error_info ret_transdate  ret_transtime trx_timestamp ret_trx_number ret_authcode ret_errorcode/) {
    is($empty->$method, "", "Return $method returns the empty string");
}
ok(!$empty->is_success, "Empty is not a success");
ok($empty->is_error, "But is an error");

$empty = Business::OnlinePayment::IPayment::Response->new();
foreach my $method (qw/ret_status trx_remoteip_country trx_paymentdata_country address_info ret_transdate  ret_transtime ret_trx_number ret_authcode ret_errorcode/) {
    is($empty->$method, "", "Return $method returns the empty string");
}
ok(!$empty->is_success, "Empty is not a success");
ok(!$empty->is_error, "But is neither an error");


diag "Testing the reverse";

$amount = int(rand(5000)) * 100 + 2;
$shopper_id = int(rand(5000)) * 100 + 2;


$secbopi->transaction(transactionType => 'preauth',
                      trxAmount       => "$amount",
                      invoiceText     => "Test reverse",
                      shopper_id      => $shopper_id);

$response = $ua->post($secbopi->ipayment_cgi_location,
                      { ipayment_session_id => $secbopi->session_id,
                        addr_name => "Mario Pegula",
                        addr_street => "via del piffero 10",
                        addr_city => "Trieste",
                        addr_zip => "34100",
                        addr_country => "IT",
                        addr_telefon => "041-311234",
                        addr_email => 'melmothx@gmail.com',
                        silent => 1,
                        cc_number => "4111111111111111",
                        cc_checkcode => "",
                        cc_expdate_month => "02",
                        trx_securityhash => $secbopi->trx_securityhash,
                        cc_expdate_year => next_year() });

$ipayres = $secbopi->get_response_obj($response->header('location'));
ok($ipayres->is_valid);
ok($ipayres->is_success);
diag $ipayres->ret_trx_number, " ", $ipayres->trx_amount, " ", $ipayres->trx_currency, "\n";
my $reverse = $secbopi->reverse($ipayres->ret_trx_number);

ok($reverse->is_success);
is($reverse->paymentMethod, "VisaCard", "Payment method ok");
is($reverse->status, "SUCCESS", "successfully reversed");
ok(!$reverse->is_error, "no error");

$reverse = $secbopi->reverse($ipayres->ret_trx_number);

ok($reverse->is_error, "Reverting again raises an error");
ok($reverse->error_info =~ qr/Transaction already reversed/);
is_deeply($reverse->errorDetails, {
                                   'retAdditionalMsg' => 'Transaction already reversed',
                                   'retFatalerror' => 0,
                                   'retErrorMsg' => 'Reverse nicht mglich. (Betrag abweichend oder bereits abgebucht? Bitte Gutschrift verwenden.)',
                                   'retErrorcode' => 10032
                                  }) or diag Dumper($reverse->errorDetails);

diag "Testing the reverse after a partial capture (should fail)";

$amount = int(rand(5000)) * 100 + 500;
$shopper_id = int(rand(5000)) * 100 + 500;

$secbopi->transaction(transactionType => 'preauth',
                      trxAmount       => "$amount",
                      invoiceText     => "Test reverse",
                      shopper_id      => $shopper_id);

$response = $ua->post($secbopi->ipayment_cgi_location,
                      { ipayment_session_id => $secbopi->session_id,
                        addr_name => "Mario Pegula",
                        addr_street => "via del piffero 10",
                        addr_city => "Trieste",
                        addr_zip => "34100",
                        addr_country => "IT",
                        addr_telefon => "041-311234",
                        addr_email => 'melmothx@gmail.com',
                        silent => 1,
                        cc_number => "4111111111111111",
                        cc_checkcode => "",
                        cc_expdate_month => "02",
                        trx_securityhash => $secbopi->trx_securityhash,
                        cc_expdate_year => next_year() });

$ipayres = $secbopi->get_response_obj($response->header('location'));
ok($ipayres->is_valid);
ok($ipayres->is_success);
diag $ipayres->ret_trx_number, " ", $ipayres->trx_amount, " ", $ipayres->trx_currency, "\n";
$res = $secbopi->capture($ipayres->ret_trx_number, 200 , "EUR",
                         { shopperId => $shopper_id });

like($secbopi->debug->request->content,
     qr{<shopperId>\Q$shopper_id\E</shopperId}, "Shopper id passed");

ok($res->is_success, "Charging 2 euros works");
$res = $secbopi->reverse($ipayres->ret_trx_number);
ok(!$res->is_success, "And now the reverse fails");
diag Dumper($res);

is_deeply($res->errorDetails, {
                                   'retAdditionalMsg' => 'Transaction already partial or completely captured',
                                   'retFatalerror' => 0,
                                   'retErrorMsg' => 'Reverse nicht mglich. (Betrag abweichend oder bereits abgebucht? Bitte Gutschrift verwenden.)',
                                   'retErrorcode' => 10032
                                  }) or diag Dumper($res->errorDetails);

ok($res->error_info =~ qr/Transaction already partial or completely captured/);


sub next_year {
    my $year = strftime('%Y', localtime(time())) + 1;
}
