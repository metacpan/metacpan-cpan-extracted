#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use FindBin qw/ $Script /;

use Carp 'confess';
$SIG{__DIE__} = \&confess;

use_ok('AWS::S3');

note( "construction" );
my $s3 = AWS::S3->new(
    access_key_id     => $ENV{AWS_ACCESS_KEY_ID}     // 'foo',
    secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY} // 'bar',
    endpoint          => $ENV{AWS_ENDPOINT}          // 's3.baz.com',
);

use_ok('AWS::S3::HTTPRequest');

isa_ok(
    my $request = AWS::S3::HTTPRequest->new(
		s3     => $s3,
		method => 'POST',
		path   => '/foo/bar',
    ),
    'AWS::S3::HTTPRequest'
);

can_ok(
    $request,
    qw/
		s3
		method
		path
		headers
		content
		metadata
		contenttype
    /,
);

isa_ok( $request->http_request,'HTTP::Request' );

is( $request->is_dns_bucket( 'foo' ),1,'_is_dns_bucket' );
is( $request->is_dns_bucket( 'Foo' ),0,'_! is_dns_bucket' );
is( $request->is_dns_bucket( 'bar123boz' ),1,'_is_dns_bucket' );
is( $request->is_dns_bucket( 'bar123Boz' ),0,'! _is_dns_bucket' );
is( $request->is_dns_bucket( 'foo!' ),0,'! _is_dns_bucket' );
is( $request->is_dns_bucket( '255.255.255.255' ),0,'! _is_dns_bucket' );
is( $request->is_dns_bucket( 'fo' ),0,'! _is_dns_bucket' );
is( $request->is_dns_bucket( 'x' x 64 ),0,'! _is_dns_bucket' );
is( $request->is_dns_bucket( 'x' x 63 ),1,'_is_dns_bucket' );

isa_ok(
    my $request_with_content = AWS::S3::HTTPRequest->new(
        s3      => $s3,
        method  => 'POST',
        path    => '/bar/baz',
        content => 'Hello World!'
    ),
    'AWS::S3::HTTPRequest'
);

isa_ok( my $http_request_with_content = $request_with_content->http_request, 'HTTP::Request' );
my $header = $http_request_with_content->headers;
is( $header->header( 'content-type' ), 'text/plain', '... and content-type got set' );
is( $header->header( 'content-length' ), 12, '... and content-length got set' );
is( $header->header( 'host' ), 's3.baz.com', '... and host got set' );

done_testing();
