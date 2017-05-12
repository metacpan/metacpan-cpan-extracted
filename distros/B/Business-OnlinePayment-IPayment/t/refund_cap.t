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

plan tests => 23;



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

my $amount = int(rand(5000)) * 100 + 2000;

my $shopper_id = int(rand(5000));

$secbopi->transaction(transactionType => 'preauth',
                      trxAmount       => "$amount",
                      shopper_id      => $shopper_id);

my $response = $ua->post($secbopi->ipayment_cgi_location,
                      { ipayment_session_id => $secbopi->session_id,
                        addr_name => "Mario Pegula",
                        silent => 1,
                        cc_number => "4111111111111111",
                        cc_checkcode => "",
                        cc_expdate_month => "02",
                        trx_securityhash => $secbopi->trx_securityhash,
                        cc_expdate_year => next_year() });

my $ipayres = $secbopi->get_response_obj($response->header('location'));

ok($ipayres->is_valid);
ok($ipayres->is_success);

print $ipayres->ret_trx_number, " ", $ipayres->trx_amount, " ", $ipayres->trx_currency, "\n";

# capture the full amount
my $res = $secbopi->capture($ipayres->ret_trx_number);

ok($res->is_success);
ok($res->ret_trx_number,
   "Got the capture transaction number: " . $res->ret_trx_number);

# please note that we have to use the transaction number of the
# capture, not the original one.

my $refund = $secbopi->refund($res->ret_trx_number, 2000, "EUR",
                              { shopperId => $shopper_id });

like($secbopi->debug->request->content,
     qr{<shopperId>\Q$shopper_id\E</shopperId}, "Shopper id passed");



ok($refund->is_success);
# print Dumper($secbopi->debug);
print Dumper($secbopi->raw_response_hash);
$refund = $secbopi->refund($res->ret_trx_number, $amount - 2000, "EUR",
                           { shopperId => $shopper_id });

like($secbopi->debug->request->content,
     qr{<shopperId>\Q$shopper_id\E</shopperId}, "Shopper id passed");

ok($refund->is_success);
ok($refund->ret_transdate);
ok($refund->ret_transtime);
ok($refund->ret_trx_number);


print Dumper($secbopi->raw_response_hash);
$refund = $secbopi->refund($res->ret_trx_number, $amount);
ok($refund->is_error);
print Dumper($secbopi->raw_response_hash);
ok($refund->error_info =~ /Not enough funds left.*for this refund/);
is($refund->status, 'ERROR');

# Without arguments we do a full refund

diag "Testing full refund without arguments";


$amount = int(rand(5000)) * 100 + 50000;

$secbopi->transaction(transactionType => 'preauth',
                      trxAmount       => "$amount",
                      shopper_id      => int(rand(5000)));

$response = $ua->post($secbopi->ipayment_cgi_location,
                      { ipayment_session_id => $secbopi->session_id,
                        addr_name => "Mario Pegula",
                        silent => 1,
                        cc_number => "4111111111111111",
                        cc_checkcode => "",
                        cc_expdate_month => "02",
                        trx_securityhash => $secbopi->trx_securityhash,
                        cc_expdate_year => next_year() });

$ipayres = $secbopi->get_response_obj($response->header('location'));

ok($ipayres->is_valid);
ok($ipayres->is_success);

print $ipayres->ret_trx_number, " ", $ipayres->trx_amount, " ", $ipayres->trx_currency, "\n";

# capture the full amount
$res = $secbopi->capture($ipayres->ret_trx_number);

ok($res->is_success);
ok($res->ret_trx_number,
   "Got the capture transaction number: " . $res->ret_trx_number);

$refund = $secbopi->refund($res->ret_trx_number);
ok($refund->is_success, "Full refund succeedeed");
ok($refund->ret_transdate);
ok($refund->ret_transtime);
ok($refund->ret_trx_number);

sleep 2;

$refund = $secbopi->refund($res->ret_trx_number, sprintf('%u', ($amount / 2)), "EUR");
ok($refund->is_error, "Another one fails for " . ($amount / 2));

print Dumper($secbopi->raw_response_hash);

sub next_year {
    my $year = strftime('%Y', localtime(time())) + 1;
}
