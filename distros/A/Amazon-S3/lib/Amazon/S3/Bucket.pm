package Amazon::S3::Bucket;

use strict;
use warnings;

use Amazon::S3::Constants qw(:all);
use Amazon::S3::Util      qw(:all);

use Carp;
use Data::Dumper;
use Digest::MD5       qw(md5 md5_hex);
use Digest::MD5::File qw(file_md5 file_md5_hex);
use English           qw(-no_match_vars);
use File::stat;
use IO::File;
use IO::Scalar;
use MIME::Base64;
use List::Util   qw(none pairs);
use Scalar::Util qw(reftype);
use URI;
use XML::Simple; ## no critic (DiscouragedModules)

use parent qw(Exporter Class::Accessor::Fast);

our $VERSION = '2.0.2'; ## no critic (RequireInterpolation)

__PACKAGE__->mk_accessors(
  qw(
    bucket
    creation_date
    account
    buffer_size
    region
    logger
    verify_region
  ),
);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = get_parameters(@args);

  $options->{buffer_size} ||= $DEFAULT_BUFFER_SIZE;

  my $self = $class->SUPER::new($options);

  croak 'no bucket'
    if !$self->bucket;

  croak 'no account'
    if !$self->account;

  if ( !$self->logger ) {
    $self->logger( $self->account->get_logger );
  }

  # now each bucket maintains its own region
  if ( !$self->region && $self->verify_region ) {
    my $region;

    if ( !$self->account->err ) {
      $region = $self->get_location_constraint() // 'us-east-1';
    }

    $self->logger->debug( sprintf "bucket: %s region: %s\n",
      $self->bucket, ( $region // $EMPTY ) );

    $self->region($region);
  }
  elsif ( !$self->region ) {
    $self->region( $self->account->region );
  }

  return $self;
}

########################################################################
sub _uri {
########################################################################
  my ( $self, $key ) = @_;

  if ($key) {
    $key =~ s/^\///xsm;
  }

  my $account = $self->account;

  my $uri = $self->bucket . $SLASH;

  if ($key) {
    $uri .= urlencode($key);
  }

  if ( $account->dns_bucket_names ) {
    $uri =~ s/^\///xsm;
  }

  return $uri;
}

########################################################################
sub add_key {
########################################################################
  my ( $self, $key, $value, $conf ) = @_;

  croak 'must specify key'
    if !$key || !length $key;

  $conf //= {};

  my $account = $self->account;

  my $headers = delete $conf->{headers};
  $headers //= {};

  if ( $conf->{acl_short} ) {
    $account->_validate_acl_short( $conf->{acl_short} );

    $conf->{'x-amz-acl'} = $conf->{acl_short};

    delete $conf->{acl_short};
  }

  $headers = { %{$conf}, %{$headers} };

  set_md5_header( data => $value, headers => $headers );

  if ( ref $value ) {
    $value = _content_sub( ${$value}, $self->buffer_size );

    $headers->{'x-amz-content-sha256'} = 'UNSIGNED-PAYLOAD';
  }

  # If we're pushing to a bucket that's under
  # DNS flux, we might get a 307 Since LWP doesn't support actually
  # waiting for a 100 Continue response, we'll just send a HEAD first
  # to see what's going on
  my $retval = eval {
    return $self->_add_key(
      { headers => $headers,
        data    => $value,
        key     => $key,
      },
    );
  };

  # one more try? if someone specified the wrong region, we'll get a
  # 301 and you'll only know the region of redirection - no location
  # header provided...
  if ($EVAL_ERROR) {
    my $rsp = $account->last_response;

    if ( $rsp->code eq $HTTP_MOVED_PERMANENTLY ) {
      $self->region( $rsp->headers->{'x-amz-bucket-region'} );
    }

    $retval = $self->_add_key(
      { headers => $headers,
        data    => $value,
        key     => $key,
      },
    );
  }

  return $retval;
}

########################################################################
sub _add_key {
########################################################################
  my ( $self, @args ) = @_;

  my ( $data, $headers, $key ) = @{ $args[0] }{qw{data headers key}};

  my $account = $self->account;

  if ( ref $data ) {
    return $account->_send_request_expect_nothing_probed(
      { method  => 'PUT',
        path    => $self->_uri($key),
        headers => $headers,
        data    => $data,
        region  => $self->region,
      },
    );
  }
  else {
    return $account->_send_request_expect_nothing(
      { method  => 'PUT',
        path    => $self->_uri($key),
        headers => $headers,
        data    => $data,
        region  => $self->region,
      },
    );
  }
}

########################################################################
sub add_key_filename {
########################################################################
  my ( $self, $key, $value, $conf ) = @_;

  return $self->add_key( $key, \$value, $conf );
}

########################################################################
sub upload_multipart_object {
########################################################################
  my ( $self, @args ) = @_;

  my $logger = $self->logger;

  my $parameters = get_parameters(@args);

  croak 'no key!'
    if !$parameters->{key};

  croak 'either data, callback or fh must be set!'
    if !$parameters->{data} && !$parameters->{callback} && !$parameters->{fh};

  croak 'callback must be a reference to a subroutine!'
    if $parameters->{callback}
    && reftype( $parameters->{callback} ) ne 'CODE';

  $parameters->{abort_on_error} //= $TRUE;
  $parameters->{chunk_size}     //= $MIN_MULTIPART_UPLOAD_CHUNK_SIZE;

  if ( !$parameters->{callback} && !$parameters->{fh} ) {
    #...but really nobody should be passing a >5MB scalar
    my $data
      = ref $parameters->{data} ? $parameters->{data} : \$parameters->{data};

    $parameters->{fh} = IO::Scalar->new($data);
  }

  # ...having a file handle implies, we use this callback
  if ( $parameters->{fh} ) {
    my $fh = $parameters->{fh};

    $fh->seek( 0, 2 );

    my $length = $fh->tell;
    $fh->seek( 0, 0 );

    $logger->trace( sub { return sprintf 'length of object: %s', $length; } );

    croak 'length of the object must be >= '
      . $MIN_MULTIPART_UPLOAD_CHUNK_SIZE
      if $length < $MIN_MULTIPART_UPLOAD_CHUNK_SIZE;

    my $chunk_size
      = ( $parameters->{chunk_size} && $parameters->{chunk_size} )
      > $MIN_MULTIPART_UPLOAD_CHUNK_SIZE
      ? $parameters->{chunk_size}
      : $MIN_MULTIPART_UPLOAD_CHUNK_SIZE;

    $parameters->{callback} = sub {
      return
        if !$length;

      my $bytes_read = 0;

      my $n = $length >= $chunk_size ? $chunk_size : $length;

      $logger->trace( sprintf 'reading %d bytes', $n );

      my $buffer;

      my $bytes = $fh->read( $buffer, $n, $bytes_read );
      $logger->trace( sprintf 'read %d bytes', $bytes );

      $bytes_read += $bytes;

      $length -= $bytes;

      $logger->trace( sprintf '%s bytes left to read', $length );

      return ( \$buffer, $bytes );
    };
  }

  my $headers = $parameters->{headers} || {};

  my $id = $self->initiate_multipart_upload( $parameters->{key}, $headers );

  $logger->trace( sprintf 'multipart id: %s', $id );

  my $part = 1;

  my %parts;

  my $key = $parameters->{key};

  my $retval = eval {
    while (1) {
      my ( $buffer, $length ) = $parameters->{callback}->();
      last if !$buffer;

      my $etag = $self->upload_part_of_multipart_upload(
        { id   => $id,
          key  => $key,
          data => $buffer,
          part => $part,
        },
      );

      $parts{ $part++ } = $etag;
    }

    $self->complete_multipart_upload( $parameters->{key}, $id, \%parts );
  };

  if ( $EVAL_ERROR && $parameters->{abort_on_error} ) {
    $self->abort_multipart_upload( $key, $id );
    %parts = ();
  }

  return \%parts;
}

# Initiates a multipart upload operation. This is necessary for uploading
# files > 5Gb to Amazon S3
#
# returns: upload ID assigned by Amazon (used to identify this
# particular upload in other operations)
########################################################################
sub initiate_multipart_upload {
########################################################################
  my ( $self, $key, $headers ) = @_;

  croak 'Object key is required'
    if !$key;

  my $acct = $self->account;

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'POST',
      path    => $self->_uri($key) . '?uploads=',
      headers => $headers,
    },
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  my $r = $acct->_xpc_of_content( $response->content );

  return $r->{UploadId};
}

