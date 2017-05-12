use 5.010001;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use File::Spec;
use LWP::UserAgent;
use URI;
use Business::OnlinePayment::IPayment;
use Business::OnlinePayment::IPayment::Response;

plan tests => 12;

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

diag "Testing the options\n";

my $secbopi = Business::OnlinePayment::IPayment->new(%account);

$secbopi->country("DE");
is $secbopi->country, undef, "country undef";


$secbopi->transaction(transactionType => 'auth',
                      trxAmount       => int(rand(5000)),
                      shopper_id      => int(rand(5000)),
                      trxCurrency     => 'EUR',
                      invoiceText     => "Thanks!",
                      trxUserComment  => "Hello!",
                      paymentType     => "cc",
                      options => {
                                  fromIp => '99.99.99.99',
                                  checkDoubleTrx => 1,
                                  errorLang      => 'en',
                                  # and possibly others, see doc wsdl
                                 }
                     );

ok($secbopi->session_id, "Got a session: " . $secbopi->session_id);

diag "Checking the options: " . $secbopi->debug->request->content;
like($secbopi->debug->request->content, qr{checkDoubleTrx});
like($secbopi->debug->request->content, qr{errorLang});
like($secbopi->debug->request->content, qr{fromIp});


my $ua = LWP::UserAgent->new;
$ua->max_redirect(0);
my $response = $ua->post($secbopi->ipayment_cgi_location,
                         { ipayment_session_id => $secbopi->session_id,
                           addr_name => "Mario Pegula",
                           silent => 1,
                           cc_number => "4111111111111112",
                           cc_checkcode => "",
                           cc_expdate_month => "02",
                           trx_securityhash => $secbopi->trx_securityhash,
                           cc_expdate_year => "2014" });

my $location = URI->new($response->header('location'));
my %params = $location->query_form;

is $params{ret_errormsg}, 'The given credit card number is not valid.',
  "The options work, as we got the error message in english!";
is $params{invoice_text}, "Thanks!", "Found invoice text";
is $params{trx_user_comment}, "Hello!", "Found user comment";

print Dumper(\%params);

$secbopi->country("DE");

is $secbopi->country, "DE", "country ok";

$secbopi->country("UK");

is $secbopi->country, "GB", "UK translated to GB";

$secbopi->country("EI");

is $secbopi->country, "IE", "EI translated to IE";

$secbopi->country("italy");

is $secbopi->country, undef, "invalid country returns undef";
