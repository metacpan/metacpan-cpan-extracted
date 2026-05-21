#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use MIME::Base64 qw(encode_base64);
use Digest::MD5 qw(md5);
use JSON::PP;

use Amazon::S3::Lite;
use Amazon::S3::Lite::Logger;
use Amazon::S3::Lite::Credentials;

########################################################################
# Helpers
########################################################################

my $LOCALSTACK = 'http://localhost:4566';

sub localstack_available {
  # Require explicit opt-in to avoid hitting unrelated services on port 4566
  return 0 if !$ENV{TEST_LOCALSTACK};

  require HTTP::Tiny;

  my $res = eval { HTTP::Tiny->new( timeout => 2 )->get("$LOCALSTACK/_localstack/health"); };

  return 0 if $@ || !$res;

  # Verify it's actually LocalStack by checking the response body
  return 0 if $res->{status} != 200;
  my $status = JSON::PP->new->decode( $res->{content} );

  return $status->{services}{s3} =~ /^(?:available|running)$/xsm;
}

sub new_s3 {
  return Amazon::S3::Lite->new(
    { region                => 'us-east-1',
      aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
      @_,
    }
  );
}

sub new_localstack_s3 {
  return new_s3(
    host   => 'localhost:4566',
    secure => 0,
  );
}

# Returns a mock _request sub that captures calls and returns a canned response
sub mock_request {
  my (%args)   = @_;
  my $status   = $args{status}  // 200;
  my $content  = $args{content} // '';
  my $headers  = $args{headers} // {};
  my $captured = $args{capture};

  return sub {
    my ( $self, $method, $url, $req_headers, $body, $extra, $region ) = @_;
    if ($captured) {
      $$captured = {
        method  => $method,
        url     => $url,
        headers => $req_headers,
        body    => $body,
        region  => $region,
      };
    }
    return {
      status  => $status,
      reason  => 'OK',
      headers => $headers,
      content => $content,
    };
  };
}

########################################################################
# Unit tests — no network required
########################################################################

subtest 'constructor' => sub {
  # region required
  eval { Amazon::S3::Lite->new( {} ) };
  like $@, qr/region is required/, 'croaks without region';

  # no credentials — stub _init_credentials so the test is immune to whether
  # Amazon::Credentials is installed or finds real creds (e.g. on an EC2 instance)
  {
    local $ENV{AWS_ACCESS_KEY_ID}     = undef;
    local $ENV{AWS_SECRET_ACCESS_KEY} = undef;
    no warnings 'redefine';
    local *Amazon::S3::Lite::_init_credentials = sub {
      my ( $self, $args ) = @_;
      Carp::croak 'No AWS credentials found.'
        if !$args->{credentials}
        && !$args->{aws_access_key_id}
        && !$ENV{AWS_ACCESS_KEY_ID};
    };
    eval { Amazon::S3::Lite->new( { region => 'us-east-1' } ) };
    like $@, qr/No AWS credentials/, 'croaks without credentials';
  }

  # explicit credentials
  my $s3 = new_s3();
  isa_ok $s3, 'Amazon::S3::Lite';
  is $s3->region, 'us-east-1',        'region set';
  is $s3->host,   's3.amazonaws.com', 'default host';

  # env credentials
  {
    local $ENV{AWS_ACCESS_KEY_ID}     = 'envkey';
    local $ENV{AWS_SECRET_ACCESS_KEY} = 'envsecret';
    local $ENV{AWS_SESSION_TOKEN}     = 'envtoken';
    my $s3e = Amazon::S3::Lite->new( { region => 'us-east-1' } );
    is $s3e->credentials->aws_access_key_id, 'envkey',   'env key';
    is $s3e->credentials->token,             'envtoken', 'env token';
  }

  # duck-typed credentials object
  {

    package MyCreds;
    sub new                   { bless {}, shift }
    sub aws_access_key_id     {'duckkey'}
    sub aws_secret_access_key {'ducksecret'}
    sub token                 {undef}

    package main;
    my $s3d = Amazon::S3::Lite->new(
      { region      => 'us-east-1',
        credentials => MyCreds->new,
      }
    );
    is $s3d->credentials->aws_access_key_id, 'duckkey', 'duck-type creds';
  }

  # bad credentials object
  {

    package BadCreds;
    sub new               { bless {}, shift }
    sub aws_access_key_id {'key'}

    package main;
    eval { Amazon::S3::Lite->new( { region => 'us-east-1', credentials => BadCreds->new } ) };
    like $@, qr/must implement aws_secret_access_key/, 'bad creds object croaks';
  }

  # custom logger
  {
    my $warned = 0;
    my $logger = bless {}, 'MyLogger';
    {
      no strict 'refs';
      for my $m (qw(trace debug info error)) {
        *{"MyLogger::$m"} = sub { };
      }
      *{"MyLogger::warn"} = sub { $warned++ };
    }
    my $s3l = new_s3( logger => $logger );
    isa_ok $s3l->logger, 'MyLogger', 'custom logger accepted';
  }
};

