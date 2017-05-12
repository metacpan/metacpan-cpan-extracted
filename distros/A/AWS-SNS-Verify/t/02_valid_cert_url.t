use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib '../lib';

use AWS::SNS::Verify;


my $sns = AWS::SNS::Verify->new(body => '');

throws_ok(
    sub { $sns->valid_cert_url(undef) },
    qr/\QThe SigningCertURL () isn't a valid URL/,
);

throws_ok(
    sub { $sns->valid_cert_url("abc") },
    qr/\QThe SigningCertURL (abc) isn't a valid URL/,
);


throws_ok(
    sub { $sns->valid_cert_url("http://my.bad.com/cert.pem") },
    qr|\QThe SigningCertURL (http://my.bad.com/cert.pem) isn't an Amazon endpoint|,
);



my $valid_euwest_url = "https://sns.eu-west-1.amazonaws.com/SimpleNotificationService-b95095beb82e8f6a046b3aafc7f4149a.pem";
is(
    $sns->valid_cert_url($valid_euwest_url),
    $valid_euwest_url,
    "Valid url returns url",
);

my $valid_china_url = "https://sns.cn-north-1.amazonaws.com.cn/SimpleNotificationService-3242342098.pem";
is(
    $sns->valid_cert_url($valid_china_url),
    $valid_china_url,
    "Valid China url returns valid url",
);



my $no_validate_sns = AWS::SNS::Verify->new(body => '', validate_signing_cert_url => 0);
my $test_server_url = "http://my.local.test.server/cert.pem";
is(
    $no_validate_sns->valid_cert_url($test_server_url),
    $test_server_url,
    "Accept any URL if no validation",
);




done_testing();
