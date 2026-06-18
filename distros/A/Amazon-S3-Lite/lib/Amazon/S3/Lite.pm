package Amazon::S3::Lite;

use strict;
use warnings;

use Amazon::Signature4::Lite;
use Amazon::S3::Lite::Credentials;
use Amazon::S3::Lite::Logger;
use Carp qw(croak);
use Data::Dumper;
use Digest::MD5 qw(md5_base64 md5);
use English qw(-no_match_vars);
use HTTP::Tiny;
use List::Util qw(pairs);
use MIME::Base64 qw(encode_base64);
use Scalar::Util qw(blessed openhandle);
use URI::Escape qw(uri_escape_utf8);
use XML::Twig;

use Readonly;

Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

our $VERSION = '1.2.0';

########################################################################
sub new {
########################################################################
  my ( $class, $args ) = @_;

  $args //= {};

  croak 'new() requires a hashref'
    if ref $args ne 'HASH';

  croak 'region is required'
    if !$args->{region};

  my $self = bless {}, $class;

  $self->{region}  = $args->{region};
  $self->{host}    = $args->{host}    // 's3.amazonaws.com';
  $self->{secure}  = $args->{secure}  // 1;
  $self->{timeout} = $args->{timeout} // 30;

  $self->_init_logger( $args->{logger} );
  $self->_init_credentials($args);
  $self->_init_ua;

  return $self;
}

########################################################################
# Logger setup
# Priority: caller-supplied object -> Log::Log4perl (if available) ->
#           minimal STDERR logger
########################################################################
sub _init_logger {
########################################################################
  my ( $self, $logger ) = @_;

  if ($logger) {
    # Validate it quacks like a logger
    for my $method (qw(trace debug info warn error)) {
      croak "logger object must implement '$method'"
        if !$logger->can($method);
    }
    $self->{logger} = $logger;
    return;
  }

  if ( eval { require Log::Log4perl; 1 } ) {
    if ( !Log::Log4perl->initialized ) {
      Log::Log4perl->easy_init($Log::Log4perl::WARN);
    }
    $self->{logger} = Log::Log4perl->get_logger(__PACKAGE__);
    return;
  }

  # Fall back to minimal STDERR logger
  $self->{logger} = Amazon::S3::Lite::Logger->new;

  return;
}

########################################################################
# Credential resolution
# Priority: explicit credentials object -> constructor args ->
#           environment variables -> Amazon::Credentials (if available)
########################################################################
sub _init_credentials {
########################################################################
  my ( $self, $args ) = @_;

  # 1. Caller-supplied credentials object (duck-typed)
  if ( my $creds = $args->{credentials} ) {
    croak "credential object is not blessed.\n"
      if !blessed $creds;

    foreach (qw(aws_access_key_id aws_secret_access_key token)) {
      my $sub = $creds->can($_) // $creds->can("get_$_");

      croak "credentials object must implement $_ or get_$_\n"
        if !$sub;
    }

    $self->{credentials} = $creds;

    return;
  }

  # 2. Explicit constructor args
  if ( $args->{aws_access_key_id} && $args->{aws_secret_access_key} ) {
    $self->{credentials} = Amazon::S3::Lite::Credentials->new(
      aws_access_key_id     => $args->{aws_access_key_id},
      aws_secret_access_key => $args->{aws_secret_access_key},
      token                 => $args->{token},
    );
    return;
  }

  # 3. Environment variables
  if ( $ENV{AWS_ACCESS_KEY_ID} && $ENV{AWS_SECRET_ACCESS_KEY} ) {
    $self->{credentials} = Amazon::S3::Lite::Credentials->new(
      aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
      aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
      token                 => $ENV{AWS_SESSION_TOKEN},
    );
    return;
  }

  # 4. Amazon::Credentials (covers IAM roles, ECS task roles,
  #    ~/.aws/credentials, etc.)
  if ( eval { require Amazon::Credentials; 1 } ) {
    $self->{credentials} = Amazon::Credentials->new;
    return;
  }

  croak 'No AWS credentials found. Supply aws_access_key_id/'
    . 'aws_secret_access_key, set AWS_ACCESS_KEY_ID/'
    . 'AWS_SECRET_ACCESS_KEY environment variables, '
    . 'or install Amazon::Credentials for IAM role support.';
}

########################################################################
# HTTP::Tiny instance - one per object, keep-alive enabled
########################################################################
sub _init_ua {
########################################################################
  my ($self) = @_;

  $self->{ua} = HTTP::Tiny->new(
    timeout    => $self->{timeout},
    verify_SSL => $self->{secure},
  );

  return;
}

########################################################################
# Accessors
########################################################################
sub logger      { return $_[0]->{logger} }
sub ua          { return $_[0]->{ua} }
sub region      { return $_[0]->{region} }
sub host        { return $_[0]->{host} }
sub credentials { return $_[0]->{credentials} }

########################################################################
# Build a fresh signer from current credentials.
# Called per-request so that rotating credentials (Lambda IAM roles)
# are always current.
########################################################################
sub _signer {
########################################################################
  my ( $self, $region ) = @_;

  my $creds = $self->credentials;

  my $access_key
    = $creds->can('get_aws_access_key_id')
    ? $creds->get_aws_access_key_id
    : $creds->aws_access_key_id;

  my $secret_key
    = $creds->can('get_aws_secret_access_key')
    ? $creds->get_aws_secret_access_key
    : $creds->aws_secret_access_key;

  my $token_sub = $creds->can('get_token') // $creds->can('token');
  my $token     = $token_sub ? $token_sub->($creds) : undef;

  return Amazon::Signature4::Lite->new(
    access_key    => $access_key,
    secret_key    => $secret_key,
    session_token => $token,
    region        => $region // $self->region,
    service       => 's3',
  );
}

########################################################################
# Build the endpoint URL for a bucket/key
########################################################################
sub _endpoint {
########################################################################
  my ( $self, $bucket, $key ) = @_;

  my $scheme = $self->{secure} ? 'https' : 'http';
  my $host   = $self->host;

  # Path-style URL: https://s3.amazonaws.com/bucket/key
  # (virtual-hosted style omitted for simplicity; path-style works
  # everywhere and avoids SSL cert issues with dotted bucket names)
  my $url = "$scheme://$host";

  $url .= "/$bucket"              if defined $bucket && length $bucket;
  $url .= '/' . _encode_key($key) if defined $key    && length $key;

  return $url;
}

########################################################################
# URI-encode an S3 key, preserving '/' separators
########################################################################
sub _encode_key {
########################################################################
  my ($key) = @_;

  return join '/', map { uri_escape_utf8( $_, '^A-Za-z0-9\-._~' ) }
    split m{/}, $key, -1;
}