subtest '_endpoint' => sub {
  my $s3 = new_s3();
  is $s3->_endpoint,              'https://s3.amazonaws.com',           'root endpoint';
  is $s3->_endpoint('my-bucket'), 'https://s3.amazonaws.com/my-bucket', 'bucket endpoint';
  is $s3->_endpoint( 'my-bucket', 'path/to/key.txt' ),
    'https://s3.amazonaws.com/my-bucket/path/to/key.txt',
    'bucket+key endpoint';
  is $s3->_endpoint( 'my-bucket', 'path/to/my file+thing.txt' ),
    'https://s3.amazonaws.com/my-bucket/path/to/my%20file%2Bthing.txt',
    'key encoding preserves slashes, encodes special chars';
};

subtest 'list_buckets' => sub {
  my $s3       = new_s3( region => 'eu-west-1' );
  my $captured = {};
  my $xml      = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<ListAllMyBucketsResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Owner><ID>owner123</ID><DisplayName>rob</DisplayName></Owner>
  <Buckets>
    <Bucket><Name>bucket-a</Name><CreationDate>2024-01-01T00:00:00.000Z</CreationDate></Bucket>
    <Bucket><Name>bucket-b</Name><CreationDate>2024-06-01T00:00:00.000Z</CreationDate></Bucket>
  </Buckets>
</ListAllMyBucketsResult>
XML

  no warnings 'redefine';
  local *Amazon::S3::Lite::_request = mock_request(
    content => $xml,
    capture => \$captured,
  );

  my $r = $s3->list_buckets;

  is $captured->{method}, 'GET',                       'method is GET';
  is $captured->{url},    'https://s3.amazonaws.com/', 'hits root endpoint';
  is $captured->{region}, 'us-east-1',                 'always signs with us-east-1';
  is $s3->region,         'eu-west-1',                 'object region unchanged';

  is $r->{owner_id},            'owner123', 'owner_id';
  is $r->{owner_name},          'rob',      'owner_name';
  is scalar @{ $r->{buckets} }, 2,          '2 buckets';
  is $r->{buckets}[0]{name},    'bucket-a', 'first bucket name';
  is $r->{buckets}[1]{name},    'bucket-b', 'second bucket name';
  ok $r->{buckets}[0]{creation_date}, 'creation_date present';

  # error handling
  local *Amazon::S3::Lite::_request = mock_request( status => 403 );
  eval { $s3->list_buckets };
  like $@, qr/list_buckets failed/, '403 croaks';
};

