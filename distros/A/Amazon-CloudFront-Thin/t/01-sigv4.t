use strict;
use warnings;
use Test::More tests => 5;
use URI           ();
use HTTP::Headers ();
use Digest::SHA   ();

use Amazon::CloudFront::Thin;

my $url = URI->new('https://cloudfront.amazonaws.com/');

my @paths = qw(
    /blog/some/document.pdf
    /images/*
    /foo]]>bar
);
my $time = 1438972482; # <-- time()

my $content = Amazon::CloudFront::Thin::_create_xml_payload(\@paths, $time);

is(
    $content,
    '<?xml version="1.0" encoding="UTF-8"?><InvalidationBatch xmlns="http://cloudfront.amazonaws.com/doc/2018-11-05/"><Paths><Quantity>3</Quantity><Items><Path><![CDATA[/blog/some/document.pdf]]></Path><Path><![CDATA[/images/*]]></Path><Path><![CDATA[/foo]]]]><![CDATA[>bar]]></Path></Items></Paths><CallerReference>1438972482</CallerReference></InvalidationBatch>',
    'payload created successfully'
);

my ($formatted_date, $formatted_time) = Amazon::CloudFront::Thin::_format_date($time);

my $headers = HTTP::Headers->new(
    'Content-Length' => 312,
    'Content-Type'   => 'text/xml',
    'Host'           => $url->host,
    'X-Amz-Date'     => $formatted_date . 'T' . $formatted_time . 'Z',
);

my $canonical_request = Amazon::CloudFront::Thin::_create_canonical_request(
    $url, $headers, $content
);

my $expected = <<'EOEXPECTED';
POST
/

content-length:312
content-type:text/xml
host:cloudfront.amazonaws.com
x-amz-date:20150807T183442Z

content-length;content-type;host;x-amz-date
a3e23f629891d71d6ff0aa08039794877aad1b2c35d9a6763d73cf6000fabe2a
EOEXPECTED
chomp $expected;

is $canonical_request, $expected, 'canonical request created successfully';

is(
    Digest::SHA::sha256_hex($canonical_request),
    '0930071b1f7beda5b91ca47b4bf94719f4cba8380376a1b94fc1b172394c40ff',
    'sha256 matches canonical request'
);

my $string_to_sign = Amazon::CloudFront::Thin::_create_string_to_sign(
    $headers, $canonical_request
);

my ($date) = Amazon::CloudFront::Thin::_format_date($time);
is $date, '20150807', 'date stamp was properly formatted';

is(
    Amazon::CloudFront::Thin::_create_signature(
        'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        $string_to_sign,
        $date
    ),
    '8948b035d07fa96fdc90e0729dac79d4671b2b9ecf59da6ae093b313d32cd3b9',
    'v4 signature created successfully'
);