########################################################################
sub _request {
########################################################################
  my ( $self, $method, $url, $headers, $content, $extra, $region ) = @_;

  $region  //= $self->region;
  $headers //= {};
  $content //= q{};
  $extra   //= {};

  my $content_is_coderef = ref $content eq 'CODE';

  # sign — returns merged headers ready for HTTP::Tiny
  my $signed = $self->_signer($region)->sign(
    method  => $method,
    url     => $url,
    headers => $headers,
    payload => $content_is_coderef ? q{} : $content,
  );

  # HTTP::Tiny sets Host itself — remove to avoid duplicate header error
  delete $signed->{host};

  $self->logger->debug("$method $url");

  my $options = { headers => $signed };

  if ( length $content || $content_is_coderef ) {
    $options->{content} = $content;
  }

  if ( $extra->{data_callback} ) {
    $options->{data_callback} = $extra->{data_callback};
  }

  my $response = $self->ua->request( $method, $url, $options );

  $self->logger->debug( sprintf 'Response: %s %s', $response->{status}, $response->{reason} );

  return $response;
}

########################################################################
# head_object( $bucket, $key )
#
# Fetches metadata for an object without retrieving the body.
# Returns undef if the key does not exist (404).
# Returns a hashref with content_type, content_length, etag,
# last_modified, and metadata (x-amz-meta-* headers).
########################################################################
sub head_object {
########################################################################
  my ( $self, $bucket, $key ) = @_;

  croak 'bucket is required' if !defined $bucket || !length $bucket;
  croak 'key is required'    if !defined $key    || !length $key;

  my $url      = $self->_endpoint( $bucket, $key );
  my $response = $self->_request( 'HEAD', $url );

  return undef ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    if _is_not_found($response);

  $self->_croak_on_error( $response, 'head_object' );

  return $self->_extract_object_metadata( $response->{headers} );
}

########################################################################
# Extract the standard object metadata hashref from a response headers
# hash. Used by both head_object and get_object.
########################################################################
sub _extract_object_metadata {
########################################################################
  my ( $self, $headers ) = @_;

  my $etag = $headers->{etag};
  $etag =~ s/\A"|"\z//gxsm if defined $etag;

  # Collect x-amz-meta-* headers, stripping the prefix from the key
  my %metadata;
  for my $name ( keys %{$headers} ) {
    if ( $name =~ /^x-amz-meta-(.+)$/xsm ) {
      $metadata{$1} = $headers->{$name};
    }
  }

  return {
    content_type   => $headers->{'content-type'},
    content_length => $headers->{'content-length'} + 0,
    etag           => $etag,
    last_modified  => $headers->{'last-modified'},
    metadata       => \%metadata,
  };
}

########################################################################
# get_object( $bucket, $key, %options )
#
# Fetches an object from S3. Options:
#   range    => 'bytes=0-1023'   partial fetch
#   filename => '/tmp/foo'       stream body to disk; omits content key
#
# Returns undef on 404.
# Returns a hashref with content_type, content_length, etag,
# last_modified, metadata, and content (unless filename is used).
########################################################################
sub get_object {
########################################################################
  my ( $self, $bucket, $key, %options ) = @_;

  croak 'bucket is required' if !defined $bucket || !length $bucket;
  croak 'key is required'    if !defined $key    || !length $key;

  my $url = $self->_endpoint( $bucket, $key );

  my %headers;
  $headers{Range} = $options{range} if defined $options{range};

  my $filename = $options{filename};
  my $extra    = {};

  if ( defined $filename ) {
    # Open the destination file before making the request so we catch
    # permission errors early, before network round-trip
    open my $fh, '>', $filename
      or croak "cannot open '$filename' for writing: $!";

    $extra->{data_callback} = sub {
      my ($data) = @_;
      print {$fh} $data
        or croak "write to '$filename' failed: $!";
    };

    my $response = $self->_request( 'GET', $url, \%headers, q{}, $extra );

    close $fh
      or croak "close of '$filename' failed: $!";

    return undef ## no critic (Subroutines::ProhibitExplicitReturnUndef)
      if _is_not_found($response);

    $self->_croak_on_error( $response, 'get_object' );

    # Return metadata only — content is on disk
    return $self->_extract_object_metadata( $response->{headers} );
  }

  # In-memory path
  my $response = $self->_request( 'GET', $url, \%headers );

  return undef ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    if _is_not_found($response);

  $self->_croak_on_error( $response, 'get_object' );

  my $result = $self->_extract_object_metadata( $response->{headers} );
  $result->{content} = $response->{content};

  return $result;
}

########################################################################
# delete_object( $bucket, $key, %options )
#
# Deletes an object from S3. Options:
#   version_id => $vid    delete a specific version
#
# Returns true on success. Note S3 returns 204 for both successful
# deletes and deletes of non-existent keys — no distinction is made.
# Croaks on network or server errors.
########################################################################
sub delete_object {
########################################################################
  my ( $self, $bucket, $key, %options ) = @_;

  croak 'bucket is required' if !defined $bucket || !length $bucket;
  croak 'key is required'    if !defined $key    || !length $key;

  my $url = $self->_endpoint( $bucket, $key );

  if ( defined $options{version_id} ) {
    $url .= '?versionId=' . uri_escape_utf8( $options{version_id} );
  }

  my $response = $self->_request( 'DELETE', $url );

  $self->_croak_on_error( $response, 'delete_object' );

  return 1;
}

########################################################################
# create_bucket( $bucket, %options )
#
# Creates a new S3 bucket.
#
# us-east-1 is the S3 default region — the CreateBucketConfiguration
# body must NOT be sent for us-east-1 (S3 will error). All other regions
# require it with LocationConstraint set to the target region.
#
# Options: acl, region
#
# Returns true on success. Croaks on failure.
########################################################################
sub create_bucket {
########################################################################
  my ( $self, $bucket, %options ) = @_;

  croak 'bucket is required'
    if !defined $bucket || !length $bucket;

  my $region = $options{region} // $self->region;
  my $url    = $self->_endpoint($bucket);
  my %headers;

  $headers{'x-amz-acl'} = $options{acl} if $options{acl};

  my $content = q{};

  # us-east-1 is the implicit default — sending LocationConstraint for it
  # causes an error. All other regions require it.
  if ( $region ne 'us-east-1' ) {
    $content
      = sprintf '<CreateBucketConfiguration '
      . 'xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
      . '<LocationConstraint>%s</LocationConstraint>'
      . '</CreateBucketConfiguration>',
      $region;
    $headers{'Content-Type'}   = 'application/xml';
    $headers{'Content-Length'} = length $content;
  }

  my $response = $self->_request( 'PUT', $url, \%headers, $content, {}, $region );

  $self->_croak_on_error( $response, 'create_bucket' );

  return 1;
}