#
# Upload a part of a file as part of a multipart upload operation
# Each part must be at least 5mb (except for the last piece).
# This returns the Amazon-generated eTag for the uploaded file segment.
# It is necessary to keep track of the eTag for each part number
# The complete operation will want a sequential list of all the part
# numbers along with their eTags.
#
########################################################################
sub upload_part_of_multipart_upload {
########################################################################
  my ( $self, @args ) = @_;

  my ( $key, $upload_id, $part_number, $data, $length );

  if ( @args == 1 ) {
    if ( reftype( $args[0] ) eq 'HASH' ) {
      ( $key, $upload_id, $part_number, $data, $length )
        = @{ $args[0] }{qw{ key id part data length}};
    }
    elsif ( reftype( $args[0] ) eq 'ARRAY' ) {
      ( $key, $upload_id, $part_number, $data, $length ) = @{ $args[0] };
    }
  }
  else {
    ( $key, $upload_id, $part_number, $data, $length ) = @args;
  }

  # argh...wish we didn't have to do this!
  if ( ref $data ) {
    $data = ${$data};
  }

  $length = $length || length $data;

  croak 'Object key is required'
    if !$key;

  croak 'Upload id is required'
    if !$upload_id;

  croak 'Part Number is required'
    if !$part_number;

  my $headers = {};
  my $acct    = $self->account;

  set_md5_header( data => $data, headers => $headers );

  my $path = create_api_uri(
    path       => $self->_uri($key),
    partNumber => ${part_number},
    uploadId   => ${upload_id}
  );

  my $params = $QUESTION_MARK
    . create_query_string(
    partNumber => ${part_number},
    uploadId   => ${upload_id}
    );

  $self->logger->debug(
    sub {
      return Dumper(
        [ part   => $part_number,
          length => length $data,
          path   => $path,
        ]
      );
    }
  );

  my $request = $acct->_make_request(
    { region => $self->region,
      method => 'PUT',
      path   => $self->_uri($key) . $params,
      #path    => $path,
      headers => $headers,
      data    => $data,
    },
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  # We'll need to save the etag for later when completing the transaction
  my $etag = $response->header('ETag');

  if ($etag) {
    $etag =~ s/^"//xsm;
    $etag =~ s/"$//xsm;
  }

  return $etag;
}

#
# Inform Amazon that the multipart upload has been completed
# You must supply a hash of part Numbers => eTags
# For amazon to use to put the file together on their servers.
#
########################################################################
sub complete_multipart_upload {
########################################################################
  my ( $self, $key, $upload_id, $parts_hr ) = @_;

  $self->logger->debug( Dumper( [ $key, $upload_id, $parts_hr ] ) );

  croak 'Object key is required'
    if !$key;

  croak 'Upload id is required'
    if !$upload_id;

  croak 'Part number => etag hashref is required'
    if ref $parts_hr ne 'HASH';

  # The complete command requires sending a block of xml containing all
  # the part numbers and their associated etags (returned from the upload)
  my $content = _create_multipart_upload_request($parts_hr);

  $self->logger->debug("content: \n$content");

  my $md5        = md5($content);
  my $md5_base64 = encode_base64($md5);
  chomp $md5_base64;

  my $headers = {
    'Content-MD5'    => $md5_base64,
    'Content-Length' => length $content,
    'Content-Type'   => 'application/xml',
  };

  my $acct   = $self->account;
  my $params = "?uploadId=${upload_id}";

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'POST',
      path    => $self->_uri($key) . $params,
      headers => $headers,
      data    => $content,
    },
  );

  my $response = $acct->_do_http($request);

  if ( $response->code !~ /\A2\d\d\z/xsm ) {
    $acct->_remember_errors( $response->content, 1 );
    croak $response->status_line;
  }

  return $TRUE;
}

