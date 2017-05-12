use strict;
use warnings;
use Test::More;
use Data::Dumper;

my $NUM_TESTS = 6;
plan tests => $NUM_TESTS;

#########################

## get auth data
my %auth = ();
DO_AUTH: {
  if( -f 'auth.txt' ) {
      ## read in test auth data
      open my $fh, "<", 'auth.txt';
      while( <$fh> ) {
          chomp; next unless $_;
	  my($key, $val) = split /\s*=\s*/;
	  $auth{$key} = $val;
      }
      close $fh;

      if ( ! %auth ) {
          diag ' ';
          diag '###################################################################';
          diag ' ';
          diag "auth.txt found but incomplete. See README or module documentation";
          diag "Some tests will be skipped.";
          diag ' ';
          diag '###################################################################';
      }
  }
  else {
      diag ' ';
      diag '###################################################################';
      diag ' ';
      diag "No auth.txt found. See README or module documentation";
      diag "Some tests will be skipped.";
      diag ' ';
      diag '###################################################################';
  }
}

if ( ! %auth ) {
    # put in fake credentials for at least bare minimum tests
    $auth{'user'} = 'your.TEST.api.username.for.paypal.tld';
    $auth{'pwd'}  = 'your.TEST.api.password';
    $auth{'sig'}  = 'your.TEST.api.signature';
}

use_ok('Business::PayPal::NVP');

$Business::PayPal::NVP::Debug = 0;
my $ua = LWP::UserAgent->new;
my $pp = new Business::PayPal::NVP( test => \%auth, branch => 'test', ua => $ua );
isa_ok($pp, 'Business::PayPal::NVP');

if ( $auth{'user'} eq 'your.TEST.api.username.for.paypal.tld' ) {
    SKIP: {
        skip "Missing/invalid auth.txt.  See README or module documentation", $NUM_TESTS - 2;
    }
    exit;
}

my %ans = ();

## must have a CC merch setup w/ paypal for this to work
%ans = $pp->DoDirectPayment( PAYMENTACTION  => 'Sale',
			     CREDITCARDTYPE => 'VISA',
			     ACCT           => '4933431559370821',
			     AMT            => '30.00',
			     EXPDATE        => '022018',   ## mmyyyy
			     CVV2           => '100',
			     IPADDRESS      => '64.92.165.106',
			     FIRSTNAME      => 'Buyer',
			     LASTNAME       => 'Glassbead',
			     STREET         => '1234 Street',
			     CITY           => 'Omaha',
			     STATE          => 'NE',
			     COUNTRY        => 'United States',
			     ZIP            => '12345',
			     COUNTRYCODE    => 'US'
			   );

is( $ans{ACK}, 'Success', "successful request" )
  or diag Dumper(\%ans,$pp->errors);

%ans = ();
$Business::PayPal::NVP::Debug = 0;
my $invnum = time;
%ans = $pp->SetExpressCheckout( AMT           => '25.44',
				DESC          => 'one widget',
				CUSTOM        => 'thank you for your money...',
				INVNUM        => $invnum,
 				CURRENCYCODE  => 'USD',
                                PAYMENTACTION => 'Sale',
				RETURNURL     => 'http://www.google.com/nonexistent.html',
				CANCELURL     => 'http://www.google.com/', )
  or diag("Error making SetExpressCheckout: " . join(' ', $pp->errors));

my $token = $ans{TOKEN};
ok( $token, "token from SetExpressCheckout: $token" );

print STDERR <<"_VISIT_";

Now paste the following into your browser:

  https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=$token

and login to PayPal using a sandbox buyer. Hit enter here once you've clicked 'Continue' in the PayPal sandbox.
_VISIT_

<STDIN>;

%ans = ();
%ans = $pp->GetExpressCheckoutDetails( TOKEN => $token );

my $payerid = $ans{PAYERID};
ok( $payerid, "GetExpressCheckoutDetails data" );

%ans = ();
$Business::PayPal::NVP::Debug = 0;
%ans = $pp->DoExpressCheckoutPayment( TOKEN         => $token,
				      AMT           => '25.44',
				      PAYERID       => $payerid,
				      PAYMENTACTION => 'Sale' );

ok( $ans{TRANSACTIONID}, "DoExpressCheckoutPayment transaction completed" );

exit;