subtest 'list_objects_v2' => sub {
  my $s3  = new_s3();
  my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>test-bucket</Name>
  <Prefix>logs/</Prefix>
  <KeyCount>2</KeyCount>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <Contents>
    <Key>logs/2024-01-01.gz</Key>
    <LastModified>2024-01-01T00:00:00.000Z</LastModified>
    <ETag>&quot;abc123&quot;</ETag>
    <Size>1024</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>
  <Contents>
    <Key>logs/2024-01-02.gz</Key>
    <LastModified>2024-01-02T00:00:00.000Z</LastModified>
    <ETag>&quot;def456&quot;</ETag>
    <Size>2048</Size>
    <StorageClass>STANDARD</StorageClass>
  </Contents>
</ListBucketResult>
XML

  my $captured = {};
  no warnings 'redefine';
  local *Amazon::S3::Lite::_request = mock_request(
    content => $xml,
    capture => \$captured,
  );

  my $r = $s3->list_objects_v2( 'test-bucket', prefix => 'logs/' );

  like $captured->{url}, qr/test-bucket/,    'bucket in URL';
  like $captured->{url}, qr/list-type=2/,    'list-type=2 in query';
  like $captured->{url}, qr/prefix=logs%2F/, 'prefix encoded in query';

  is $r->{bucket},       'test-bucket', 'bucket';
  is $r->{prefix},       'logs/',       'prefix';
  is $r->{key_count},    2,             'key_count is integer';
  is $r->{is_truncated}, 0,             'not truncated';
  ok !defined $r->{next_continuation_token}, 'no next token when not truncated';
  is scalar @{ $r->{objects} }, 2, '2 objects';

  my $obj = $r->{objects}[0];
  is $obj->{key},  'logs/2024-01-01.gz', 'key';
  is $obj->{size}, 1024,                 'size is integer';
  is $obj->{etag}, 'abc123',             'etag stripped of quotes';

  # missing bucket croaks
  eval { $s3->list_objects_v2() };
  like $@, qr/bucket is required/, 'croaks without bucket';

  # 404 returns undef
  local *Amazon::S3::Lite::_request = mock_request( status => 404 );
  my $not_found = $s3->list_objects_v2('no-such-bucket');
  ok !defined $not_found, '404 returns undef';
};

subtest 'list_all_objects_v2 pagination' => sub {
  my $s3   = new_s3();
  my $page = 0;

  no warnings 'redefine';
  local *Amazon::S3::Lite::list_objects_v2 = sub {
    my ( $self, $bucket, %opts ) = @_;
    $page++;
    if ( $page == 1 ) {
      ok !exists $opts{continuation_token}, 'no token on first page';
      return {
        objects                 => [ { key => 'file1.txt', size => 100 } ],
        is_truncated            => 1,
        next_continuation_token => 'TOKEN',
        common_prefixes         => [],
      };
    }
    is $opts{continuation_token}, 'TOKEN', 'token passed on page 2';
    return {
      objects                 => [ { key => 'file2.txt', size => 200 } ],
      is_truncated            => 0,
      next_continuation_token => undef,
      common_prefixes         => [],
    };
  };

  my @all = $s3->list_all_objects_v2('test-bucket');
  is scalar @all,  2,           'all objects returned';
  is $all[0]{key}, 'file1.txt', 'first key';
  is $all[1]{key}, 'file2.txt', 'second key';
  is $page,        2,           'fetched 2 pages';

  # delimiter stripped
  $page = 0;
  local *Amazon::S3::Lite::list_objects_v2 = sub {
    my ( $self, $bucket, %opts ) = @_;
    ok !exists $opts{delimiter}, 'delimiter removed';
    return { objects => [], is_truncated => 0 };
  };
  $s3->list_all_objects_v2( 'test-bucket', delimiter => '/' );
};

subtest 'head_object' => sub {
  my $s3 = new_s3();

  no warnings 'redefine';

  # 404 returns undef
  local *Amazon::S3::Lite::_request = mock_request( status => 404 );
  ok !defined $s3->head_object( 'b', 'k' ), '404 returns undef';

  # success
  local *Amazon::S3::Lite::_request = mock_request(
    headers => {
      'content-type'      => 'text/plain',
      'content-length'    => '42',
      'etag'              => '"abc123"',
      'last-modified'     => 'Wed, 01 Jan 2025 00:00:00 GMT',
      'x-amz-meta-source' => 'lambda',
    },
  );
  my $r = $s3->head_object( 'test-bucket', 'hello.txt' );
  is $r->{content_type},   'text/plain', 'content_type';
  is $r->{content_length}, 42,           'content_length is integer';
  is $r->{etag},           'abc123',     'etag stripped of quotes';
  ok !exists $r->{content}, 'no content key for HEAD';
  is $r->{metadata}{source}, 'lambda', 'x-amz-meta stripped to bare key';

  # missing args
  eval { $s3->head_object() };
  like $@, qr/bucket is required/, 'croaks without bucket';
  eval { $s3->head_object('b') };
  like $@, qr/key is required/, 'croaks without key';
};