########################################################################
sub abort_multipart_upload {
########################################################################
  my ( $self, $key, $upload_id ) = @_;

  croak 'Object key is required'
    if !$key;

  croak 'Upload id is required'
    if !$upload_id;

  my $acct   = $self->account;
  my $params = "?uploadId=${upload_id}";

  my $request = $acct->_make_request(
    { region => $self->region,
      method => 'DELETE',
      path   => $self->_uri($key) . $params,
    },
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  return $TRUE;
}

#
# List all the uploaded parts for an ongoing multipart upload
# It returns the block of XML returned from Amazon
#
########################################################################
sub list_multipart_upload_parts {
########################################################################
  my ( $self, $key, $upload_id, $headers ) = @_;

  croak 'Object key is required'
    if !$key;

  croak 'Upload id is required'
    if !$upload_id;

  my $acct   = $self->account;
  my $params = "?uploadId=${upload_id}";

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'GET',
      path    => $self->_uri($key) . $params,
      headers => $headers,
    },
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  # Just return the XML, let the caller figure out what to do with it
  return $response->content;
}

# List all the currently active multipart upload operations
# Returns the block of XML returned from Amazon
########################################################################
sub list_multipart_uploads {
########################################################################
  my ( $self, $headers ) = @_;

  my $acct = $self->account;

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'GET',
      path    => $self->_uri() . '?uploads',
      headers => $headers,
    },
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  # Just return the XML, let the caller figure out what to do with it
  return $response->content;
}

########################################################################
sub head_key {
########################################################################
  my ( $self, $key ) = @_;

  return $self->get_key( $key, 'HEAD' );
}

########################################################################
sub get_key_v2 {
########################################################################
  my ( $self, $key, $method, $headers ) = @_;

  return $self->_get_key( $key, $method, undef, $headers );
}

########################################################################
sub get_key {
########################################################################
  my ( $self, @args ) = @_;

  my ( $key, $method, $headers, $uri_params );

  if ( ref $args[0] ) {
    ( $key, $method, $headers, $uri_params )
      = @{ $args[0] }{qw(key method headers uri_params)};
  }
  else {
    ( $key, $method, $headers, $uri_params ) = @args;
  }

  return $self->_get_key(
    key        => $key,
    method     => $method,
    filename   => undef,
    headers    => $headers,
    uri_params => $uri_params,
  );
}

########################################################################
sub _get_key {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $key, $method, $filename, $headers, $uri_params )
    = @{$parameters}{qw(key method filename headers uri_params)};

  $method //= 'GET';

  my $uri = $self->_uri($key);

  if ( $uri_params && keys %{$uri_params} ) {
    $uri = $QUESTION_MARK . create_query_string($uri_params);
  }

  if ( ref $filename ) {
    $filename = ${$filename};
  }

  my $acct = $self->account;

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => $method,
      path    => $uri,
      headers => $headers,
    },
  );

  my $response = $acct->_do_http( $request, $filename );

  return
    if $response->code eq $HTTP_NOT_FOUND;

  $acct->_croak_if_response_error($response);

  my $etag = $response->header('ETag');

  if ($etag) {
    $etag =~ s/^"//xsm;
    $etag =~ s/"$//xsm;
  }

  my $retval = {
    content_length => ( $response->content_length || 0 ),
    content_type   => scalar $response->content_type,
    etag           => $etag,
    value          => ( $response->content // $EMPTY ),
    content_range  => ( $response->header('Content-Range') || $EMPTY ),
    last_modified  => ( $response->header('Last-Modified') || $EMPTY ),
  };

  # Validate against data corruption by verifying the MD5 (only if not partial)
  if ( $method eq 'GET' && $response->code ne $HTTP_PARTIAL_CONTENT ) {
    my $md5
      = ( $filename and -f $filename )
      ? file_md5_hex($filename)
      : md5_hex( $retval->{value} );

    # Some S3-compatible providers return an all-caps MD5 value in the
    # etag so it should be lc'd for comparison.
    croak "Computed and Response MD5's do not match:  $md5 : $etag"
      if $md5 ne lc $etag;
  }

  foreach my $header ( $response->headers->header_field_names ) {
    next if $header !~ /x-amz-meta-/ixsm;
    $retval->{ lc $header } = $response->header($header);
  }

  return $retval;
}

