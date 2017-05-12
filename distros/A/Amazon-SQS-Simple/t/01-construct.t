#!perl -T

use Test::More tests => 4;
use Amazon::SQS::Simple;

my $obj;

eval {
    $obj = new Amazon::SQS::Simple();
};

ok($@, "should get a constructor exception when no AWS keys exist");
my $error = $@;
chomp($error);
like($error,
     qr/missing.*aws.*key/i,
     "should have a good error message (got: \"$error\")");

eval {
    $obj = new Amazon::SQS::Simple('fake access', 'fake secret',
                                      Version => "bogus version");
};

ok(!$@, 
    "Giving an unrecognised version is OK");

eval {
    $obj = new Amazon::SQS::Simple('fake access', 'fake secret');
};

ok(!$@ 
    && $obj->_api_version eq $Amazon::SQS::Simple::Base::DEFAULT_SQS_VERSION,
    "Constructor should default to the default API version if no version is given");