subtest 'get_object' => sub {
  my $s3 = new_s3();

  no warnings 'redefine';

  # 404 returns undef
  local *Amazon::S3::Lite::_request = mock_request( status => 404 );
  ok !defined $s3->get_object( 'b', 'k' ), '404 returns undef';

  # in-memory success
  local *Amazon::S3::Lite::_request = mock_request(
    content => 'hello world',
    headers => {
      'content-type'   => 'text/plain',
      'content-length' => '11',
      'etag'           => '"abc123"',
      'last-modified'  => 'Wed, 01 Jan 2025 00:00:00 GMT',
    },
  );
  my $r = $s3->get_object( 'test-bucket', 'hello.txt' );
  is $r->{content},      'hello world', 'content returned';
  is $r->{content_type}, 'text/plain',  'content_type';
  is $r->{etag},         'abc123',      'etag clean';

  # range header passed through
  my $captured = {};
  local *Amazon::S3::Lite::_request = mock_request(
    status  => 206,
    content => 'hello',
    headers => { 'content-type' => 'text/plain', 'content-length' => '5', 'etag' => '"abc"' },
    capture => \$captured,
  );
  $s3->get_object( 'test-bucket', 'hello.txt', range => 'bytes=0-4' );
  is $captured->{headers}{Range}, 'bytes=0-4', 'Range header set';

  # filename — streaming to disk
  {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    close $fh;

    local *Amazon::S3::Lite::_request = sub {
      my ( $self, $method, $url, $headers, $content, $extra ) = @_;
      $extra->{data_callback}->('hello ') if $extra->{data_callback};
      $extra->{data_callback}->('world')  if $extra->{data_callback};
      return {
        status  => 200,
        reason  => 'OK',
        headers => { 'content-type' => 'text/plain', 'content-length' => '11', 'etag' => '"abc"' },
        content => '',
      };
    };

    my $meta = $s3->get_object( 'test-bucket', 'hello.txt', filename => $fname );
    ok !exists $meta->{content}, 'no content key when filename used';
    ok -f $fname,                'file created';
    open my $in, '<', $fname or die $!;
    is do { local $/; <$in> }, 'hello world', 'file content correct';
  }
};

subtest 'put_object' => sub {
  my $s3       = new_s3();
  my $captured = {};

  no warnings 'redefine';

  # scalar
  local *Amazon::S3::Lite::_request = mock_request(
    headers => { etag => '"newetag"' },
    capture => \$captured,
  );
  my $etag = $s3->put_object(
    'test-bucket', 'hello.txt', 'hello world',
    content_type => 'text/plain',
    metadata     => { source => 'test' },
  );
  is $etag,                                     'newetag',    'returns clean etag';
  is $captured->{headers}{'Content-Type'},      'text/plain', 'Content-Type set';
  is $captured->{headers}{'Content-Length'},    11,           'Content-Length set';
  is $captured->{headers}{'x-amz-meta-source'}, 'test',       'metadata prefixed';
  ok defined $captured->{headers}{'Content-MD5'}, 'Content-MD5 set for scalar';

  # scalar ref
  local *Amazon::S3::Lite::_request = mock_request(
    headers => { etag => '"x"' },
    capture => \$captured,
  );
  my $data = 'from scalar ref';
  $s3->put_object( 'test-bucket', 'k', \$data );
  is $captured->{body}, $data, 'scalar ref dereferenced';

  # real filehandle
  {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    print $fh 'file content';
    close $fh;
    open my $rfh, '<', $fname or die $!;

    local *Amazon::S3::Lite::_request = mock_request(
      headers => { etag => '"x"' },
      capture => \$captured,
    );
    $s3->put_object( 'test-bucket', 'k', $rfh );
    is ref( $captured->{body} ), 'CODE', 'filehandle wrapped in code ref';
    ok defined $captured->{headers}{'Content-Length'}, 'Content-Length from stat';
    ok !defined $captured->{headers}{'Content-MD5'},   'no MD5 for filehandle';
    close $rfh;
  }

  # in-memory fh without content_length
  {
    use IO::Scalar;
    my $d  = 'hello';
    my $fh = IO::Scalar->new( \$d );
    eval { $s3->put_object( 'test-bucket', 'k', $fh ) };
    like $@, qr/content_length is required/, 'in-memory fh needs content_length';
  }

  # acl
  local *Amazon::S3::Lite::_request = mock_request(
    headers => { etag => '"x"' },
    capture => \$captured,
  );
  $s3->put_object( 'test-bucket', 'k', 'data', acl => 'public-read' );
  is $captured->{headers}{'x-amz-acl'}, 'public-read', 'acl header set';

  # missing args
  eval { $s3->put_object() };
  like $@, qr/bucket is required/, 'croaks without bucket';
  eval { $s3->put_object('b') };
  like $@, qr/key is required/, 'croaks without key';
  eval { $s3->put_object( 'b', 'k' ) };
  like $@, qr/data is required/, 'croaks without data';
};