########################################################################
# list_buckets()
#
# Lists all buckets owned by the authenticated user.
#
# Note: ListBuckets is a global S3 operation and must always be signed
# against us-east-1 regardless of the region the object was constructed
# with. We pass the region override directly to the signer.
#
# Returns a hashref:
#   {
#     owner_id   => '...',
#     owner_name => '...',
#     buckets    => [
#       { name => '...', creation_date => '...' },
#       ...
#     ],
#   }
########################################################################
sub list_buckets {
########################################################################
  my ($self) = @_;

  my $url = $self->_endpoint . q{/};  # ensure canonical URI is / not empty

  my $response = $self->_request( 'GET', $url, {}, q{}, {}, 'us-east-1' );

  $self->_croak_on_error( $response, 'list_buckets' );

  return $self->_parse_list_buckets( $response->{content} );
}

########################################################################
# Parse ListAllMyBucketsResult XML
########################################################################
########################################################################
sub _parse_list_buckets {
########################################################################
  my ( $self, $xml ) = @_;

  my ( @buckets, $owner_id, $owner_name );

  XML::Twig->new(
    twig_handlers => {
      'Bucket' => sub {
        my ( $t, $node ) = @_;
        push @buckets,
          {
          name          => $node->first_child_text('Name'),
          creation_date => $node->first_child_text('CreationDate'),
          };
      },
      'Owner' => sub {
        my ( $t, $node ) = @_;
        $owner_id   = $node->first_child_text('ID');
        $owner_name = $node->first_child_text('DisplayName');
      },
    }
  )->parse($xml);

  return {
    owner_id   => $owner_id,
    owner_name => $owner_name,
    buckets    => \@buckets,
  };
}

########################################################################
# copy_object( %args )
#
# Copies an object within or between buckets, entirely server-side.
# Required: src_bucket, src_key, dst_bucket, dst_key
#
# Note: S3 can return HTTP 200 with an XML error body for copy operations
# that fail mid-transfer. This method detects and croaks on that case.
#
# Returns a hashref: { etag => '...', last_modified => '...' }
########################################################################
sub copy_object {
########################################################################
  my ( $self, %args ) = @_;

  for my $required (qw( src_bucket src_key dst_bucket dst_key )) {
    croak "$required is required"
      if !defined $args{$required} || !length $args{$required};
  }

  my $url = $self->_endpoint( $args{dst_bucket}, $args{dst_key} );

  # x-amz-copy-source: /src-bucket/encoded-key
  my $copy_source = '/' . $args{src_bucket} . '/' . _encode_key( $args{src_key} );

  my %headers = (
    'x-amz-copy-source'       => $copy_source,
    'x-amz-tagging-directive' => 'COPY',
    'Content-Length'          => 0,
  );

  my $response = $self->_request( 'PUT', $url, \%headers );

  $self->_croak_on_error( $response, 'copy_object' );

  # S3 can return HTTP 200 with an XML error body for copies that fail
  # after the headers have been sent. Detect this by checking the root
  # element — a success response has <CopyObjectResult>, an error has <Error>.
  return $self->_parse_copy_response( $response->{content}, 'copy_object' );
}

########################################################################
# Parse CopyObjectResult XML, detecting the 200-with-error edge case
########################################################################
########################################################################
sub _parse_copy_response {
########################################################################
  my ( $self, $xml, $context ) = @_;

  my $twig = XML::Twig->new->parse($xml);
  my $root = $twig->root->tag;

  if ( $root eq 'Error' ) {
    my $code = $twig->root->first_child_text('Code');
    my $msg  = $twig->root->first_child_text('Message');
    croak sprintf '%s failed: %s - %s', $context, $code, $msg;
  }

  my $etag = $twig->root->first_child_text('ETag') // q{};
  $etag =~ s/\A"|"\z//gxsm;

  return {
    etag          => $etag,
    last_modified => $twig->root->first_child_text('LastModified'),
  };
}

########################################################################
# put_object( $bucket, $key, $data, %options )
#
# Stores an object in S3. $data may be a scalar string, a reference to
# a scalar, or an open filehandle / IO::File object.
#
# Options: content_type, content_length, metadata (hashref), acl
#
# Returns the ETag of the stored object. Croaks on failure.
########################################################################
sub put_object {
########################################################################
  my ( $self, $bucket, $key, $data, %options ) = @_;

  croak 'bucket is required' if !defined $bucket || !length $bucket;
  croak 'key is required'    if !defined $key    || !length $key;
  croak 'data is required'   if !defined $data;

  my $url = $self->_endpoint( $bucket, $key );

  my %headers;
  $headers{'Content-Type'} = $options{content_type} // 'application/octet-stream';

  # x-amz-acl header
  if ( $options{acl} ) {
    $headers{'x-amz-acl'} = $options{acl};
  }

  # User metadata — prefix bare keys with x-amz-meta-
  if ( my $meta = $options{metadata} ) {
    for my $k ( keys %{$meta} ) {
      my $header = $k =~ /^x-amz-meta-/xsm ? $k : "x-amz-meta-$k";
      $headers{$header} = $meta->{$k};
    }
  }

  my $body;

  if ( openhandle($data) || ( blessed($data) && $data->can('read') ) ) {
    # --- Filehandle path ---
    my $content_length = $options{content_length};

    # Try to stat the handle for real files; suppress warning on
    # in-memory handles (IO::Scalar etc.) that have no underlying fd
    if ( !defined $content_length ) {
      my $fd = eval { fileno($data) };
      if ( defined $fd && $fd >= 0 ) {
        my @st = stat $data;
        $content_length = $st[7] if @st && defined $st[7];
      }
    }

    croak 'content_length is required for in-memory filehandles'
      if !defined $content_length;

    $headers{'Content-Length'} = $content_length;

    # Wrap filehandle in a code ref for HTTP::Tiny streaming
    my $chunk_size = 1024 * 64;  # 64KB chunks
    $body = sub {
      my $buf;
      my $n = read( $data, $buf, $chunk_size );
      return $buf if $n;
      return q{};
    };
  }
  elsif ( ref $data eq 'SCALAR' ) {
    # --- Scalar ref path ---
    $body                      = ${$data};
    $headers{'Content-Length'} = length $body;
    $headers{'Content-MD5'}    = encode_base64( md5($body), q{} );
  }
  else {
    # --- Plain scalar path ---
    $body                      = $data;
    $headers{'Content-Length'} = length $body;
    $headers{'Content-MD5'}    = encode_base64( md5($body), q{} );
  }

  my $response = $self->_request( 'PUT', $url, \%headers, $body );

  $self->_croak_on_error( $response, 'put_object' );

  my $etag = $response->{headers}{etag};
  $etag =~ s/\A"|"\z//gxsm if defined $etag;

  return $etag;
}

