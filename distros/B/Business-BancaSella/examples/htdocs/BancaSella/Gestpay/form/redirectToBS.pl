#!/usr/bin/perl

use CGI qw/:standard/;
use URI::BancaSella::Encode;

my $YOUR_SERVER_WEB     = 'pc100.it';

my $bs	          = new URI::BancaSella::Encode(  type            => param('type'),
                                                shopping        => param('shopping'),
                                                amount          => param('amount'),
                                                language        => 'italian',
                                                currency        => 'itl',
                                                otp             => 'another_otp',
                                                id              => 'internal_id'
                                                );

# this is only for test...remove if using bancaSella true gateway
$bs->base_url("http://$YOUR_SERVER_WEB/BancaSella/Gestpay/bsSimul/bsSimul.pl");




print header, start_html,h1('Test page for module URI::BancaSella::Encode (Form mode)');

print $bs->form('formName');
print<<HTML;
Click button to send data to Banca Sella Demo. You can send form directly modify the body
tag of this page like <pre>&lt;BODY onLoad='document.formName.submit()'&gt;</PRE> 
<form>
<input type='SUBMIT' onClick='document.formName.submit();return false;'>
</form>
HTML

print end_html; 