########################################################################
sub get_key_filename {
########################################################################
  my ( $self, @args ) = @_;

  my ( $key, $method, $filename, $headers, $uri_params );

  if ( ref $args[0] ) {
    ( $key, $method, $filename, $headers, $uri_params )
      = @{ $args[0] }{qw(key method filename headers uri_params)};
  }
  else {
    ( $key, $method, $filename, $headers, $uri_params ) = @args;
  }

  if ( !defined $filename ) {
    $filename = $key;
  }

  return $self->_get_key(
    key        => $key,
    method     => $method,
    filename   => \$filename,
    headers    => $headers,
    uri_params => $uri_params,
  );
}

########################################################################
# See: https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html
#
# Note that in this request the bucket object is the destination you
# specify the source bucket in the key (bucket-name/source-key) or the
# header x-amz-copy-source
########################################################################
sub copy_object {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $source, $key, $bucket, $headers_in )
    = @{$parameters}{qw(source key bucket headers)};

  $headers_in //= {};

  my %request_headers;

  if ( reftype($headers_in) eq 'ARRAY' ) {
    %request_headers = @{$headers_in};
  }
  elsif ( reftype($headers_in) eq 'HASH' ) {
    %request_headers = %{$headers_in};
  }
  else {
    croak 'headers must be hash or array'
      if !ref($headers_in) || reftype($headers_in) ne 'HASH';
  }

  croak 'source or x-amz-copy-source must be specified'
    if !$source && !exists $request_headers{'x-amz-copy-source'};

  croak 'no key'
    if !$key;

  my $acct = $self->account;
  $bucket //= $self->bucket();

  if ( !$request_headers{'x-amz-copy-source'} ) {

    $request_headers{'x-amz-copy-source'} = sprintf '%s/%s', $bucket,
      urlencode($source);
  }

  $request_headers{'x-amz-tagging-directive'} //= 'COPY';

  $key = $self->_uri($key);

  my $request = $acct->_make_request(
    method  => 'PUT',
    path    => $key,
    headers => \%request_headers,
  );

  my $response = $acct->_do_http($request);

  if ( $response->code !~ /\A2\d{2}\z/xsm ) {
    $acct->_remember_errors( $response->content, 1 );
    croak $response->status_line;
  }

  return $acct->_xpc_of_content( $response->content );
}

########################################################################
sub delete_key {
########################################################################
  my ( $self, $key, $version ) = @_;

  croak 'must specify key'
    if !$key && length $key;

  my $account = $self->account;

  my $path = $self->_uri($key);

  if ($version) {
    $path = '?versionId=' . $version;
  }

  return $account->_send_request_expect_nothing(
    { method  => 'DELETE',
      region  => $self->region,
      path    => $path,
      headers => {},
    },
  );
}

########################################################################
sub _format_delete_keys {
########################################################################
  my (@args) = @_;

  my @keys;

  if ( ref $args[0] ) {
    if ( reftype( $args[0] ) eq 'ARRAY' ) { # list of keys, no version ids
      foreach my $key ( @{ $args[0] } ) {
        if ( ref($key) && reftype($key) eq 'HASH' ) {

          push @keys,
            {
            Key => [ $key->{Key} ],
            defined $key->{VersionId}
            ? ( VersionId => [ $key->{VersionId} ] )
            : (),
            };
        }
        else { # array of keys
          push @keys, { Key => [$key], };
        }
      }
    }
    elsif ( reftype( $args[0] ) eq 'CODE' ) { # sub that returns key, version id
      while ( my (@object) = $args[0]->() ) {
        last if !@object || !defined $object[0];

        push @keys,
          {
          Key => [ $object[0] ],
          defined $object[1] ? ( VersionId => [ $object[1] ] ) : (),
          };
      }
    }
    else {                                    # list of keys
      croak 'argument must be array or list';
    }
  }
  elsif (@args) {
    @keys = map { { Key => [$_] } } @args;
  }
  else {
    croak 'must specify keys';
  }

  croak 'must not exceed ' . $MAX_DELETE_KEYS . ' keys'
    if @keys > $MAX_DELETE_KEYS;

  return \@keys;
}

#  @args => list of keys
#  $args[0] => array of hashes (Key, [VersionId]) VersionId is optional
#  $args[0] => array of scalars (keys)
#  $args[0] => code reference that returns key, version id or empty
#  $args[0] => hash ({ quiet => 1, keys => $keys})

# Throws exception if no keys or in wrong format...
########################################################################
sub delete_keys {
########################################################################
  my ( $self, @args ) = @_;

  my ( $keys, $quiet_mode, $headers );

  if ( ref $args[0] && reftype( $args[0] ) eq 'HASH' ) {
    ( $keys, $quiet_mode, $headers ) = @{ $args[0] }{qw(keys quiet headers)};
    $keys = _format_delete_keys($keys);
  }
  else {
    $keys = _format_delete_keys(@args);
  }

  if ( defined $quiet_mode ) {
    $quiet_mode = $quiet_mode ? 'true' : 'false';
  }
  else {
    $quiet_mode = 'false';
  }

  my $content = {
    xmlns  => $S3_XMLNS,
    Quiet  => [$quiet_mode],
    Object => $keys,
  };

  my $xml_content = XMLout(
    $content,
    RootName => 'Delete',
    XMLDecl  => $XMLDECL,
  );

  my $account = $self->account;

  my $md5        = md5($xml_content);
  my $md5_base64 = encode_base64($md5);

  chomp $md5_base64;

  $headers //= {};

  $headers->{'Content-MD5'} = $md5_base64;

  return $account->_send_request(
    { method  => 'POST',
      region  => $self->region,
      path    => $self->_uri() . '?delete',
      headers => $headers,
      data    => $xml_content,
    },
  );
}