########################################################################
# list_objects_v2( $bucket, %options )
#
# Lists objects in a bucket using the S3 ListObjectsV2 API.
# Returns a hashref with keys: bucket, prefix, key_count, max_keys,
# is_truncated, next_continuation_token, objects, common_prefixes.
########################################################################
sub list_objects_v2 {
########################################################################
  my ( $self, $bucket, %options ) = @_;

  croak 'bucket is required'
    if !defined $bucket || !length $bucket;

  # Map our option names to S3 query parameter names
  my %param_map = (
    prefix             => 'prefix',
    delimiter          => 'delimiter',
    max_keys           => 'max-keys',
    continuation_token => 'continuation-token',
    start_after        => 'start-after',
  );

  my %params = ( 'list-type' => '2' );

  for my $opt ( keys %param_map ) {
    if ( defined $options{$opt} ) {
      $params{ $param_map{$opt} } = $options{$opt};
    }
  }

  # Build query string
  my $query = join q{&}, map { uri_escape_utf8($_) . q{=} . uri_escape_utf8( $params{$_} ) }
    sort keys %params;

  my $url = $self->_endpoint($bucket) . q{?} . $query;

  my $response = $self->_request( 'GET', $url );

  return undef ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    if _is_not_found($response);

  $self->_croak_on_error( $response, 'list_objects_v2' );

  return $self->_parse_list_objects_v2( $response->{content} );
}

########################################################################
# Parse the XML body of a ListObjectsV2 response
########################################################################
########################################################################
sub _parse_list_objects_v2 {
########################################################################
  my ( $self, $xml ) = @_;

  my ( @objects, @common_prefixes );
  my ( $bucket, $prefix, $key_count, $max_keys, $is_truncated, $next_token );

  XML::Twig->new(
    twig_handlers => {
      'Name'                    => sub { $bucket       = $_[1]->text },
      'ListBucketResult/Prefix' => sub { $prefix       = $_[1]->text },
      'KeyCount'                => sub { $key_count    = $_[1]->text + 0 },
      'MaxKeys'                 => sub { $max_keys     = $_[1]->text + 0 },
      'IsTruncated'             => sub { $is_truncated = $_[1]->text eq 'true' ? 1 : 0 },
      'NextContinuationToken'   => sub { $next_token   = $_[1]->text },
      'Contents'                => sub {
        my ( $t, $node ) = @_;
        my $etag = $node->first_child_text('ETag') // q{};
        $etag =~ s/\A"|"\z//gxsm;
        push @objects,
          {
          key           => $node->first_child_text('Key'),
          size          => $node->first_child_text('Size') + 0,
          last_modified => $node->first_child_text('LastModified'),
          etag          => $etag,
          storage_class => $node->first_child_text('StorageClass'),
          };
        $t->purge;  # free memory as we go - important for large listings
      },
      'CommonPrefixes' => sub {
        my ( $t, $node ) = @_;
        push @common_prefixes, $node->first_child_text('Prefix');
      },
    }
  )->parse($xml);

  return {
    bucket                  => $bucket,
    prefix                  => $prefix,
    key_count               => $key_count,
    max_keys                => $max_keys,
    is_truncated            => $is_truncated,
    next_continuation_token => $next_token,
    objects                 => \@objects,
    common_prefixes         => \@common_prefixes,
  };
}

########################################################################
# list_all_objects_v2( $bucket, %options )
#
# Convenience wrapper that auto-paginates list_objects_v2 and returns
# a flat list of all matching object hashrefs.
# delimiter is ignored — use list_objects_v2 directly for that.
########################################################################
sub list_all_objects_v2 {
########################################################################
  my ( $self, $bucket, %options ) = @_;

  # delimiter is meaningless here — silently remove it
  delete $options{delimiter};

  my @all_objects;
  my $continuation_token;

  while ($TRUE) {
    if ( defined $continuation_token ) {
      $options{continuation_token} = $continuation_token;
    }

    my $result = $self->list_objects_v2( $bucket, %options );

    last if !$result;  # 404 / empty bucket

    push @all_objects, @{ $result->{objects} };

    last if !$result->{is_truncated};

    $continuation_token = $result->{next_continuation_token};
  }

  return @all_objects;
}

########################################################################
sub put_bucket_notification_configuration {
########################################################################
  my ( $self, $bucket, %options ) = @_;

  my $xml = $self->_create_notification_configuration( $bucket, %options );

  my $url = $self->_endpoint($bucket) . q{?notification=};

  my %headers = (
    'Content-Type'   => 'application/xml',
    'Content-Length' => length $xml,
    'Content-MD5'    => encode_base64( md5($xml), q{} ),
  );

  my $response = $self->_request( 'PUT', $url, \%headers, $xml );

  $self->_croak_on_error( $response, 'put_bucket_notification_configuration' );

  return $TRUE;
}

########################################################################
sub remove_bucket_notification_configuration {
########################################################################
  my ( $self, $bucket ) = @_;

  croak 'bucket is required'
    if !defined $bucket || !length $bucket;

  my $xml = <<'END_XML';
<NotificationConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"/>
END_XML

  my $url = $self->_endpoint($bucket) . q{?notification=};

  my %headers = (
    'Content-Type'   => 'application/xml',
    'Content-Length' => length $xml,
    'Content-MD5'    => encode_base64( md5($xml), q{} ),
  );

  my $response = $self->_request( 'PUT', $url, \%headers, $xml );

  $self->_croak_on_error( $response, 'remove_bucket_notification_configuration' );

  return $TRUE;
}

########################################################################
sub get_bucket_notification_configuration {
########################################################################
  my ( $self, $bucket ) = @_;

  croak 'bucket is required'
    if !defined $bucket || !length $bucket;

  my $url = $self->_endpoint($bucket) . q{?notification=};

  my $response = $self->_request( 'GET', $url );

  $self->_croak_on_error( $response, 'get_bucket_notification_configuration' );

  my $rsp = $self->_parse_notification_configuration( $response->{content} );

  $self->logger->debug(
    Dumper(
      [ response        => $response,
        parsed_response => $rsp
      ]
    )
  );

  return $rsp;
}

