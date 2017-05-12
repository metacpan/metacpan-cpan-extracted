#-*-Perl-*-

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use FindBin '$Bin';
use constant TEST_COUNT => 11;

use lib "$Bin/lib","$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use Test::More tests => TEST_COUNT;

use_ok('AWS::Signature4');
use_ok('HTTP::Request::Common');

my $signer = AWS::Signature4->new(-access_key => 'AKIDEXAMPLE',
				  -secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY');
ok($signer,'AWS::Signature4->new');
my $request = POST('https://iam.amazonaws.com',
		   [Action=>'ListUsers', Version=>'2010-05-08'],
		   Date    => '1 January 2014 01:00:00 -0500',
    );
$signer->sign($request);

is($request->method,'POST','request method correct');
is($request->header('Host'),'iam.amazonaws.com','host correct');
is($request->header('X-Amz-Date'),'20140101T060000Z','timestamp correct');
is($request->content,'Action=ListUsers&Version=2010-05-08','payload correct');
is($request->header('Authorization'),'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20140101/us-east-1/iam/aws4_request, SignedHeaders=content-length;content-type;host;x-amz-date, Signature=0233049369ae675cea7616efa5d2e5216c37a4b1496a36595f32181f078e3549','signature correct');

$request = GET('https://iam.amazonaws.com?Action=ListUsers&Version=2010-05-08',
	       Date => '1 January 2014 01:00:00 -0500');

my $expected = 'https://iam.amazonaws.com?Action=ListUsers&Version=2010-05-08&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIDEXAMPLE%2F20140101%2Fus-east-1%2Fiam%2Faws4_request&X-Amz-Date=20140101T060000Z&X-Amz-SignedHeaders=host&X-Amz-Signature=9d0b832ec5c5ebba65a462951e29dcc2eff53b000105a727dd0f233f328e92b2';

is($signer->signed_url($request),$expected,'signed url from request correct');

my $url = 'https://iam.amazonaws.com?Action=ListUsers&Version=2010-05-08&Date=1%20January%202014%2001:00:00%20-0500';

is($signer->signed_url($url),$expected,'signed url from url correct (1)');

$url = 'https://iam.amazonaws.com?Action=ListUsers&Version=2010-05-08&Date=20140101T060000Z';
is($signer->signed_url($url),$expected,'signed url from url correct (2)');

exit 0;

