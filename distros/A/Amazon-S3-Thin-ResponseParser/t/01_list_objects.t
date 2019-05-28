use strict;
use warnings;
use Test::More;
use Amazon::S3::Thin::ResponseParser;

# https://docs.aws.amazon.com/AmazonS3/latest/API/v2-RESTBucketGET.html
# https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketGET.html

my $response_parser = Amazon::S3::Thin::ResponseParser->new();

subtest 'Example 1: Listing Keys' => sub {
    my ($list_objects, $error) = $response_parser->list_objects(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>bucket</Name>
    <Prefix/>
    <KeyCount>205</KeyCount>
    <MaxKeys>1000</MaxKeys>
    <IsTruncated>false</IsTruncated>
    <Contents>
        <Key>my-image.jpg</Key>
        <LastModified>2009-10-12T17:50:30.000Z</LastModified>
        <ETag>&quot;fba9dede5f27731c9771645a39863328&quot;</ETag>
        <Size>434234</Size>
        <StorageClass>STANDARD</StorageClass>
    </Contents>
</ListBucketResult>
XML
    is $error, undef;

    is_deeply $list_objects, {
        contents                => [
            {
                etag          => 'fba9dede5f27731c9771645a39863328',
                key           => 'my-image.jpg',
                last_modified => '2009-10-12T17:50:30.000Z',
                owner         => {
                    display_name => '',
                    id           => '',
                },
                size          => 434234,
                storage_class => 'STANDARD',
            },
        ],
        common_prefixes         => [],
        delimiter               => '',
        encoding_type           => '',
        is_truncated            => 0,
        max_keys                => 1000,
        name                    => 'bucket',
        prefix                  => '',

        marker                  => '',
        next_marker             => '',

        continuation_token      => '',
        next_continuation_token => '',
        key_count               => 205,
        start_after             => '',
    };
};

subtest 'Example 2: Listing Keys Using the max-keys, prefix, and start-after Parameters' => sub {
    my ($list_objects, $error) = $response_parser->list_objects(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
    <Name>quotes</Name>
    <Prefix>E</Prefix>
    <StartAfter>ExampleGuide.pdf</StartAfter>
    <KeyCount>1</KeyCount>
    <MaxKeys>3</MaxKeys>
    <IsTruncated>false</IsTruncated>
    <Contents>
        <Key>ExampleObject.txt</Key>
        <LastModified>2013-09-17T18:07:53.000Z</LastModified>
        <ETag>&quot;599bab3ed2c697f1d26842727561fd94&quot;</ETag>
        <Size>857</Size>
        <StorageClass>REDUCED_REDUNDANCY</StorageClass>
    </Contents>
</ListBucketResult>
XML
    is $error, undef;
    is_deeply $list_objects, {
        contents                => [
            {
                etag          => '599bab3ed2c697f1d26842727561fd94',
                key           => 'ExampleObject.txt',
                last_modified => '2013-09-17T18:07:53.000Z',
                owner         => {
                    display_name => '',
                    id           => '',
                },
                size          => 857,
                storage_class => 'REDUCED_REDUNDANCY',
            },
        ],
        common_prefixes         => [],
        delimiter               => '',
        encoding_type           => '',
        is_truncated            => 0,
        max_keys                => 3,
        name                    => 'quotes',
        prefix                  => 'E',

        marker                  => '',
        next_marker             => '',

        continuation_token      => '',
        next_continuation_token => '',
        key_count               => 1,
        start_after             => 'ExampleGuide.pdf',
    };
};

subtest 'Example 3: Listing Keys Using the prefix and delimiter Parameters' => sub {
    my ($list_objects, $error) = $response_parser->list_objects(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>example-bucket</Name>
  <Prefix>photos/2006/</Prefix>
  <KeyCount>3</KeyCount>
  <MaxKeys>1000</MaxKeys>
  <Delimiter>/</Delimiter>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>photos/2006/</Key>
    <LastModified>2016-04-30T23:51:29.000Z</LastModified>
    <ETag>&quot;d41d8cd98f00b204e9800998ecf8427e&quot;</ETag>
    <Size>0</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>

  <CommonPrefixes>
    <Prefix>photos/2006/February/</Prefix>
  </CommonPrefixes>
  <CommonPrefixes>
    <Prefix>photos/2006/January/</Prefix>
  </CommonPrefixes>
</ListBucketResult>
XML
    is $error, undef;
    is_deeply $list_objects, {
        contents                => [
            {
                etag          => 'd41d8cd98f00b204e9800998ecf8427e',
                key           => 'photos/2006/',
                last_modified => '2016-04-30T23:51:29.000Z',
                owner         => {
                    display_name => '',
                    id           => '',
                },
                size          => 0,
                storage_class => 'STANDARD',
            },
        ],
        common_prefixes         => [
            {
                prefix => 'photos/2006/February/',
                owner  => {
                    display_name => '',
                    id           => '',
                },
            },
            {
                prefix => 'photos/2006/January/',
                owner  => {
                    display_name => '',
                    id           => '',
                },
            },
        ],
        delimiter               => '/',
        encoding_type           => '',
        is_truncated            => 0,
        max_keys                => 1000,
        name                    => 'example-bucket',
        prefix                  => 'photos/2006/',

        marker                  => '',
        next_marker             => '',

        continuation_token      => '',
        next_continuation_token => '',
        key_count               => 3,
        start_after             => '',
    };
};

subtest 'Example 4: Using a Continuation Token' => sub {
    my ($list_objects, $error) = $response_parser->list_objects(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>bucket</Name>
  <Prefix></Prefix>
  <NextContinuationToken>1ueGcxLPRx1Tr/XYExHnhbYLgveDs2J/wm36Hy4vbOwM=</NextContinuationToken>
  <KeyCount>1000</KeyCount>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>true</IsTruncated>
  <Contents>
    <Key>happyface.jpg</Key>
    <LastModified>2014-11-21T19:40:05.000Z</LastModified>
    <ETag>&quot;70ee1738b6b21e2c8a43f3a5ab0eee71&quot;</ETag>
    <Size>11</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>
</ListBucketResult>
XML
    is $error, undef;
    is_deeply $list_objects, {
        contents                => [
            {
                etag          => '70ee1738b6b21e2c8a43f3a5ab0eee71',
                key           => 'happyface.jpg',
                last_modified => '2014-11-21T19:40:05.000Z',
                owner         => {
                    display_name => '',
                    id           => '',
                },
                size          => 11,
                storage_class => 'STANDARD',
            },
        ],
        common_prefixes         => [],
        delimiter               => '',
        encoding_type           => '',
        is_truncated            => 1,
        max_keys                => 1000,
        name                    => 'bucket',
        prefix                  => '',

        marker                  => '',
        next_marker             => '',

        continuation_token      => '',
        next_continuation_token => '1ueGcxLPRx1Tr/XYExHnhbYLgveDs2J/wm36Hy4vbOwM=',
        key_count               => 1000,
        start_after             => '',
    };
};

subtest 'Sample Request Using Request Parameters (v1)' => sub {
    my ($list_objects, $error) = $response_parser->list_objects(<<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>quotes</Name>
  <Prefix>N</Prefix>
  <Marker>Ned</Marker>
  <MaxKeys>40</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>Nelson</Key>
    <LastModified>2006-01-01T12:00:00.000Z</LastModified>
    <ETag>&quot;828ef3fdfa96f00ad9f27c383fc9ac7f&quot;</ETag>
    <Size>5</Size>
    <StorageClass>STANDARD</StorageClass>
    <Owner>
      <ID>bcaf161ca5fb16fd081034f</ID>
      <DisplayName>webfile</DisplayName>
     </Owner>
  </Contents>
  <Contents>
    <Key>Neo</Key>
    <LastModified>2006-01-01T12:00:00.000Z</LastModified>
    <ETag>&quot;828ef3fdfa96f00ad9f27c383fc9ac7f&quot;</ETag>
    <Size>4</Size>
    <StorageClass>STANDARD</StorageClass>
     <Owner>
      <ID>bcaf1ffd86a5fb16fd081034f</ID>
      <DisplayName>webfile</DisplayName>
    </Owner>
 </Contents>
</ListBucketResult>
XML
    is $error, undef;
    is_deeply $list_objects, {
        contents                => [
            {
                etag          => '828ef3fdfa96f00ad9f27c383fc9ac7f',
                key           => 'Nelson',
                last_modified => '2006-01-01T12:00:00.000Z',
                owner         => {
                    display_name => 'webfile',
                    id           => 'bcaf161ca5fb16fd081034f',
                },
                size          => 5,
                storage_class => 'STANDARD',
            },
            {
                etag          => '828ef3fdfa96f00ad9f27c383fc9ac7f',
                key           => 'Neo',
                last_modified => '2006-01-01T12:00:00.000Z',
                owner         => {
                    display_name => 'webfile',
                    id           => 'bcaf1ffd86a5fb16fd081034f',
                },
                size          => 4,
                storage_class => 'STANDARD',
            },
        ],
        common_prefixes         => [],
        delimiter               => '',
        encoding_type           => '',
        is_truncated            => 0,
        max_keys                => 40,
        name                    => 'quotes',
        prefix                  => 'N',

        marker                  => 'Ned',
        next_marker             => '',

        continuation_token      => '',
        next_continuation_token => '',
        key_count               => '',
        start_after             => '',
    };
};

done_testing;