subtest 'delete_object' => sub {
  my $s3       = new_s3();
  my $captured = {};

  no warnings 'redefine';
  local *Amazon::S3::Lite::_request = mock_request(
    status  => 204,
    capture => \$captured,
  );

  my $r = $s3->delete_object( 'test-bucket', 'hello.txt' );
  is $r,                  1,        'returns 1 on success';
  is $captured->{method}, 'DELETE', 'method is DELETE';
  like $captured->{url}, qr{test-bucket/hello\.txt}, 'URL correct';
  ok( $captured->{url} !~ /versionId/, 'no versionId without option' );

  # version_id
  $s3->delete_object( 'test-bucket', 'hello.txt', version_id => 'v123' );
  like $captured->{url}, qr/versionId=v123/, 'versionId in URL';

  # version_id with special chars
  $s3->delete_object( 'test-bucket', 'hello.txt', version_id => 'v 1+2' );
  like $captured->{url}, qr/versionId=v%201/, 'version_id encoded';

  # 5xx croaks
  local *Amazon::S3::Lite::_request = mock_request( status => 500 );
  eval { $s3->delete_object( 'test-bucket', 'hello.txt' ) };
  like $@, qr/delete_object failed/, '5xx croaks';

  # missing args
  eval { $s3->delete_object() };
  like $@, qr/bucket is required/, 'croaks without bucket';
  eval { $s3->delete_object('b') };
  like $@, qr/key is required/, 'croaks without key';
};

subtest 'copy_object' => sub {
  my $s3          = new_s3();
  my $captured    = {};
  my $success_xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<CopyObjectResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <LastModified>2024-01-01T00:00:00.000Z</LastModified>
  <ETag>&quot;copietag&quot;</ETag>
</CopyObjectResult>
XML

  no warnings 'redefine';
  local *Amazon::S3::Lite::_request = mock_request(
    content => $success_xml,
    capture => \$captured,
  );

  my $r = $s3->copy_object(
    src_bucket => 'src-bucket',
    src_key    => 'orig/file.json',
    dst_bucket => 'dst-bucket',
    dst_key    => 'copy/file.json',
  );

  is $captured->{method}, 'PUT', 'method is PUT';
  like $captured->{url},                          qr{dst-bucket/copy/file\.json}, 'dst URL correct';
  like $captured->{headers}{'x-amz-copy-source'}, qr{src-bucket/orig/file\.json}, 'copy-source header set';
  is $captured->{headers}{'Content-Length'}, 0, 'Content-Length is 0';

  is $r->{etag},          'copietag',                 'etag clean';
  is $r->{last_modified}, '2024-01-01T00:00:00.000Z', 'last_modified';

  # special chars in src_key
  $s3->copy_object(
    src_bucket => 'src',
    src_key    => 'path/my file.txt',
    dst_bucket => 'dst',
    dst_key    => 'copy.txt',
  );
  like $captured->{headers}{'x-amz-copy-source'}, qr/%20/,   'spaces encoded in copy-source';
  like $captured->{headers}{'x-amz-copy-source'}, qr{path/}, 'slashes preserved';

  # 200-with-error body
  my $error_xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>InternalError</Code>
  <Message>Something went wrong</Message>
</Error>
XML
  local *Amazon::S3::Lite::_request = mock_request( content => $error_xml );
  eval { $s3->copy_object( src_bucket => 'src', src_key => 'k', dst_bucket => 'dst', dst_key => 'k2', ); };
  like $@, qr/copy_object failed.*InternalError/, '200-with-error body croaks';

  # missing required args
  for my $missing (qw(src_bucket src_key dst_bucket dst_key)) {
    my %args = (
      src_bucket => 'src',
      src_key    => 'k',
      dst_bucket => 'dst',
      dst_key    => 'k2',
    );
    delete $args{$missing};
    eval { $s3->copy_object(%args) };
    like $@, qr/$missing is required/, "croaks without $missing";
  }
};

