#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use Carp 'confess';
$SIG{__DIE__} = \&confess;

use_ok('AWS::S3');

note( "construction" );
my $s3 = AWS::S3->new(
    access_key_id     => $ENV{AWS_ACCESS_KEY_ID}     // 'foo',
    secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY} // 'bar',
    endpoint          => $ENV{AWS_ENDPOINT}          // 's3.baz.com',
);

use_ok('AWS::S3::Signer');

isa_ok(
    my $signer = AWS::S3::Signer->new(
        method  => 'HEAD',
        s3      => $s3,
        uri     => "http://maibucket.s3.baz.com/boz",
        content => \'hello world',
    ),
    'AWS::S3::Signer'
);

can_ok(
    $signer,
    qw/
        s3
        method
        bucket_name
        uri
        headers
        date
        string_to_sign
        canonicalized_amz_headers
        canonicalized_resource
        content_type
        content_md5
        content
        content_length
        signature
    /,
);


note( "attributes" );
isa_ok( $signer->s3,'AWS::S3' );
is( $signer->method,'HEAD','method' );
is( $signer->bucket_name,'maibucket','bucket_name' );
isa_ok( $signer->uri,'URI' );
cmp_deeply( $signer->headers,[],'headers' );
like( $signer->date,qr/\w+, +\d{1,2} \w+ \d{4} \d{2}:\d{2}:\d{2}/,'date' );
is(
    $signer->string_to_sign,
    "HEAD\nXrY7u+Ae7tCTyyK7j1rNww==\ntext/plain\n".$signer->date."\n/maibucket/boz",
    'string_to_sign'
);
is( $signer->canonicalized_amz_headers,'','canonicalized_amz_headers' );
is( $signer->canonicalized_resource,'/maibucket/boz','canonicalized_resource' );
is( $signer->content_type,'text/plain','content_type' );
is( $signer->content_md5,'XrY7u+Ae7tCTyyK7j1rNww==','content_md5' );
is( ${ $signer->content },'hello world','content' );
is( $signer->content_length,11,'content_length' );
like( $signer->signature,qr/^.{28}$/,'signature' );

note( "methods" );
like( $signer->auth_header,qr/AWS foo:.{28}/,'auth_header' );

done_testing();