########################################################################
sub delete_bucket {
########################################################################
  my ($self) = @_;

  croak 'Unexpected arguments'
    if @_ > 1;

  return $self->account->delete_bucket($self);
}

########################################################################
sub list_v2 {
########################################################################
  my ( $self, $conf ) = @_;

  $conf ||= {};

  $conf->{bucket}      = $self->bucket;
  $conf->{'list-type'} = '2';

  if ( $conf->{'marker'} ) {
    $conf->{'continuation-token'} = delete $conf->{'marker'};
  }

  return $self->list($conf);
}

########################################################################
sub list {
########################################################################
  my ( $self, $conf ) = @_;

  $conf ||= {};

  $conf->{bucket} = $self->bucket;

  return $self->account->list_bucket($conf);
}

########################################################################
sub list_all_v2 {
########################################################################
  my ( $self, $conf ) = @_;

  $conf //= {};

  $conf->{bucket} = $self->bucket;

  return $self->account->list_bucket_all_v2($conf);
}

########################################################################
sub list_all {
########################################################################
  my ( $self, $conf ) = @_;

  $conf //= {};

  $conf->{bucket} = $self->bucket;

  return $self->account->list_bucket_all($conf);
}

########################################################################
sub get_acl {
########################################################################
  my ( $self, $key, $headers ) = @_;

  my $account = $self->account;

  my $request = $account->_make_request(
    { region  => $self->region,
      method  => 'GET',
      path    => $self->_uri($key) . '?acl=',
      headers => $headers // {},
    },
  );

  my $old_redirectable = $account->ua->requests_redirectable;
  $account->ua->requests_redirectable( [] );

  my $response = $account->_do_http($request);

  if ( $response->code =~ /^30/xsm ) {
    my $xpc = $account->_xpc_of_content( $response->content );
    my $uri = URI->new( $response->header('location') );

    my $old_host = $account->host;
    $account->host( $uri->host );

    $request = $account->_make_request(
      { region  => $self->region,
        method  => 'GET',
        path    => $uri->path,
        headers => {},
      },
    );

    $response = $account->_do_http($request);

    $account->ua->requests_redirectable($old_redirectable);
    $account->host($old_host);
  }

  my $content;

  # do we test for NOT FOUND, returning undef?
  if ( $response->code ne $HTTP_NOT_FOUND ) {
    $account->_croak_if_response_error($response);
    $content = $response->content;
  }

  return $content;
}

########################################################################
sub set_acl {
########################################################################
  my ( $self, $conf ) = @_;

  my $account = $self->account;

  $conf //= {};

  croak 'need either acl_xml or acl_short'
    if !$conf->{acl_xml} && !$conf->{acl_short};

  croak 'cannot provide both acl_xml and acl_short'
    if $conf->{acl_xml} && $conf->{acl_short};

  my $path = $self->_uri( $conf->{key} ) . '?acl';

  my $headers = $conf->{headers};

  if ( $conf->{acl_short} ) {
    $headers->{'x-amz-acl'} //= $conf->{acl_short};
  }

  my $xml = $conf->{acl_xml} // $EMPTY;

  $headers->{'Content-Length'} = length $xml;

  return $account->_send_request_expect_nothing(
    { method  => 'PUT',
      path    => $path,
      headers => $headers,
      data    => $xml,
      region  => $self->region,
    },
  );
}

########################################################################
sub get_location_constraint {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $bucket, $headers, $region )
    = @{$parameters}{qw(bucket headers region)};

  my $account = $self->account;
  $bucket //= $self->bucket;

  my $location = $account->_send_request(
    { region  => $region // $self->region,
      method  => 'GET',
      path    => $bucket . '/?location=',
      headers => $headers,
    },
  );

  return $location
    if $location;

  croak $account->errstr
    if $account->_remember_errors($location);

  return;
}

########################################################################
sub last_response {
########################################################################
  my ($self) = @_;

  return $self->account->last_response;
}

########################################################################
sub err {
########################################################################
  my ($self) = @_;

  return $self->account->err;
}

########################################################################
sub errstr {
########################################################################
  my ($self) = @_;

  return $self->account->errstr;
}

########################################################################
sub error {
########################################################################
  my ($self) = @_;

  return $self->account->error;
}

########################################################################
sub _content_sub {
########################################################################
  my ( $filename, $buffer_size ) = @_;

  my $stat = stat $filename;

  my $remaining = $stat->size;
  my $blksize   = $stat->blksize || $buffer_size;

  croak "$filename not a readable file with fixed size"
    if !-r $filename || !$remaining;

  my $fh = IO::File->new( $filename, 'r' )
    or croak "Could not open $filename: $OS_ERROR";

  $fh->binmode;

  return sub {
    my $buffer;

    # upon retries the file is closed and we must reopen it
    if ( !$fh->opened ) {
      $fh = IO::File->new( $filename, 'r' )
        or croak "Could not open $filename: $OS_ERROR";

      $fh->binmode;

      $remaining = $stat->size;
    }

    my $read = $fh->read( $buffer, $blksize );

    if ( !$read ) {
      croak
        "Error while reading upload content $filename ($remaining remaining) $OS_ERROR"
        if $OS_ERROR and $remaining;

      $fh->close # otherwise, we found EOF
        or croak "close of upload content $filename failed: $OS_ERROR";

      $buffer ||= $EMPTY; # LWP expects an empty string on finish, read returns 0
    }

    $remaining -= length $buffer;

    return $buffer;
  };
}