subtest 'error XML body extracted' => sub {
  my $s3        = new_s3();
  my $error_xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>AccessDenied</Code>
  <Message>Access Denied</Message>
</Error>
XML
  no warnings 'redefine';
  local *Amazon::S3::Lite::_request = mock_request(
    status  => 403,
    content => $error_xml,
  );
  eval { $s3->list_buckets };
  like $@, qr/AccessDenied/,  'error Code extracted from XML body';
  like $@, qr/Access Denied/, 'error Message extracted from XML body';
};

subtest 'list_objects_v2 with common_prefixes' => sub {
  my $s3  = new_s3();
  my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?>
<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Name>test-bucket</Name>
  <Prefix>logs/</Prefix>
  <KeyCount>0</KeyCount>
  <MaxKeys>1000</MaxKeys>
  <IsTruncated>false</IsTruncated>
  <CommonPrefixes><Prefix>logs/2024/</Prefix></CommonPrefixes>
  <CommonPrefixes><Prefix>logs/2025/</Prefix></CommonPrefixes>
</ListBucketResult>
XML

  no warnings 'redefine';
  local *Amazon::S3::Lite::_request = mock_request( content => $xml );
  my $r = $s3->list_objects_v2( 'test-bucket', prefix => 'logs/', delimiter => '/' );
  is $r->{prefix},                      'logs/',      'root prefix correct';
  is scalar @{ $r->{common_prefixes} }, 2,            'two common prefixes';
  is $r->{common_prefixes}[0],          'logs/2024/', 'first common prefix';
};

########################################################################
# Integration tests — require LocalStack
########################################################################

