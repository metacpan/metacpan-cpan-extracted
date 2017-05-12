#!/usr/bin/perl -Ilib -Iblib/lib

use strict;
use Business::MaxMind::CreditCardFraudDetection;

# Enter your license key here (non registered users limited to 20 lookups per day)
my $license_key = 'ENTER_LICENSE_KEY_HERE';

# Constructor parameters:
#  isSecure
#   = 0 then use Regular HTTP
#   = 1 then use Secure HTTP
#  debug
#   = 0 then print no debuging info
#   = 1 then print debuging info
#  timeout
#   time in seconds to wait before timing out and returning

my $ccfs = Business::MaxMind::CreditCardFraudDetection->new(
    isSecure => 1,
    debug    => 1,
    timeout  => 5,
);

# see http://www.maxmind.com/app/ccv for description of fields
$ccfs->input(

    # required fields
    i           => '24.24.24.24',
    city        => 'NewYork',
    region      => 'NY',
    postal      => '11434',
    country     => 'US',
    license_key => $license_key,

    # recommended fields
    domain      => 'yahoo.com',
    bin         => '549099',
    custPhone   => '212-242',
    forwardedIP => '24.24.24.25',

    # optional fields
    binName        => 'MBNA America Bank',
    binPhone       => '800-421-2110',
    requested_type => 'premium',

    # Business::MaxMind::CreditCardFraudDetection will take
    # MD5 hash of e-mail address passed to emailMD5 if it
    # detects '@' in the string
    emailMD5        => 'Adeeb@Hackstyle.com',
    usernameMD5     => 'test_carder_username',
    passwordMD5     => 'test_carder_password',
    shipAddr        => '145-50 157TH STREET',
    shipCity        => 'Jamaica',
    shipRegion      => 'NY',
    shipPostal      => '11434',
    shipCountry     => 'US',
    txnID           => '1234',
    sessionID       => 'abcd9876',
    accept_language => 'de-de',
    user_agent =>
        'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.0.3705; Media Center PC 3.1; .NET CLR 1.1.4322)',
);
$ccfs->query;
my $hash_ref = $ccfs->output;

use Data::Dumper;
print Dumper($hash_ref);