########################################################################
sub _create_multipart_upload_request {
########################################################################
  my ($parts_hr) = @_;

  my @parts;

  foreach my $part_num ( sort { $a <=> $b } keys %{$parts_hr} ) {
    push @parts,
      {
      PartNumber => $part_num,
      ETag       => $parts_hr->{$part_num},
      };
  }

  return create_xml_request(
    { CompleteMultipartUpload => { Part => \@parts } } );
}

1;

__END__

=pod

=head1 NAME

Amazon::S3::Bucket - A container class for a S3 bucket and its contents.

=head1 SYNOPSIS

  use Amazon::S3;
  
  # creates bucket object (no "bucket exists" check)
  my $bucket = $s3->bucket("foo"); 
  
  # create resource with meta data (attributes)
  my $keyname = 'testing.txt';
  my $value   = 'T';
  $bucket->add_key(
      $keyname, $value,
      {   content_type        => 'text/plain',
          'x-amz-meta-colour' => 'orange',
      }
  );
  
  # list keys in the bucket
  $response = $bucket->list
      or die $s3->err . ": " . $s3->errstr;
  print $response->{bucket}."\n";
  for my $key (@{ $response->{keys} }) {
        print "\t".$key->{key}."\n";  
  }

  # check if resource exists.
  print "$keyname exists\n" if $bucket->head_key($keyname);

  # delete key from bucket
  $bucket->delete_key($keyname);

=head1 DESCRIPTION

Class for interacting with AWS S3 buckets.

=head1 METHODS AND SUBROUTINES

=head2 new

Instaniates a new bucket object. 

Pass a hash or hash reference containing various options:

=over

=item bucket (required)

The name (identifier) of the bucket.

=item account (required)

The L<S3::Amazon> object (representing the S3 account) this
bucket is associated with.

=item buffer_size

The buffer size used for reading and writing objects to S3.

default: 4K

=item region

If no region is set and C<verify_region> is set to true, the region of
the bucket will be determined by calling the
C<get_location_constraint> method.  Note that this will decrease
performance of the constructor. If you know the region or are
operating in only 1 region, set the region in the C<account> object
(C<Amazon::S3>).

=item logger

Sets the logger.  The logger should be a blessed reference capable of
providing at least a C<debug> and C<trace> method for recording log
messages. If no logger object is passed the C<account> object's logger
object will be used.

=item verify_region

Indicates that the bucket's region should be determined by calling the
C<get_location_constraint> method.

default: false

=back

I<NOTE:> This method does not check if a bucket actually exists unless
you set C<verify_region> to true. If the bucket does not exist,
the constructor will set the region to the default region specified by
the L<Amazon::S3> object (C<account>) that you passed.

Typically a developer will not call this method directly,
but work through the interface in L<S3::Amazon> that will
handle their creation.

=head2 add_key

 add_key( key, value, configuration)

Write a new or existing object to S3.

=over

=item key

A string identifier for the object being written to the bucket.

=item value

A SCALAR string representing the contents of the object.

=item configuration

A HASHREF of configuration data for this key. The configuration
is generally the HTTP headers you want to pass to the S3
service. The client library will add all necessary headers.
Adding them to the configuration hash will override what the
library would send and add headers that are not typically
required for S3 interactions.

=item acl_short (optional)

In addition to additional and overriden HTTP headers, this
HASHREF can have a C<acl_short> key to set the permissions
(access) of the resource without a seperate call via
C<add_acl> or in the form of an XML document.  See the
documentation in C<add_acl> for the values and usage. 

=back

Returns a boolean indicating the sucess or failure of the call. Check
C<err> and C<errstr> for error messages if this operation fails. To
examine the raw output of the response from the API call, use the
C<last_response()> method.

  my $retval = $bucket->add_key('foo', $content, {});

  if ( !$retval ) {
    print STDERR Dumper([$bucket->err, $bucket->errstr, $bucket->last_response]);
  }

=head2 add_key_filename

The method works like C<add_key> except the value is assumed
to be a filename on the local file system. The file will 
be streamed rather then loaded into memory in one big chunk.

=head2 copy_object %parameters

Copies an object from one bucket to another bucket. I<Note that the
bucket represented by the bucket object is the destination.> Returns a
hash reference to the response object (C<CopyObjectResult>).

Headers returned from the request can be obtained using the
C<last_response()> method.

 my $headers = { $bucket->last_response->headers->flatten };

Throws an exception if the response code is not 2xx. You can get an
extended error message using the C<errstr()> method.

 my $result = eval { return $s3->copy_object( key => 'foo.jpg',
     source => 'boo.jpg' ); };
 
 if ($@) {
   die $s3->errstr;
 }