########################################################################
sub _parse_notification_configuration {
########################################################################
  my ( $self, $xml ) = @_;

  my @configs;

  my $handler = sub {
    my ( $t, $node ) = @_;

    my @events = map { $_->text } $node->children('Event');

    my @filter_rules;

    if ( my $filter = $node->first_child('Filter') ) {
      if ( my $s3key = $filter->first_child('S3Key') ) {
        for my $rule ( $s3key->children('FilterRule') ) {
          push @filter_rules,
            {
            name  => $rule->first_child_text('Name'),
            value => $rule->first_child_text('Value'),
            };
        }
      }
    }

    push @configs,
      {
      id         => $node->first_child_text('Id'),
      lambda_arn => $node->first_child_text('CloudFunction'),
      queue_arn  => $node->first_child_text('Queue'),
      topic_arn  => $node->first_child_text('Topic'),
      events     => \@events,
      filters    => \@filter_rules,
      };

    $t->purge;
  };

  XML::Twig->new(
    twig_handlers => {
      CloudFunctionConfiguration => $handler,
      QueueConfiguration         => $handler,
      TopicConfiguration         => $handler,
    }
  )->parse($xml);

  return \@configs;
}

########################################################################
sub _create_notification_configuration {
########################################################################
  my ( $self, $bucket, %options ) = @_;

  croak 'ERROR: bucket is required'
    if !defined $bucket || !length $bucket;

  croak "ERROR: type is a required argument\n"
    if !$options{type};

  croak 'ERROR: lambda_arn is required'
    if $options{type} eq 'lambda' && !$options{lambda_arn};

  croak 'ERROR: queue_arn is required'
    if $options{type} eq 'sqs' && !$options{queue_arn};

  my $events = ref $options{events} ? $options{events} : [ $options{events} ];

  croak "ERROR: no events defined\n"
    if !$options{events} || !@{$events};

  my $templates = $self->_fetch_templates();

  my $id = $options{id} // 'notification-1';

  my @event_xml;

  foreach ( @{$events} ) {
    push @event_xml, $self->_resolve( $templates->{event}, event => $_ );
  }

  my @filter_rules;

  foreach my $p ( pairs %{ $options{filters} // {} } ) {
    my ( $name, $value ) = @{$p};
    push @filter_rules, $self->_resolve( $templates->{'filter-rule'}, filter_name => $name, filter => $value );
  }

  my $xml = $templates->{ $options{type} . '-event' };

  return $self->_resolve(
    $xml,
    id           => $id,
    lambda_arn   => $options{lambda_arn},
    queue_arn    => $options{queue_arn},
    events       => "@event_xml",
    filter_rules => "@filter_rules"
  );
}

my %TEMPLATES;

########################################################################
sub _fetch_templates {
########################################################################
  my ($self) = @_;

  return \%TEMPLATES
    if %TEMPLATES;

  local $RS = undef;

  my $data = <DATA>;
  $data =~ s/\A(.*?)^=pod.*\z/$1/xsm;

  my $t             = q{};
  my $template_name = q{};

  foreach my $line ( split /\n/xsm, $data ) {
    if ( $line =~ /^:(.*)$/xsm ) {
      if ( $template_name && $t ) {
        $TEMPLATES{$template_name} = $t;
      }
      $t             = q{};
      $template_name = $1;
      next;
    }

    $t .= "$line\n";
  }

  $TEMPLATES{$template_name} = $t;

  return \%TEMPLATES;
}

########################################################################
sub _resolve {
########################################################################
  my ( $self, $template, %data ) = @_;

  my $output = $template;

  foreach my $p ( pairs %data ) {
    my ( $k, $v ) = @{$p};

    $output =~ s/[@]\Q$k\E[@]/$v/xsmg;
  }

  return $output;
}

########################################################################
# Error checking helpers
########################################################################
sub _is_success {
########################################################################
  return $_[0]->{status} =~ /\A2\d{2}\z/;
}

########################################################################
sub _is_not_found {
########################################################################
  return $_[0]->{status} == 404;
}

########################################################################
sub _croak_on_error {
########################################################################
  my ( $self, $response, $context ) = @_;

  return if _is_success($response);

  my ( $status, $reason ) = @{$response}{qw(status reason)};

  # Attempt to extract S3 error message from XML body
  my $detail = q{};

  if ( $response->{content} && $response->{content} =~ /<\?xml/xsm ) {
    my ($code) = $response->{content} =~ m{<Code>([^<]+)</Code>}xsm;
    my ($msg)  = $response->{content} =~ m{<Message>([^<]+)</Message>}xsm;

    if ( $code || $msg ) {
      $detail = " - $code: $msg";
    }
  }

  croak sprintf '%s failed: HTTP %s %s%s', $context, $status, $reason, $detail;
}

1;

## no critic (RequirePodSections)

__DATA__
:filter-rule
<FilterRule>
  <Name>@filter_name@</Name>
  <Value>@filter@</Value>
</FilterRule>
:event
<Event>@event@</Event>
:lambda-event
<NotificationConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <LambdaFunctionConfiguration>
    <Id>@id@</Id>
    <LambdaFunctionArn>@lambda_arn@</LambdaFunctionArn>
    @events@
    <Filter>
      <S3Key>
        @filter_rules@
      </S3Key>
    </Filter>
  </LambdaFunctionConfiguration>
</NotificationConfiguration>
:sqs-event
<NotificationConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <QueueConfiguration>
    <Id>@id@</Id>
    <Queue>@queue_arn@</Queue>
    @events@
    <Filter>
      <S3Key>
        @filter_rules@
      </S3Key>
    </Filter>
  </QueueConfiguration>
</NotificationConfiguration>

=pod

=encoding utf8

=head1 NAME

Amazon::S3::Lite - A lightweight Amazon S3 client for common
operations

=head1 SYNOPSIS

  use Amazon::S3::Lite;

  # Credentials from environment or IAM role automatically
  my $s3 = Amazon::S3::Lite->new({ region => 'us-east-1' });

  # Explicit credentials
  my $s3 = Amazon::S3::Lite->new({
    region                => 'us-east-1',
    aws_access_key_id     => $key,
    aws_secret_access_key => $secret,
    token                 => $session_token,  # optional, for STS/Lambda roles
  });

  # Pass any credentials object with standard getters
  my $s3 = Amazon::S3::Lite->new({
    region      => 'us-east-1',
    credentials => $creds_obj,
  });

  # List objects in a bucket
  my $result = $s3->list_objects_v2('my-bucket', prefix => 'logs/');

  foreach my $obj ( @{ $result->{objects} } ) {
    printf "%s  %d bytes\n", $obj->{key}, $obj->{size};
  }

  # Paginate
  while ( $result->{is_truncated} ) {
    $result = $s3->list_objects_v2('my-bucket',
      prefix             => 'logs/',
      continuation_token => $result->{next_continuation_token},
    );
    # ... process $result->{objects}
  }

  # Get an object
  my $obj = $s3->get_object('my-bucket', 'path/to/key.json');
  print $obj->{content};

  # Head an object (existence check / metadata only)
  my $meta = $s3->head_object('my-bucket', 'path/to/key.json');
  if ($meta) {
    print $meta->{content_length};
  }

  # Put an object
  $s3->put_object('my-bucket', 'path/to/key.json', $json_string,
    content_type => 'application/json',
    metadata     => { source => 'lambda' },
  );

  # Copy an object
  $s3->copy_object(
    src_bucket => 'my-bucket', src_key => 'orig/file.json',
    dst_bucket => 'my-bucket', dst_key => 'archive/file.json',
  );

  # Delete an object
  $s3->delete_object('my-bucket', 'path/to/key.json');

  # List all buckets
  my $result = $s3->list_buckets;
  for my $bucket ( @{ $result->{buckets} } ) {
    print $bucket->{name}, "\n";
  }

  # Create a bucket
  $s3->create_bucket('my-bucket');
  $s3->create_bucket('my-bucket', region => 'eu-west-1');

  # Configure a Lambda notification trigger
  $s3->put_bucket_notification_configuration('my-bucket',
    type       => 'lambda',
    lambda_arn => $function_arn,
    events     => 's3:ObjectCreated:*',
    filters    => { prefix => 'uploads/' },
  );

  # Configure an SQS notification trigger
  $s3->put_bucket_notification_configuration('my-bucket',
    type      => 'sqs',
    queue_arn => $queue_arn,
    events    => 's3:ObjectCreated:*',
  );

  # Retrieve notification configuration
  my $configs = $s3->get_bucket_notification_configuration('my-bucket');
  for my $cfg ( @{$configs} ) {
    printf "id=%s lambda=%s queue=%s\n",
      $cfg->{id}, $cfg->{lambda_arn} // '', $cfg->{queue_arn} // '';
  }

=head1 DESCRIPTION

C<Amazon::S3::Lite> is a minimal Amazon S3 client covering the
operations most commonly needed in AWS Lambda functions and
lightweight scripts: listing buckets, listing objects, reading,
writing, copying, and deleting.

It is built on L<HTTP::Tiny> (core since Perl 5.14) and
L<Amazon::Signature4::Lite>, with no dependency on LWP or any part of
the libwww-perl ecosystem. The dependency list is intentionally small,
making it well-suited for Lambda container images where minimizing
cold-start time and image size matters.

It is not a replacement for L<Amazon::S3> or L<Net::Amazon::S3>, which
support the full S3 API surface including multipart upload, bucket
management, ACLs, versioning, and presigned URLs. If you need those
features, use one of those distributions instead.

L<Amazon::S3::Thin> is another excellent lightweight S3 client with a
similar philosophy and a longer track record. It is more complete than
this module - supporting presigned URLs, bulk delete, and
virtual-hosted-style requests - and returns raw L<HTTP::Response>
objects so callers handle status codes and errors
themselves. C<Amazon::S3::Lite> differs in three ways: it has no
dependency on LWP (C<Amazon::S3::Thin> defaults to L<LWP::UserAgent>),
it returns parsed hashrefs rather than raw response objects, and it
has first-class support for Lambda IAM role credential rotation. If
you need the broader feature set or prefer direct HTTP access,
C<Amazon::S3::Thin> is a fine choice.

=head1 CONSTRUCTOR

=head2 new

  my $s3 = Amazon::S3::Lite->new(\%options);

Returns a new C<Amazon::S3::Lite> object. Options:

=over 4

=item region (required)

The AWS region for your bucket, e.g. C<us-east-1>.

=item aws_access_key_id / aws_secret_access_key

Static credentials. C<token> may also be supplied for STS temporary
credentials (as used by Lambda execution roles).

These are only consulted if no C<credentials> object is provided.

=item token

Optional STS session token, used alongside static credentials for
temporary credential sets.

=item credentials

An object providing credential getters. The object must respond to:

  $creds->aws_access_key_id
  $creds->aws_secret_access_key
  $creds->token            # may return undef

Any object that satisfies this interface is accepted -
L<Amazon::Credentials>, L<Paws::Credential::*>, or your own. The
getters are called at request time, so objects that refresh expiring
credentials transparently are supported.

=item logger

An object providing the standard log methods:

  $logger->trace(...)
  $logger->debug(...)
  $logger->info(...)
  $logger->warn(...)
  $logger->error(...)

If not supplied, the module looks for L<Log::Log4perl>. If available,
it calls C<Log::Log4perl::easy_init> with level WARN and logs to
STDERR.  If Log::Log4perl is not installed, a minimal internal logger
is used that prints WARN and above to STDERR.

=item host

Override the S3 endpoint host. Defaults to C<s3.amazonaws.com>.
Useful for S3-compatible services (MinIO, Ceph, LocalStack).

=item secure

Use HTTPS. Default is 1 (true). Set to 0 only for testing against
local S3-compatible endpoints.

=item timeout

HTTP request timeout in seconds. Default is 30.

=back

=head2 Credential resolution order

When no C<credentials> object is passed, credentials are resolved in
this order:

=over 4

=item 1.

Constructor arguments C<aws_access_key_id> and C<aws_secret_access_key>.

=item 2.

Environment variables C<AWS_ACCESS_KEY_ID>, C<AWS_SECRET_ACCESS_KEY>,
and optionally C<AWS_SESSION_TOKEN>.

=item 3.

L<Amazon::Credentials>, if installed. This covers IAM instance roles,
Lambda execution roles, ECS task roles, and C<~/.aws/credentials>
profiles.

=item 4.

If none of the above yield credentials, the constructor croaks.

=back

=head1 METHODS

All methods croak on unrecoverable errors (network failure, HTTP 5xx).
HTTP 404 is not an exception - methods that can meaningfully return
C<undef> for a missing resource do so.

=head2 list_objects_v2

  my $result = $s3->list_objects_v2($bucket, %options);

Lists objects in C<$bucket> using the S3 ListObjectsV2 API.

Options:

=over 4

=item prefix

Limit results to keys beginning with this string.

=item delimiter

Group keys sharing a common prefix up to this delimiter. Grouped
prefixes are returned in C<common_prefixes>.

=item max_keys

Maximum number of objects to return per call (1-1000, default 1000).

=item continuation_token

Resume a truncated listing from a prior call's
C<next_continuation_token>.

=item start_after

Return only keys lexicographically after this value.

=back

Returns a hashref:

  {
    bucket                 => 'my-bucket',
    prefix                 => 'logs/',
    is_truncated           => 0,
    next_continuation_token => undef,        # set when is_truncated is true
    key_count              => 42,
    objects                => [
      {
        key           => 'logs/2024-01-01.gz',
        size          => 102400,
        last_modified => '2024-01-01T00:00:00.000Z',
        etag          => 'abc123',
        storage_class => 'STANDARD',
      },
      ...
    ],
    common_prefixes        => [],            # populated when delimiter is set
  }

=head2 list_all_objects_v2

  my @objects = $s3->list_all_objects_v2($bucket, %options);

Convenience wrapper around L</list_objects_v2> that automatically
follows continuation tokens and returns a flat list of all matching
object hashrefs in a single call.

Accepts the same options as C<list_objects_v2> except
C<continuation_token> (which is managed internally) and C<delimiter>
(which is silently ignored - see below).

  my @logs = $s3->list_all_objects_v2('my-bucket', prefix => 'logs/');

  foreach my $obj (@logs) {
    printf "%s  %d bytes\n", $obj->{key}, $obj->{size};
  }

Be mindful of memory when listing buckets with large numbers of
objects.  For very large listings, use L</list_objects_v2> directly
and process each page as it arrives.

C<delimiter> and C<common_prefixes> are not supported by this method.
The purpose of C<list_all_objects_v2> is a complete flat listing of
all matching keys. Hierarchical directory-style traversal using
C<delimiter> is inherently page-by-page and should use
L</list_objects_v2> directly.

Returns a (possibly empty) list of object hashrefs, each with the same
fields as the elements of C<objects> in the C<list_objects_v2>
response.

=head2 get_object

  my $obj = $s3->get_object($bucket, $key);
  my $obj = $s3->get_object($bucket, $key, %options);

Fetches the object at C<$key> in C<$bucket>.

Returns C<undef> if the key does not exist (HTTP 404).

Returns a hashref on success:

  {
    content        => '...',          # raw bytes; absent when filename is used
    content_type   => 'application/json',
    content_length => 1024,
    etag           => 'abc123',
    last_modified  => 'Tue, 01 Jan 2024 00:00:00 GMT',
    metadata       => {               # x-amz-meta-* headers, lowercased
      source => 'lambda',
    },
  }

Options:

=over 4

=item range

An HTTP Range header value, e.g. C<bytes=0-1023>, for partial fetches.

=item filename

Path to a local file where the object body should be written. When
supplied, the response body is streamed directly to disk via
HTTP::Tiny's C<:content_file> mechanism and C<content> is omitted from
the returned hashref. The file is created or overwritten.

  my $meta = $s3->get_object('my-bucket', 'data/dump.csv',
    filename => '/tmp/dump.csv',
  );
  # $meta->{content} is absent; file is on disk

This is the recommended approach for large objects in Lambda where
holding the full body in memory is undesirable.

=back

=head2 head_object

  my $meta = $s3->head_object($bucket, $key);

Fetches metadata for C<$key> without retrieving the object body.
Useful for existence checks and reading C<x-amz-meta-*> headers
cheaply.

Returns C<undef> if the key does not exist (HTTP 404).

Returns a hashref on success with the same fields as C<get_object>
except C<content>, which is always absent.

=head2 put_object

  $s3->put_object($bucket, $key, $data, %options);

Stores C<$data> at C<$key> in C<$bucket>. C<$data> may be:

=over 4

=item * A scalar string (the object body verbatim)

=item * A reference to a scalar (avoids copying large strings)

=item * An open filehandle or L<IO::File> object (body is read to EOF)

=back

When passing a filehandle, C<content_length> becomes required unless
HTTP::Tiny can determine the size from the handle (i.e. the handle is
backed by a real file). For in-memory handles (C<IO::Scalar>, etc.)
you must supply C<content_length> explicitly, or the method will
croak.

  # Scalar
  $s3->put_object('my-bucket', 'hello.txt', 'Hello, world!',
    content_type => 'text/plain',
  );

  # Filehandle
  open my $fh, '<', '/tmp/data.csv' or die $!;
  $s3->put_object('my-bucket', 'data.csv', $fh,
    content_type => 'text/csv',
  );

Options:

=over 4

=item content_type

MIME type for the object. Defaults to C<application/octet-stream>.

=item content_length

Required when C<$data> is an in-memory filehandle. Optional (and
ignored) for scalar data, where length is computed automatically.

=item metadata

Hashref of user-defined metadata. Keys should be bare names - the
C<x-amz-meta-> prefix is added automatically.

  metadata => { source => 'lambda', job_id => '42' }

=item acl

Canned ACL string, e.g. C<private> (default), C<public-read>.

=back

Returns the ETag of the stored object on success. Croaks on failure.

=head2 copy_object

  $s3->copy_object(
    src_bucket => 'src-bucket',
    src_key    => 'original/key.json',
    dst_bucket => 'dst-bucket',
    dst_key    => 'copy/key.json',
  );

Copies an object within or between buckets without transferring data
through the client. The copy is performed entirely server-side by S3.

Returns a hashref on success:

  {
    etag          => 'abc123',
    last_modified => '2024-01-01T00:00:00.000Z',
  }

Croaks on failure.

=head2 delete_object

  $s3->delete_object($bucket, $key);
  $s3->delete_object($bucket, $key, version_id => $vid);

Deletes the object at C<$key> in C<$bucket>.

If C<version_id> is provided, that specific version is deleted.

Returns true on success. Note that S3 returns HTTP 204 for both
successful deletes I<and> deletes of non-existent keys, so this method
does not distinguish between the two - it succeeds silently in either
case.

=head2 list_buckets

  my $result = $s3->list_buckets;

Lists all S3 buckets owned by the authenticated account.

Returns a hashref:

  {
    owner_id   => 'abc123...',
    owner_name => 'myaccount',
    buckets    => [
      { name => 'my-bucket',    creation_date => '2024-01-01T00:00:00.000Z' },
      { name => 'other-bucket', creation_date => '2024-06-01T00:00:00.000Z' },
      ...
    ],
  }

Note that this operation is always signed against C<us-east-1>
regardless of the region the object was constructed with. See
L</LAMBDA USAGE NOTES>.

=head2 create_bucket

  $s3->create_bucket($bucket);
  $s3->create_bucket($bucket, region => 'eu-west-1', acl => 'private');

Creates a new S3 bucket. Options:

=over 4

=item region

The region in which to create the bucket. Defaults to the region the
object was constructed with. B<Note:> C<us-east-1> is S3's implicit
default - the C<CreateBucketConfiguration> body is intentionally
omitted for that region as including it causes a C<InvalidLocationConstraint>
error. For all other regions the C<LocationConstraint> element is
sent automatically.

=item acl

Canned ACL string, e.g. C<private> (the S3 default), C<public-read>.

=back

Returns true on success. Croaks on failure.

=head2 put_bucket_notification_configuration

  # Lambda trigger
  $s3->put_bucket_notification_configuration($bucket,
    type       => 'lambda',
    lambda_arn => $function_arn,
    events     => 's3:ObjectCreated:*',
  );

  # SQS trigger
  $s3->put_bucket_notification_configuration($bucket,
    type      => 'sqs',
    queue_arn => $queue_arn,
    events    => [qw(s3:ObjectCreated:* s3:ObjectRemoved:*)],
    filters   => { prefix => 'uploads/', suffix => '.csv' },
  );

Sets the bucket notification configuration for C<$bucket>, routing
S3 events to a Lambda function or SQS queue.

Options:

=over 4

=item type (required)

The notification target type. Must be C<lambda> or C<sqs>.

=item lambda_arn (required when type is C<lambda>)

The ARN of the Lambda function to invoke.

=item queue_arn (required when type is C<sqs>)

The ARN of the SQS queue to deliver messages to.

=item events (required)

A scalar event name or an arrayref of event names.
Common values: C<s3:ObjectCreated:*>, C<s3:ObjectRemoved:*>.

=item filters

A hashref of S3 key filter rules. Supported keys are C<prefix>
and C<suffix>.

=item id

An identifier for the configuration entry. Defaults to C<notification-1>.

=back

Returns true on success. Croaks on failure.

=head2 get_bucket_notification_configuration

  my $configs = $s3->get_bucket_notification_configuration($bucket);

  for my $cfg ( @{$configs} ) {
    if ( $cfg->{lambda_arn} ) {
      printf "Lambda: id=%s arn=%s\n", $cfg->{id}, $cfg->{lambda_arn};
    }
    elsif ( $cfg->{queue_arn} ) {
      printf "SQS:    id=%s arn=%s\n", $cfg->{id}, $cfg->{queue_arn};
    }
    print "  events: ", join(', ', @{ $cfg->{events} }), "\n";
  }

Retrieves the current notification configuration for C<$bucket>.
Handles both Lambda (C<CloudFunctionConfiguration>) and SQS
(C<QueueConfiguration>) entries, which are the XML element names
the S3 API returns regardless of how the configuration was created.

Returns an arrayref of configuration hashrefs, each containing:

=over 4

=item id

The configuration entry identifier.

=item lambda_arn

The Lambda function ARN. Present for Lambda notification entries;
C<undef> for SQS entries.

=item queue_arn

The SQS queue ARN. Present for SQS notification entries;
C<undef> for Lambda entries.

=item events

Arrayref of event type strings.

=item filters

Arrayref of hashrefs, each with C<name> (C<prefix> or C<suffix>)
and C<value>.

=back

Returns an empty arrayref if no notification configuration is set.
Croaks on failure.

=head2 remove_bucket_notification_configuration

  $s3->remove_bucket_notification_configuration($bucket);

Removes all notification configurations from C<$bucket> by sending an
empty C<NotificationConfiguration> document to S3. After this call S3
will no longer deliver any events for the bucket.

Returns true on success. Croaks on failure.

=head1 ERROR HANDLING

Methods croak on:

=over 4

=item * Network-level failures (connection refused, timeout, DNS failure)

=item * HTTP 5xx responses from S3

=item * Unexpected HTTP 3xx responses that could not be resolved

=back

Methods return C<undef> on:

=over 4

=item * HTTP 404 (key or bucket not found), where the return type allows it

=back

All other HTTP error codes (400, 403, 409, etc.) cause a croak with a
message containing the HTTP status line and the S3 error body where
available.

=head1 DEPENDENCIES

=over 4

=item * L<HTTP::Tiny> (core since Perl 5.14)

=item * L<Amazon::Signature4::Lite>

=item * L<XML::Twig> (for parsing list and copy responses)

=item * L<Digest::MD5> (core, for Content-MD5 headers)

=item * L<MIME::Base64> (core)

=item * L<URI::Escape>

=item * L<Carp> (core)

=back

Optional:

=over 4

=item * L<Amazon::Credentials> - automatic credential discovery from IAM
roles, ECS task roles, ~/.aws/credentials, and environment.

=item * L<Log::Log4perl> - structured logging; if present, used in
preference to the built-in minimal logger.

=back

=head1 LAMBDA USAGE NOTES

In a Lambda container, credentials come from the execution role via
the ECS credential provider endpoint (indicated by
C<AWS_CONTAINER_CREDENTIALS_RELATIVE_URI> in the environment).
L<Amazon::Credentials> handles this automatically when installed and
is the recommended approach. If you prefer not to take that
dependency, the Lambda runtime also populates C<AWS_ACCESS_KEY_ID>,
C<AWS_SECRET_ACCESS_KEY>, and C<AWS_SESSION_TOKEN> directly, which
this module picks up automatically from the environment.

B<Region note:> The C<list_buckets> method is a global S3 operation
and is always signed against C<us-east-1>, regardless of the region
supplied to the constructor. This is an S3 requirement, not a
limitation of this module, and is handled transparently - your
object's region is not changed.

B<Cold start:> Because this module depends only on L<HTTP::Tiny> (Perl
core), L<XML::Twig>, L<AWS::Signature4>, and L<URI::Escape>, it adds
minimal overhead to Lambda container image builds compared to
LWP-based S3 clients.

=head1 TESTING

When testing against LocalStack, be aware that LocalStack is more
lenient than real S3 regarding SigV4 requirements. In particular,
LocalStack may accept requests where the C<x-amz-content-sha256>
header is missing or where session token handling is incorrect. Tests
that pass against LocalStack should always be verified against real S3
before release.

=head1 SEE ALSO

L<Amazon::S3> - the full-featured S3 client this module draws from

L<Amazon::S3::Thin> - another excellent lightweight S3 client with a
similar philosophy, broader feature coverage, and a longer track
record. Uses LWP by default and returns raw L<HTTP::Response>
objects. See L</DESCRIPTION> for a detailed comparison.

L<Net::Amazon::S3> - a Moose-based full-featured alternative

L<Amazon::Signature4::Lite> - the signing module used internally

L<Amazon::Credentials> - credential provider with IAM role and profile
support

=head1 AUTHOR

Rob Lauer <rlauer@treasurersbriefcase.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
