#!perl

use strict;
use warnings;

package Mocked::HTTP::Response;

use Moose;
extends 'HTTP::Response';

sub content { return shift->{_msg}; }

1;

package main;

use Test::More 'no_plan';
use Test::Deep;
use Test::Exception;
use Data::Section::Simple 'get_data_section';

use Carp 'confess';
$SIG{__DIE__} = \&confess;

use_ok('AWS::S3');

my $s3 = AWS::S3->new(
  access_key_id     => $ENV{AWS_ACCESS_KEY_ID}     // 'foo',
  secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY} // 'bar',
  endpoint          => 'bad.hostname',
);

my $bucket_name = "aws-s3-test-" . int(rand() * 1_000_000) . '-' . time() . "-foo";

eval {
    my $bucket = $s3->add_bucket( name => $bucket_name, location => 'us-west-1' );
};

like(
    $@,
    qr/Can't connect to aws-s3-test-.*?bad\.hostname/,
    'endpoint was used'
);

isa_ok(
	$s3->request( 'CreateBucket',bucket => 'foo' ),
	'AWS::S3::Request::CreateBucket'
);

subtest 'create bucket strange temporary redirect' => sub {
    plan tests => 8;    # make sure all tests in here get run

    my $i = 1;
    local *LWP::UserAgent::Determined::request = sub {
        my ( undef, $req ) = @_;

        if ( $i == 1 ) {

            # first PUT request, send a forward
            is( $req->method, 'PUT', 'bucket creation with PUT request' );
            is( $req->uri->as_string, 'http://bar.bad.hostname/', '... and with correct URI' );

            $i++;
            return HTTP::Response->new(
                307,
                'TEMPORARY REDIRECT',
                [ Location => 'http://example.org' ],
                '<fake>TemporaryRedirect</fake>'
            );
        }
        elsif ( $i == 2 ) {

            # the PUT is sent again, but to the forwarded location

            is( $req->method, 'PUT', 'redirected and second PUT request' );
            is( $req->uri->as_string, 'http://example.org', '... and to the correct URI' );

            $i++;
            return Mocked::HTTP::Response->new( 200, q{} );
        }
        else {
            # there is a call to ->bucket, which does ->buckets, which is empty.
            is( $req->method, 'GET', '->buckets with GET' );
            is( $req->uri->as_string, 'http://bad.hostname/', '... and with correct URI' );

            # we need to return XML in the body or xpc doesn't work
            return Mocked::HTTP::Response->new( 200,
                get_data_section('ListAllMyBucketsResult.xml') );
        }
    };

    my $bucket = $s3->add_bucket( name => 'bar', location => 'us-west-1' );
    isa_ok( $bucket, 'AWS::S3::Bucket' );
    is( $bucket->name, 'bar', '... and the right bucket got returned' );
};

# list all buckets and owner
{
    my $xml = get_data_section('ListAllMyBucketsResult.xml');
    local *LWP::UserAgent::Determined::request = sub {
        return Mocked::HTTP::Response->new( 200,$xml );
    };

    isa_ok( my $owner = $s3->owner,'AWS::S3::Owner' );
    is( $owner->id, 'bcaf1ffd86f41161ca5fb16fd081034f', '... and the owner id correct' );
    is( $owner->display_name, 'webfile', '... and the owner name is correct' );

    my @buckets = $s3->buckets;
    cmp_deeply( \@buckets,
        [ obj_isa('AWS::S3::Bucket'), obj_isa('AWS::S3::Bucket') ], '->buckets' );
    ok( ! $s3->bucket( 'does not exist' ),'!->bucket' );
    is( $s3->bucket( 'foo' )->name, 'foo', '->bucket' );
}

{
    my $xml = get_data_section('error.xml');

    local *LWP::UserAgent::Determined::request = sub {
        return Mocked::HTTP::Response->new( 400,$xml );
    };

    throws_ok { $s3->add_bucket( name => 'too many buckets', location => 'us-west-1' ) }
    qr/TooManyBuckets/, 'add_bucket throws an error';
}
__DATA__
@@ ListAllMyBucketsResult.xml
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Owner>
    <ID>bcaf1ffd86f41161ca5fb16fd081034f</ID>
    <DisplayName>webfile</DisplayName>
  </Owner>
  <Buckets>
    <Bucket>
      <Name>foo</Name>
      <CreationDate>2006-02-03T16:45:09.000Z</CreationDate>
    </Bucket>
    <Bucket>
      <Name>bar</Name>
      <CreationDate>2006-02-03T16:41:58.000Z</CreationDate>
    </Bucket>
 </Buckets>
</ListAllMyBucketsResult>
@@ error.xml
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>TooManyBuckets</Code>
  <Message>You have attempted to create more buckets than allowed.</Message>
  <Resource>/mybucket</Resource>
  <RequestId>4442587FB7D0A2F9</RequestId>
</Error>