Examples:

 $bucket->copy_object( key => 'foo.jpg', source => 'boo.jpg' );

 $bucket->copy_object(
   key    => 'foo.jpg',
   source => 'boo.jpg',
   bucket => 'my-source-bucket'
 );
 
 $bucket->copy_object(
   key     => 'foo.jpg',
   headers => { 'x-amz-copy-source' => 'my-source-bucket/boo.jpg'
   );

See L<CopyObject|
https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html>
for more details.

C<%parameters> is a list of key/value pairs described below:

=over

=item key (required)

Name of the destination key in the bucket represented by the bucket object.

=item headers (optional)

Hash or array reference of headers to send in the request.

=item bucket (optional)

Name of the source bucket. Default is the same bucket as the destination.

=item source (optional)

Name of the source key in the source bucket. If not provided, you must
provide the source in the `x-amz-copy-source` header.

=back

=head2 head_key $key_name

Returns a configuration HASH of the given key. If a key does
not exist in the bucket C<undef> will be returned.

HASH will contain the following members:

=over

=item content_length

=item content_type

=item etag

=item value

=back

=head2 delete_key

 delete_key(key, [version])

Permanently removes C<$key_name> from the bucket. Returns a
boolean value indicating the operation's success.

=head2 delete_keys @keys

=head2 delete_keys $keys

Permanently removes keys from the bucket. Returns the response body
from the API call. Returns C<undef> on non '2xx' return codes.

See <Deleting Amazon S3 objects | https://docs.aws.amazon.com/AmazonS3/latest/userguide/DeletingObjects.html>

The argument to C<delete_keys> can be:

=over 5

=item * list of key names

=item * an array of hashes where each hash reference contains the keys
C<Key> and optionally C<VersionId>.

=item * an array of scalars where each scalar is a key name

=item * a hash of options where the hash contains

=item * a callback that returns the key and optionally the version id

=over 10

=item quiet

Boolean indicating quiet mode

=item keys

An array of keys containing scalars or hashes as describe above.

=back

=back

Examples:

 # delete a list of keys
 $bucket->delete_keys(qw( foo bar baz));

 # delete an array of keys
 $bucket->delete_keys([qw(foo bar baz)]);

 # delete an array of keys in quiet mode 
 $bucket->delete({ quiet => 1, keys => [ qw(foo bar baz) ]);

 # delete an array of versioned objects
 $bucket->delete_keys([ { Key => 'foo', VersionId => '1'} ]);

 # callback
 my @key_list = qw(foo => 1, bar => 3, biz => 1);

 $bucket->delete_keys(
   sub {
     return ( shift @key_list, shift @key_list );
   }
 );

I<When using a callback, the keys are deleted in bulk. The
C<DeleteObjects> API is only called once.>

=head2 delete_bucket

Permanently removes the bucket from the server. A bucket
cannot be removed if it contains any keys (contents).

This is an alias for C<$s3-E<gt>delete_bucket($bucket)>.

=head2 get_key key, [method, headers, uri_params]

=head2 get_key hashref

Takes a key and optional arguments and returns the hash of metatdata
which includes the contents of the S3 object.

Example:

 $bucket->get_key(
   key        => 'foo',
   uri_params => { versionId => $version },
   headers    => { Range     => 'bytes=0-9' }
 );

=over 5

=item key

Key name

=item method

HTTP method (GET or HEAD)

default: GET

=item headers

A hashref of additional headers to send with the request

=item uri-params

A hashref containing key/value pairs representing the URI parameters
you want to include in the request. Possible parameters are shown below.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html#API_GetObject_RequestSyntax>

=over 10

=item partNumber

=item response-cache-control

=item response-content-disposition

=item response-content-encoding

=item response-content-language

=item response-content-type

=item response-expires

=item versionId

=back

=back

The method returns C<undef> if the key does not exist in the
bucket and throws an exception (dies) on server errors.

On success, the method returns a HASHREF containing:

=over

=item content_type

=item etag

=item value

=item @meta

=item content_range

=item last_modified

=back

I<Note that the C<etag> for ranged gets is the MD5 value for the entire file.>

=head2 get_key_filename $key_name, [$method, $filename, $headers, $uri_params]

=head2 get_key_filename $args

Pass a list of arguments or a hash of key value/pairs.

This method works like C<get_key>, but takes an added
filename that the S3 resource will be written to.

If C<filename> is undefined or an empty string, the a file with the
key name will be created.

=over 5

=item key (required)

=item method

default: GET

=item filename

default: name of the key

=item headers

A hashref of additional headers to send with the request

=item uri-params

A hashref containing key/value pairs representing the URI parameters
you want to include in the request. See L</get_key> for possible parameters.

See L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html#API_GetObject_RequestSyntax>

=back

=head2 list

List all keys in this bucket.

See L<Amazon::S3/list_bucket> for documentation of this
method.

=head2 list_v2

See L<Amazon::S3/list_bucket_v2> for documentation of this
method.

=head2 list_all

List all keys in this bucket without having to worry about
'marker'. This may make multiple requests to S3 under the
hood.

See L<Amazon::S3/list_bucket_all> for documentation of this
method.

=head2 list_all_v2

Same as C<list_all> but uses the version 2 API for listing keys.

See L<Amazon::S3/list_bucket_all_v2> for documentation of this
method.

=head2 get_acl

Retrieves the Access Control List (ACL) for the bucket or
resource as an XML document.

=over

=item key

The key of the stored resource to fetch. This parameter is
optional. By default the method returns the ACL for the
bucket itself.

=back

=head2 set_acl

 set_acl(acl)

Sets the Access Control List (ACL) for the bucket or
resource. Requires a HASHREF argument with one of the following keys:

=over

=item acl_xml

An XML string which contains access control information
which matches Amazon's published schema.

=item acl_short

Alternative shorthand notation for common types of ACLs that
can be used in place of a ACL XML document.

According to the Amazon S3 API documentation the following recognized acl_short
types are defined as follows:

=over

=item private

Owner gets FULL_CONTROL. No one else has any access rights.
This is the default.

=item public-read

Owner gets FULL_CONTROL and the anonymous principal is
granted READ access. If this policy is used on an object, it
can be read from a browser with no authentication.

=item public-read-write

Owner gets FULL_CONTROL, the anonymous principal is granted
READ and WRITE access. This is a useful policy to apply to a
bucket, if you intend for any anonymous user to PUT objects
into the bucket.

=item authenticated-read

Owner gets FULL_CONTROL, and any principal authenticated as
a registered Amazon S3 user is granted READ access.

=back

=item key

The key name to apply the permissions. If the key is not
provided the bucket ACL will be set.

=back

Returns a boolean indicating the operations success.

=head2 get_location_constraint

Returns the location constraint (region the bucket resides in) for a
bucket. Returns undef if there is no location constraint.

Valid values that may be returned:

 af-south-1
 ap-east-1
 ap-northeast-1
 ap-northeast-2
 ap-northeast-3
 ap-south-1
 ap-southeast-1
 ap-southeast-2
 ca-central-1
 cn-north-1
 cn-northwest-1
 EU
 eu-central-1
 eu-north-1
 eu-south-1
 eu-west-1
 eu-west-2
 eu-west-3
 me-south-1
 sa-east-1
 us-east-2
 us-gov-east-1
 us-gov-west-1
 us-west-1
 us-west-2

For more information on location constraints, refer to the
documentation for
L<GetBucketLocation|https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLocation.html>.

=head2 err

The S3 error code for the last error the account encountered.

=head2 errstr

A human readable error string for the last error the account encountered.

=head2 error

The decoded XML string as a hash object of the last error.

=head2 last_response

Returns the last C<HTTP::Response> to an API call.

=head1 MULTIPART UPLOAD SUPPORT

From Amazon's website:

I<Multipart upload allows you to upload a single object as a set of
parts. Each part is a contiguous portion of the object's data. You can
upload these object parts independently and in any order. If
transmission of any part fails, you can retransmit that part without
affecting other parts. After all parts of your object are uploaded,
Amazon S3 assembles these parts and creates the object. In general,
when your object size reaches 100 MB, you should consider using
multipart uploads instead of uploading the object in a single
operation.>

See L<https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html> for more information about multipart uploads.

=over 5

=item * Maximum object size 5TB

=item * Maximum number of parts 10,000

=item * Part numbers 1 to 10,000 (inclusive)

=item * Part size 5MB to 5GB. There is no limit on the last part of your multipart upload.

=item * Maximum nubmer of parts returned for a list parts request - 1000

=item * Maximum number of multipart uploads returned in a list multipart uploads request - 1000

=back

A multipart upload begins by calling
C<initiate_multipart_upload()>. This will return an identifier that is
used in subsequent calls.

 my $bucket = $s3->bucket('my-bucket');
 my $id = $bucket->initiate_multipart_upload('some-big-object');

 my $part_list = {};

 my $part = 1;
 my $etag = $bucket->upload_part_of_multipart_upload('my-bucket', $id, $part, $data, length $data);
 $part_list{$part++} = $etag;

 $bucket->complete_multipart_upload('my-bucket', $id, $part_list);

=heads upload_multipart_object

 upload_multipart_object( ... )

Convenience routine C<upload_multipart_object> that encapsulates the
multipart upload process. Accepts a hash or hash reference of
arguments. If successful, a reference to a hash that contains the part
numbers and etags of the uploaded parts.

You can pass a data object, callback routine or a file handle.

=over 5

=item key

Name of the key to create.

=item data

Scalar object that contains the data to write to S3.

=item callback

Optionally provided a callback routine that will be called until you
pass a buffer with a length of 0. Your callback will receive no
arguments but should return a tuple consisting of a B<reference> to a
scalar object that contains the data to write and a scalar that
represents the length of data. Once you return a zero length buffer
the multipart process will be completed.

=item fh

File handle of an open file. The file must be greater than the minimum
chunk size for multipart uploads otherwise the method will throw an
exception.

=item abort_on_error

Indicates whether the multipart upload should be aborted if an error
is encountered. Amazon will charge you for the storage of parts that
have been uploaded unless you abort the upload.

default: true

=back

=head2 abort_multipart_upload

 abort_multipart_upload(key, multpart-upload-id)

Abort a multipart upload

=head2 complete_multipart_upload

 complete_multipart_upload(key, multpart-upload-id, parts)

Signal completion of a multipart upload. C<parts> is a reference to a
hash of part numbers and etags.

=head2 initiate_multipart_upload

 initiate_multipart_upload(key, headers)

Initiate a multipart upload. Returns an id used in subsequent call to
C<upload_part_of_multipart_upload()>.

=head2 list_multipart_upload_parts

List all the uploaded parts of a multipart upload

=head2 list_multipart_uploads

List multipart uploads in progress

=head2 upload_part_of_multipart_upload

  upload_part_of_multipart_upload(key, id, part, data, length)

Upload a portion of a multipart upload

=over 5

=item key

Name of the key in the bucket to create.

=item id

The multipart-upload id return in the C<initiate_multipart_upload> call.

=item part

The next part number (part numbers start at 1).

=item data

Scalar or reference to a scalar that contains the data to upload.

=item length (optional)

Length of the data.

=back

=head1 SEE ALSO

L<Amazon::S3>

=head1 AUTHOR

Please see the L<Amazon::S3> manpage for author, copyright, and
license information.

=head1 CONTRIBUTORS

Rob Lauer
Jojess Fournier
Tim Mullin
Todd Rinaldo
luiserd97

=cut