SKIP: {
  skip 'LocalStack not available', 5 unless localstack_available();

  my $s3 = new_localstack_s3();

  my $r            = eval { $s3->list_buckets };
  my @bucket_names = map { $_->{name} } @{ $r->{buckets} // [] };

  skip 'test-bucket not found in LocalStack - create it first', 5
    if !grep { $_ eq 'test-bucket' } @bucket_names;

  # Each subtest is wrapped in eval so one failure doesn't kill the harness
  subtest 'LocalStack - list_buckets' => sub {
    my $r = eval { $s3->list_buckets };
    if ($@) { fail "list_buckets threw: $@"; return }
    ok ref $r->{buckets} eq 'ARRAY', 'buckets is arrayref';
    my @names = map { $_->{name} } @{ $r->{buckets} };
    ok( ( grep { $_ eq 'test-bucket' } @names ), 'test-bucket exists' );
  };

  subtest 'LocalStack - put, head, get, delete' => sub {
    my $key     = 'test/hello.txt';
    my $content = 'Hello from Amazon::S3::Lite!';

    # put
    my $etag = $s3->put_object(
      'test-bucket', $key, $content,
      content_type => 'text/plain',
      metadata     => { author => 'rob' },
    );
    ok defined $etag, 'put_object returns etag';

    # head
    my $meta = $s3->head_object( 'test-bucket', $key );
    ok defined $meta, 'head_object finds the object';
    is $meta->{content_type},     'text/plain',     'content_type correct';
    is $meta->{content_length},   length($content), 'content_length correct';
    is $meta->{metadata}{author}, 'rob',            'metadata preserved';

    # get in-memory
    my $obj = $s3->get_object( 'test-bucket', $key );
    ok defined $obj, 'get_object finds the object';
    is $obj->{content}, $content, 'content matches';
    is $obj->{etag},    $etag,    'etag matches';

    # get to file
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    close $fh;
    my $file_meta = $s3->get_object( 'test-bucket', $key, filename => $fname );
    ok defined $file_meta,            'get_object with filename returns meta';
    ok !exists $file_meta->{content}, 'no content key';
    open my $in, '<', $fname or die $!;
    is do { local $/; <$in> }, $content, 'file content correct';

    # 404
    my $missing = $s3->get_object( 'test-bucket', 'no/such/key.txt' );
    ok !defined $missing, '404 returns undef';

    # delete
    ok $s3->delete_object( 'test-bucket', $key ), 'delete_object returns true';

    # confirm gone
    my $gone = $s3->head_object( 'test-bucket', $key );
    ok !defined $gone, 'object gone after delete';
  };

  subtest 'LocalStack - list_objects_v2' => sub {
    # seed some objects
    for my $i ( 1 .. 3 ) {
      $s3->put_object( 'test-bucket', "list-test/file$i.txt", "content $i" );
    }

    my $r = $s3->list_objects_v2( 'test-bucket', prefix => 'list-test/' );
    ok $r->{key_count} >= 3, 'at least 3 objects';
    my @keys = map { $_->{key} } @{ $r->{objects} };
    ok( ( grep { $_ eq 'list-test/file1.txt' } @keys ), 'file1 in list' );

    # list_all_objects_v2
    my @all = $s3->list_all_objects_v2( 'test-bucket', prefix => 'list-test/' );
    ok scalar @all >= 3, 'list_all returns all objects';

    # max_keys pagination
    my $page = $s3->list_objects_v2(
      'test-bucket',
      prefix   => 'list-test/',
      max_keys => 2,
    );
    is scalar @{ $page->{objects} }, 2, 'max_keys respected';

    my @all_paginated = $s3->list_all_objects_v2(
      'test-bucket',
      prefix   => 'list-test/',
      max_keys => 2,
    );
    ok scalar @all_paginated >= 3, 'list_all_objects_v2 auto-paginates correctly';

    # cleanup
    for my $obj (@all) {
      $s3->delete_object( 'test-bucket', $obj->{key} );
    }
  };

  subtest 'LocalStack - copy_object' => sub {
    $s3->put_object( 'test-bucket', 'copy-src.txt', 'original content' );

    my $r = $s3->copy_object(
      src_bucket => 'test-bucket',
      src_key    => 'copy-src.txt',
      dst_bucket => 'test-bucket',
      dst_key    => 'copy-dst.txt',
    );
    ok defined $r->{etag}, 'copy_object returns etag';

    my $dst = $s3->get_object( 'test-bucket', 'copy-dst.txt' );
    is $dst->{content}, 'original content', 'copied content matches';

    $s3->delete_object( 'test-bucket', 'copy-src.txt' );
    $s3->delete_object( 'test-bucket', 'copy-dst.txt' );
  };

  subtest 'LocalStack - put_object with filehandle' => sub {
    my ( $fh, $fname ) = tempfile( UNLINK => 1 );
    print $fh 'filehandle content';
    close $fh;

    open my $rfh, '<', $fname or die $!;
    my $etag = $s3->put_object( 'test-bucket', 'fh-test.txt', $rfh, content_type => 'text/plain', );
    close $rfh;

    ok defined $etag, 'put with filehandle returns etag';
    my $obj = $s3->get_object( 'test-bucket', 'fh-test.txt' );
    is $obj->{content}, 'filehandle content', 'filehandle content correct';

    $s3->delete_object( 'test-bucket', 'fh-test.txt' );
  };
}

done_testing;
