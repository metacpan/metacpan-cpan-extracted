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
use Test::Deep;
use Test::Exception;
use FindBin qw/ $Script /;
use Data::Section::Simple 'get_data_section';

use Carp 'confess';
$SIG{__DIE__} = \&confess;

use_ok('AWS::S3');
use_ok('AWS::S3::FileIterator');
use_ok('AWS::S3::Bucket');

my $s3 = AWS::S3->new(
    access_key_id     => $ENV{AWS_ACCESS_KEY_ID}     // 'foo',
    secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY} // 'bar',
    endpoint          => $ENV{AWS_ENDPOINT}          // 's3.baz.com',
);

isa_ok(
    my $bucket = AWS::S3::Bucket->new(
        s3   => $s3,
        name => $ENV{AWS_TEST_BUCKET} // 'maibucket',
    ),
    'AWS::S3::Bucket'
);

foreach my $args (
    [qw( page_size page_number )],
    [qw( bucket page_number )],
    [qw( bucket page_size )],
)
{
    throws_ok {
        AWS::S3::FileIterator->new( map { $_ => 1 } @$args );
    }
    qr/Required argument/, 'dies when arg is missing';
}

{
    isa_ok(
        my $iterator = AWS::S3::FileIterator->new(
            page_number => 2,
            page_size   => 1,
            bucket      => $bucket,
            prefix      => 'img',
        ),
        'AWS::S3::FileIterator'
    );

    is( $iterator->marker,'','marker' );
    is( $iterator->pattern,qr/.*/,'pattern' );
    isa_ok( $iterator->bucket,'AWS::S3::Bucket' );
    is( $iterator->page_size,1,'page_size' );
    is( $iterator->has_prev,'','has_prev' );
    is( $iterator->has_next,undef,'has_next' );
    is( $iterator->page_number,1,'get page_number' );
    is( $iterator->page_number(1),0,'set page_number' );
    is( $iterator->prefix,'img','prefix' );

    {
        my $iterator2 = AWS::S3::FileIterator->new(
            page_number => 1,
            page_size   => 1,
            bucket      => $bucket,
            marker      => 'foo',
            pattern     => qr/\d/,
        );
        is( $iterator2->marker,'foo','marker passed');
        is( $iterator2->pattern,qr/\d/,'pattern passed');
        is( $iterator2->prefix,undef,'!prefix' );
    }

    my $mocked_response = Mocked::HTTP::Response->new( 200,get_data_section('ListBucketResult.xml') );
    local *LWP::UserAgent::Determined::request = sub { $mocked_response };
    
    my @pages = $iterator->next_page; # to check wantarray
    cmp_deeply( \@pages,[ obj_isa('AWS::S3::File') ],'next_page returns one ::File' );
    is( $pages[0]->key,'img/my image.jpg','... and it is the one expected' );
    is( $iterator->next_page->[0]->key,'img/my-third-image.jpg','next_page second item' );
    is( $iterator->next_page->[0]->key,'img/my image.jpg','next_page new request, first item' );

    $mocked_response = Mocked::HTTP::Response->new( 200,get_data_section('EmptyResult') );
    ok( $iterator->next_page,'next_page second item' );
    ok( ! $iterator->next_page,'no more items' );
}

subtest 'advance to page X before processing' => sub {
	my $iterator = AWS::S3::FileIterator->new(
		page_number => 5,
		page_size   => 1,
		bucket      => $bucket,
        pattern     => qr/\d+/,
	);

    my $number_of_request;
    my $xml = get_data_section('LongResult');
    my $mocked_response = Mocked::HTTP::Response->new( 200,$xml );
    local *LWP::UserAgent::Determined::request = sub { $number_of_request++; return $mocked_response };

    is( $iterator->next_page->[0]->key,5,'start at file 5' );
    is( $iterator->next_page->[0]->key,6,'... file 6' );
    is( $iterator->next_page->[0]->key,7,'... file 7' );
    is( $iterator->next_page->[0]->key,8,'... file 8' );
    is( $iterator->next_page->[0]->key,9,'... file 9' );
    is( $iterator->next_page->[0]->key,0,'do a new request and get file 0' );
    is( $number_of_request,2,'did two requests' );
};

done_testing();

__DATA__
@@ ListBucketResult.xml
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>bucket</Name>
    <Prefix>img</Prefix>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
    <Contents>
        <Key>img/my image.jpg</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
       <Key>img/my-third-image.jpg</Key>
         <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;1b2cf535f27731c974343645a3985328&quot;</ETag>
        <Size>64994</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
</ListBucketResult>
@@ EmptyResult
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>bucket</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
</ListBucketResult>
@@ LongResult
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>bucket</Name>
    <Prefix/>
    <Marker/>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>true</IsTruncated>
    <Contents>
        <Key>0</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>1</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>2</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>this should get discarded</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>3</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>4</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>5</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>6</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>7</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>this should get discarded</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>8</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
    <Contents>
        <Key>9</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
        <Owner>
            <ID>75aa57f09aa0c8caeab4f8c24e99d10f8e7faeebf76c078efc7c6caea54ba06a</ID>
            <DisplayName>mtd@amazon.com</DisplayName>
        </Owner>
    </Contents>
</ListBucketResult>
