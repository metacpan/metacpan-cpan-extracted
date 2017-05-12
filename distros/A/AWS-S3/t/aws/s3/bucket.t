#!perl

use strict;
use warnings;

package Mocked::HTTP::Response;

use Moose;
extends 'HTTP::Response';

sub content        { shift->{_msg}; }
sub code           { 200 }
sub is_success     { 1 }
sub header         { $_[1] =~ /content-length/i ? 1 : 'header' }

1;

package main;
use Test::More;
use Test::Exception;
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

use_ok('AWS::S3::Bucket');

isa_ok(
    my $bucket = AWS::S3::Bucket->new(
        s3   => $s3,
        name => $ENV{AWS_TEST_BUCKET} // 'maibucket',
    ),
    'AWS::S3::Bucket'
);

can_ok(
    $bucket,
    qw/
        s3
        name
        creation_date
        acl
		location_constraint
		policy
    /,
);

isa_ok(
	$bucket->files(
		page_size => 1,
		page_number => 1,
	),
	'AWS::S3::FileIterator'
);

no warnings 'once';
my $mocked_response = Mocked::HTTP::Response->new( 200,'bar' );
*LWP::UserAgent::Determined::request = sub { $mocked_response };

isa_ok( $bucket->file( 'foo' ),'AWS::S3::File' );
isa_ok(
	$bucket->add_file(
		key => 'foo',
		size => 1,
		contents => \"bar",
	),
	'AWS::S3::File'
);

$mocked_response->{_msg} = '';
ok( $bucket->delete,'->delete' );
ok( $bucket->delete_multi( qw/foo bar baz/ ),'->delete_multi' );

throws_ok
	{ $bucket->enable_cloudfront_distribution( $mocked_response ) }
	qr/AWS::CloudFront::Distribution/
;

done_testing();
