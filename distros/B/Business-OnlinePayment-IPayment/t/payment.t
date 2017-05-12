use 5.010001;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use File::Spec;
use LWP::UserAgent;
use URI;
use POSIX qw/strftime/;

plan tests => 34;

use Business::OnlinePayment::IPayment;
use Business::OnlinePayment::IPayment::Response;

diag "Create the object and store the fixed values";

# first try with faulty data

my %faulty = ();

my $faultybopi;

eval { $faultybopi =
         Business::OnlinePayment::IPayment->new();
       $faultybopi->session_id;
       };

ok($@, "Error: $@");

my %accdata = (
               accountid => 99999,
               trxuserid => 99999,
               trxpassword => 0,
               adminactionpassword => '5cfgRT34xsdedtFLdfHxj7tfwx24fe',
              );

my %urls = (
            success_url => "http://linuxia.de/ipayment/success",
            failure_url => "http://linuxia.de/ipayment/failure",
           );

$faulty{wsdl_file} = File::Spec->catfile("t", "ipayment.wsdl");

# incrementally add the data to the hash

# please note that we want to die here, as without the credentials is
# not going to work, and should be provided when the object is
# created.
foreach my $k (qw/accountid trxuserid trxpassword/) {
    eval { $faultybopi =
             Business::OnlinePayment::IPayment->new(%faulty, %urls);
           $faultybopi->session_id;
       };
    # test all the bad values
    ok($@, "Error: $@");
    $faulty{$k} = $accdata{$k};
}

# adminactionpassword seems to be optional? But we need only to
# generate the session, nothing more

my $wsdl_file = File::Spec->catfile("t", "ipayment.wsdl");

my $bopi = Business::OnlinePayment::IPayment->new(%accdata, %urls,
                                                  wsdl_file => $wsdl_file);

$accdata{accountId} = delete $accdata{accountid};
$accdata{trxuserId} = delete $accdata{trxuserid};

is_deeply($bopi->accountData, { %accdata } , "Stored values ok");

is scalar(keys %{$bopi->processorUrls}), 3, "Found 3 urls";
is $bopi->processorUrls->{redirectUrl}, $urls{success_url}, "success ok";
is $bopi->processorUrls->{silentErrorUrl}, $urls{failure_url}, "success ok";

eval { $bopi->trx_obj->paymentType("test") };
ok($@, "Can't set payment type to bogus value $@");

eval { $bopi->trx_obj->transactionType("preauth") };
ok($@, "Can't change the transaction to allowed value after its creation");

eval { $bopi->trx_obj->transactionType("test") };
ok($@, "Can't set payment type to bogus value $@");



# ok, no point in testing each of those, we trust Moo to do its job

$bopi->transaction(transactionType => 'preauth',
                   trxAmount => int(rand(1000)) * 100);


my $session_id = $bopi->session_id;

my $ua = LWP::UserAgent->new;
$ua->max_redirect(0);

my $response = $ua->post($bopi->ipayment_cgi_location,,
                         { ipayment_session_id => $session_id,
                           addr_name => "Mario Rossi",
                           silent => 1,
                           cc_number => "371449635398431",
                           return_paymentdata_details => 1,
                           cc_checkcode => "",
                           cc_expdate_month => "02",
                           cc_expdate_year => next_year() });

test_success($response);


diag "Testing secured app";


my %account = (
               accountid => 99999,
               trxuserid => 99998,
               trxpassword => 0,
               adminactionpassword => '5cfgRT34xsdedtFLdfHxj7tfwx24fe',
               app_security_key => 'testtest',
               wsdl_file => $wsdl_file,
               %urls
              );


my $secbopi = Business::OnlinePayment::IPayment->new(%account);

$secbopi->transaction(transactionType => 'preauth',
                      trxAmount       => int(rand(5000)) * 100,
                      shopper_id      => 1234);

$response = $ua->post($secbopi->ipayment_cgi_location,
                      { ipayment_session_id => $secbopi->session_id,
                        addr_name => "Mario Pegula",
                        silent => 1,
                        cc_number => "4111111111111111",
                        return_paymentdata_details => 1,
                        cc_checkcode => "",
                        cc_expdate_month => "02",
                        trx_securityhash => $secbopi->trx_securityhash,
                        cc_expdate_year => next_year() });

ok($secbopi->debug->request->content, "We can inspect the SOAP request");

# diag Dumper($response->header('location'));
test_success($response);

my $ipayres = $secbopi->get_response_obj($response->header('location'));

# we build this anew, as in the web it will be a fresh request, so we
# don't do nothing about the previous one.

$ipayres->set_credentials(
                          my_amount   => $secbopi->trx_obj->trxAmount,
                          my_currency => $secbopi->trx_obj->trxCurrency,
                          # my_userid   => $secbopi->trxuserid,
                          # my_security_key => $secbopi->app_security_key,
                         );

ok($ipayres->url_is_valid, "Url is ok");
ok($ipayres->is_valid, "Payment looks ok");
ok(!$ipayres->validation_errors, "No errors found");
is($ipayres->paydata_cc_number, 'XXXXXXXXXXXX1111', "CC num returned masked");
is($ipayres->paydata_cc_cardowner, "Mario Pegula", "CC owner returned");
is($ipayres->paydata_cc_typ, "VisaCard", "Visa card returned");
my $expiration_expected = next_year();
$expiration_expected =~ s/^(\d\d)(\d\d)/02$2/;
is($ipayres->paydata_cc_expdate, $expiration_expected,
   "Expiration returned $expiration_expected");

# while if we tamper fails
$ipayres->my_amount(5000000);
ok(!$ipayres->is_valid, "Tampered data not ok");
ok($ipayres->validation_errors, "Errors: " . $ipayres->validation_errors);

# passing only the security key should work too
my $location = URI->new($response->header('location'));
my %params = $location->query_form;

$ipayres = Business::OnlinePayment::IPayment::Response->new(%params);
eval {$ipayres->is_valid };
ok($@, "no secret key: $@");

# with security key pass is ok.
$ipayres = Business::OnlinePayment::IPayment::Response->new(%params);
$ipayres->my_security_key("testtest");
ok($ipayres->is_success && $ipayres->is_valid, "Payment looks ok");
ok $ipayres->shopper_id, "Shopper id retrieve: " . $ipayres->shopper_id;
ok($ipayres->url_is_valid($response->header('location')),
   "Url looks untampered");
ok(!$ipayres->validation_errors, "No errors");

$ipayres->my_security_key("testtestX");
ok(!$ipayres->is_valid, "wrong secret key yields failure");
ok($ipayres->validation_errors, "Errors: " . $ipayres->validation_errors);




# diag "Please wait 2 minutes before running me again, or the tests will fail!";
# diag "Test run on " . localtime;

sub test_success {
    my $r = shift;
    is($r->status_line, '302 Found', "We are redirected");
    unlike($r->decoded_content, qr/ERROR/, "No error");
    like($r->decoded_content, qr/<a href="http:/, "Redirect");
    my $uri = URI->new($r->header('location'));
    # my %result = $uri->query_form;
    # print Dumper(\%result);
}

sub next_year {
    my $year = strftime('%Y', localtime(time())) + 1;
}
