use Business::OnlinePayment::BitPay::KeyUtils;
use strict;
use warnings;
use Mozilla::CA;
use Test::More;
use LWP::UserAgent;
use HTTP::Request;
use LWP::Protocol::https;
use JSON;
use JSON::Parse 'parse_json';
use IO::Socket::SSL;

my $const_sin = "TeyN4LPrXiG5t2yuSamKqP3ynVk3F52iHrX";
my $const_pem = "-----BEGIN EC PRIVATE KEY-----\nMHQCAQEEICg7E4NN53YkaWuAwpoqjfAofjzKI7Jq1f532dX+0O6QoAcGBSuBBAAK\noUQDQgAEjZcNa6Kdz6GQwXcUD9iJ+t1tJZCx7hpqBuJV2/IrQBfue8jh8H7Q/4vX\nfAArmNMaGotTpjdnymWlMfszzXJhlw==\n-----END EC PRIVATE KEY-----\n\n";
my $const_pri = "283B13834DE77624696B80C29A2A8DF0287E3CCA23B26AD5FE77D9D5FED0EE90";
my $const_pub = "038D970D6BA29DCFA190C177140FD889FADD6D2590B1EE1A6A06E255DBF22B4017";

test_generate_pem();
test_get_sin_from_pem();
test_get_public_key_from_pem();
test_sign_message_with_pem();
test_can_connect_to_bitpay_api();

sub test_generate_pem {
  my $pem = Business::OnlinePayment::BitPay::KeyUtils::bpGeneratePem();
  ok( $pem =~ m/BEGIN EC PRIVATE KEY.*\n.*\n.*\n.*\n.*END EC PRIVATE KEY/, 'TEST PEM GENERATION');
}

sub test_get_sin_from_pem {
  my $sin = Business::OnlinePayment::BitPay::KeyUtils::bpGenerateSinFromPem($const_pem);
  is( $sin, $const_sin, 'TEST SIN GENERATION');
}

sub test_get_public_key_from_pem {
  my $pub = Business::OnlinePayment::BitPay::KeyUtils::bpGetPublicKeyFromPem($const_pem);
  is( $pub, $const_pub, 'TEST PUBLIC KEY GENERATION');
}

sub test_sign_message_with_pem {
  my $message = "We are the crystal gems";
  my $signature = Business::OnlinePayment::BitPay::KeyUtils::bpSignMessageWithPem($const_pem, $message);
  ok( $signature =~ m/^[a-f0-9]+$/, 'TEST SIGNATURE IS HEX');
  ok( $signature =~ m/^304[4-6]022[0-1].*022[0-1]/, 'TEST SIGNATURE ENCODING SCHEME, BYTE LENGTH, & NEW SECTION LENGTHS');

  my $signature_length = length $signature;
  ok( $signature_length >= 140 && $signature_length <= 144, "TEST SIGNATURE LENGTH");
}

sub test_can_connect_to_bitpay_api {
  my $uri = "https://bitpay.com/tokens";
  my $pem = Business::OnlinePayment::BitPay::KeyUtils::bpGeneratePem();
  my $sin = Business::OnlinePayment::BitPay::KeyUtils::bpGenerateSinFromPem($pem);
  my $request = HTTP::Request->new(POST => $uri);
  $request->header('content-type' => 'application/json');
  my %content = ('id'=>$sin);
  my $jsonc = encode_json \%content;
  $request->content($jsonc);
  my $ua = LWP::UserAgent->new;
  my $response = $ua->request($request);
  ok($response->is_success, "TEST CONNECTION WITH BITPAY");
}

done_testing();
