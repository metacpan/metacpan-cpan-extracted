use strict;
use warnings;
use Test::More;
use Business::OnlinePayment::IPayment::Response;

plan tests => 5;

my $url = 'http://linuxia.de/ipayment/success?addr_name=Mario+Pegula&trxuser_id=99998&trx_amount=5000&trx_currency=EUR&trx_typ=preauth&trx_paymenttyp=cc&ret_transdate=14.03.13&ret_transtime=12%3A18%3A18&ret_errorcode=0&ret_authcode=&ret_ip=88.198.37.147&ret_booknr=1-83449524&ret_trx_number=1-83449524&ret_param_checksum=e8f28c37bbf6f019d0fd72d90075c841&redirect_needed=0&trx_paymentmethod=VisaCard&trx_paymentdata_country=US&trx_remoteip_country=DE&ret_status=SUCCESS&ret_url_checksum=618bad619ce4b08894983c28adcd4131';

my $validator = Business::OnlinePayment::IPayment::Response
  ->new(my_security_key => "testtest");

ok($validator->url_is_valid($url));
ok(!$validator->validation_errors);

$validator = Business::OnlinePayment::IPayment::Response
  ->new(my_security_key => "testtesX");
ok(!$validator->url_is_valid($url));
ok($validator->validation_errors, "Errors: ". $validator->validation_errors);

$validator = Business::OnlinePayment::IPayment::Response
  ->new(my_security_key => "testtest",
        raw_url => 'http://flowers.linuxia.de/checkout-payment?addr_name=Mario&addr_street=&addr_zip=&addr_city=&addr_country=HR&addr_telefon=&addr_email=&form_submit=Naprej+na+povzetek+naroila&trxuser_id=99998&trx_amount=3990&trx_currency=EUR&shopper_id=252726&trx_typ=preauth&trx_paymenttyp=cc&ret_errorcode=5003&ret_fatalerror=0&ret_errormsg=Das+angegebene+Verfallsdatum+der+Kreditkarte+ist+fehlerhaft.&ret_additionalmsg=The+Expdate+%28%29+is+invalid&ret_ip=93.137.157.213&redirect_needed=0&ret_status=ERROR&ret_url_checksum=25d65aed465c8067a0a1ba8c5d7dcef1',
       );


ok($validator->url_is_valid);

