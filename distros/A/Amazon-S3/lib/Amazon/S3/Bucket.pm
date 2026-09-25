package Amazon::S3::Bucket;

use strict;
use warnings;

use Amazon::S3::Constants qw(:all);
use Amazon::S3::Util qw(:all);

use Carp;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_hex);
use Digest::MD5::File qw(file_md5 file_md5_hex);
use English qw(-no_match_vars);
use File::stat;
use File::Temp qw(tempfile);
use IO::File;
use IO::Scalar;
use List::Util qw(none pairs any);
use MIME::Base64;
use Scalar::Util qw(reftype);
use URI;
use XML::Simple; ## no critic (DiscouragedModules)

use parent qw(Exporter Class::Accessor::Fast);

our $VERSION = '2.1.1'; ## no critic (RequireInterpolation)

__PACKAGE__->mk_accessors(
  qw(
    account
    bucket
    buffer_size
    creation_date
    logger
    region
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

    $self->logger->debug( sprintf "bucket: %s region: %s\n", $self->bucket, ( $region // $EMPTY ) );

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
sub _add_key {
########################################################################
  my ( $self, @args ) = @_;

  my ( $data, $headers, $key ) = @{ $args[0] }{qw{data headers key}};

  my $account = $self->account;

  my $args = {
    method  => 'PUT',
    path    => $self->_uri($key),
    headers => $headers,
    data    => $data,
    region  => $self->region,
  };

  return $account->send_request_expect_nothing_probed($args)
    if ref $data;

  return $account->send_request_expect_nothing($args);
}

########################################################################
sub add_key {
########################################################################
  my ( $self, @args ) = @_;

  my ( $key, $value, $conf, $source );

  if ( @args == 1 && ref $args[0] && reftype( $args[0] ) eq 'HASH' ) {
    my $parameters = { %{ $args[0] } };

    $key = delete $parameters->{key};

    $source = $self->_stage_upload_source($parameters);

    if ( exists $source->{data} ) {
      $value = $source->{data};
    }
    else {
      $value = \$source->{filename};
    }

    delete @{$parameters}{qw(data filename fh callback)};

    $conf = $parameters;
  }
  else {
    ( $key, $value, $conf ) = @args;
  }

  croak 'must specify key'
    if !$key || !length $key;

  $conf //= {};

  my $account = $self->account;

  my $retval;

  eval {
    my $headers = delete $conf->{headers};
    $headers //= {};

    if ( $conf->{acl_short} ) {
      $account->_validate_acl_short( $conf->{acl_short} );

      $conf->{'x-amz-acl'} = $conf->{acl_short};

      delete $conf->{acl_short};
    }

    $headers = { %{$conf}, %{$headers} };

    set_md5_header( data => $value, headers => $headers );

    my $algorithm      = lc $account->checksum_algorithm;
    my $checksum_types = $account->checksum_types;

    if ( exists $checksum_types->{$algorithm} ) {
      my %digest_parameters;

      if ( ref $value ) {
        $digest_parameters{filename} = ${$value};
      }
      else {
        $digest_parameters{data} = $value;
      }

      my $digest = $checksum_types->{$algorithm}->(%digest_parameters);

      $headers->{ 'x-amz-checksum-' . $algorithm } = encode_base64( $digest, $EMPTY );
    }

    if ( ref $value ) {
      $value = _content_sub( ${$value}, $self->buffer_size );

      $headers->{'x-amz-content-sha256'} = 'UNSIGNED-PAYLOAD';
    }

    my $request_error;

    eval { $retval = $self->_add_key( { headers => $headers, data => $value, key => $key, }, ); };

    $request_error = $EVAL_ERROR;

    if ($request_error) {
      my $rsp = $account->last_response;

      if ( $rsp && $rsp->code eq $HTTP_MOVED_PERMANENTLY ) {
        $self->region( $rsp->headers->{'x-amz-bucket-region'} );
      }

      $retval = $self->_add_key(
        { headers => $headers,
          data    => $value,
          key     => $key,
        },
      );
    }
  };

  my $error = $EVAL_ERROR;

  if ( $source && $source->{temporary} ) {
    my $filename = $source->{filename};

    if ( !unlink $filename ) {
      warn "Could not remove temporary upload file $filename: $OS_ERROR\n";
    }
  }

  die $error
    if $error;

  return $retval;
}

########################################################################
sub add_key_filename {
########################################################################
  my ( $self, $key, $filename, $conf ) = @_;

  $conf //= {};

  return $self->add_key(
    { %{$conf},
      key      => $key,
      filename => $filename,
    }
  );
}

########################################################################
sub _stage_upload_source {
########################################################################
  my ( $self, $parameters ) = @_;

  my @sources;

  foreach my $name (qw(data filename fh callback)) {
    if ( $name eq 'data' ) {
      push @sources, $name
        if exists $parameters->{$name};

      next;
    }

    push @sources, $name
      if defined $parameters->{$name};
  }

  croak 'one of data, filename, fh or callback must be specified'
    if !@sources;

  croak 'only one of data, filename, fh or callback may be specified'
    if @sources > 1;

  my $source_type = $sources[0];

  if ( $source_type eq 'data' ) {
    return { data => $parameters->{data}, };
  }

  if ( $source_type eq 'filename' ) {
    return { filename => $parameters->{filename}, };
  }

  my $callback;

  if ( $source_type eq 'fh' ) {
    my $fh = $parameters->{fh};

    $callback = sub {
      my $buffer;

      my $read = $fh->read( $buffer, $self->buffer_size );

      croak "Error while reading upload content: $OS_ERROR"
        if !defined $read;

      return
        if !$read;

      return \$buffer;
    };
  }
  else {
    $callback = $parameters->{callback};

    croak 'callback must be a reference to a subroutine'
      if !ref $callback || reftype($callback) ne 'CODE';
  }

  my ( $tmp_fh, $filename ) = tempfile( UNLINK => $FALSE );

  $tmp_fh->binmode;

  eval {
    while ($TRUE) {
      my $buffer = $callback->();

      last
        if !defined $buffer;

      croak 'upload callback must return a scalar reference'
        if !ref $buffer || reftype($buffer) ne 'SCALAR';

      print {$tmp_fh} ${$buffer}
        or croak "Could not write temporary upload file: $OS_ERROR";
    }

    $tmp_fh->close
      or croak "Could not close temporary upload file: $OS_ERROR";
  };

  my $error = $EVAL_ERROR;

  if ($error) {
    eval { $tmp_fh->close; };

    if ( -e $filename && !unlink $filename ) {
      warn "Could not remove temporary upload file $filename: $OS_ERROR\n";
    }

    die $error;
  }

  return {
    filename  => $filename,
    temporary => $TRUE,
  };
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
    my $data = ref $parameters->{data} ? $parameters->{data} : \$parameters->{data};

    $parameters->{fh} = IO::Scalar->new($data);
  }

  # ...having a file handle implies, we use this callback
  if ( $parameters->{fh} ) {
    my $fh = $parameters->{fh};

    $fh->seek( 0, 2 );

    my $length = $fh->tell;
    $fh->seek( 0, 0 );

    $logger->trace( sub { return sprintf 'length of object: %s', $length; } );

    croak 'length of the object must be >= ' . $MIN_MULTIPART_UPLOAD_CHUNK_SIZE
      if $length < $MIN_MULTIPART_UPLOAD_CHUNK_SIZE;

    my $chunk_size
      = ( $parameters->{chunk_size} && $parameters->{chunk_size} ) > $MIN_MULTIPART_UPLOAD_CHUNK_SIZE
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

  my $headers = { %{ $parameters->{headers} || {} } };

  $headers->{'x-amz-checksum-algorithm'} //= uc $self->account->checksum_algorithm;

  my ( $id, $algorithm )
    = $self->initiate_multipart_upload( $parameters->{key}, $headers );

  $logger->trace( sprintf 'multipart id: %s', $id );

  my $part = 1;

  my %parts;
  my %return_parts;

  my $key = $parameters->{key};

  my $retval = eval {
    while (1) {
      my ( $buffer, $length ) = $parameters->{callback}->();
      last if !$buffer;

      my ( $etag, $checksum ) = $self->upload_part_of_multipart_upload(
        { id        => $id,
          key       => $key,
          data      => $buffer,
          part      => $part,
          algorithm => $algorithm,
        },
      );
      my $part_number = $part++;

      $parts{$part_number}        = { etag => $etag, checksum => $checksum };
      $return_parts{$part_number} = $etag;
    }

    $self->complete_multipart_upload( $parameters->{key}, $id, \%parts, $algorithm );
  };

  my $err = $EVAL_ERROR;

  warn $err
    if $err;

  if ( $err && $parameters->{abort_on_error} ) {
    $self->abort_multipart_upload( $key, $id );
    %parts        = ();
    %return_parts = ();
  }

  return \%return_parts;
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
  my $acct           = $self->account;
  my $checksum_types = $acct->checksum_types;

  $headers = { %{ $headers // {} } };

  my $algorithm = $EMPTY;

  if ( exists $headers->{'x-amz-checksum-algorithm'} ) {
    $algorithm = lc $headers->{'x-amz-checksum-algorithm'};

    if ( none { $algorithm eq $_ } qw(crc64nvme crc32 crc32c) ) {
      croak sprintf 'Checksum algorithm %s is not available for multipart upload', uc $algorithm
        if !exists $checksum_types->{$algorithm};
    }

    if ( any { $algorithm eq $_ } qw(crc64nvme crc32 crc32c) ) {
      $headers->{'x-amz-checksum-type'} = 'FULL_OBJECT';
    }
  }

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

  return wantarray ? ( $r->{UploadId}, lc $algorithm ) : $r->{UploadId};
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

  my ( $key, $upload_id, $part_number, $data, $length, $algorithm );

  if ( @args == 1 ) {
    if ( reftype( $args[0] ) eq 'HASH' ) {
      ( $key, $upload_id, $part_number, $data, $length, $algorithm )
        = @{ $args[0] }{qw{ key id part data length algorithm}};
    }
    elsif ( reftype( $args[0] ) eq 'ARRAY' ) {
      ( $key, $upload_id, $part_number, $data, $length, $algorithm ) = @{ $args[0] };
    }
  }
  else {
    ( $key, $upload_id, $part_number, $data, $length, $algorithm ) = @args;
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

  $algorithm = lc( $algorithm // $EMPTY );

  my $checksum;

  my $checksum_types = $self->account->checksum_types;

  if ( exists $checksum_types->{$algorithm} ) {
    my $digest = $checksum_types->{$algorithm}->( data => $data, );

    $checksum = encode_base64( $digest, $EMPTY );

    $headers->{ 'x-amz-checksum-' . $algorithm } = $checksum;
  }

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

  return wantarray ? ( $etag, $checksum ) : $etag;
}

#
# Inform Amazon that the multipart upload has been completed
# You must supply a hash of part Numbers => eTags
# For amazon to use to put the file together on their servers.
#
########################################################################
sub complete_multipart_upload {
########################################################################
  my ( $self, $key, $upload_id, $parts_hr, $algorithm ) = @_;

  $self->logger->debug( Dumper( [ $key, $upload_id, $parts_hr ] ) );

  croak 'Object key is required'
    if !$key;

  croak 'Upload id is required'
    if !$upload_id;

  croak 'Part number => etag hashref is required'
    if ref $parts_hr ne 'HASH';

  $algorithm = lc( $algorithm // $EMPTY );

  # The complete command requires sending a block of xml containing all
  # the part numbers and their associated etags (returned from the upload)
  my $content = _create_multipart_upload_request( $parts_hr, $algorithm );

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

  $acct->_croak_if_response_error($response);

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

  my ( $key, $method, $headers, $uri_params, $verify_checksums );

  if ( ref $args[0] ) {
    ( $key, $method, $headers, $uri_params, $verify_checksums )
      = @{ $args[0] }{qw(key method headers uri_params verify_checksums)};
  }
  else {
    ( $key, $method, $headers, $uri_params ) = @args;
  }

  return $self->_get_key(
    key              => $key,
    method           => $method,
    filename         => undef,
    headers          => $headers,
    uri_params       => $uri_params,
    verify_checksums => $verify_checksums,
  );
}

########################################################################
sub _get_key {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $key, $method, $filename, $headers, $uri_params, $verify_checksums )
    = @{$parameters}{qw(key method filename headers uri_params verify_checksums)};

  $verify_checksums //= $self->account->verify_checksums;

  $method //= 'GET';

  my $uri = $self->_uri($key);

  if ( $uri_params && keys %{$uri_params} ) {
    $uri .= $QUESTION_MARK . create_query_string($uri_params);
  }

  if ( ref $filename ) {
    $filename = ${$filename};
  }

  my $acct = $self->account;

  $headers = { %{ $headers // {} } };  # do not mutate caller's headers

  if ( $verify_checksums && $method eq 'GET' ) {
    $headers->{'x-amz-checksum-mode'} = 'ENABLED';
  }

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

  my %checksums;

  foreach my $header ( $response->headers->header_field_names ) {
    if ( $header =~ /\Ax-amz-checksum-(.+)\z/ixsm ) {
      my $algorithm = lc $1;
      if ( $algorithm ne 'type' ) {
        $checksums{$algorithm} = $response->header($header);
      }
    }
  }

  my $retval = {
    content_length => ( $response->content_length || 0 ),
    content_type   => scalar $response->content_type,
    etag           => $etag,
    value          => ( $response->content // $EMPTY ),
    content_range  => ( $response->header('Content-Range') || $EMPTY ),
    last_modified  => ( $response->header('Last-Modified') || $EMPTY ),
    checksums      => \%checksums,
    checksum_type  => scalar $response->header('x-amz-checksum-type'),
  };

  if ( $verify_checksums && $method eq 'GET' && $response->code ne $HTTP_PARTIAL_CONTENT ) {
    $self->_verify_checksums(
      checksums     => $retval->{checksums},
      checksum_type => $retval->{checksum_type},
      filename      => $filename,
      data          => $retval->{value},
    );
  }

  foreach my $header ( $response->headers->header_field_names ) {
    next if $header !~ /x-amz-meta-/ixsm;
    $retval->{ lc $header } = $response->header($header);
  }

  return $retval;
}

########################################################################
sub _verify_checksums {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $checksums, $checksum_type, $filename, $data )
    = @{$parameters}{qw(checksums checksum_type filename data)};

  return $TRUE
    if !$checksums || !keys %{$checksums};

  return $TRUE
    if ( $checksum_type // $EMPTY ) ne 'FULL_OBJECT';

  my $checksum_types = $self->account->checksum_types;

  foreach my $algorithm ( keys %{$checksums} ) {
    next
      if !exists $checksum_types->{$algorithm};

    my %digest_parameters;

    if ( defined $filename ) {
      $digest_parameters{filename} = $filename;
    }
    else {
      $digest_parameters{data} = $data // $EMPTY;
    }

    my $digest = $checksum_types->{$algorithm}->(%digest_parameters);

    my $computed = encode_base64( $digest, $EMPTY );
    my $expected = $checksums->{$algorithm};

    croak sprintf 'Computed and response %s checksums do not match: %s : %s', uc($algorithm), $computed, $expected
      if $computed ne $expected;
  }

  return $TRUE;
}

########################################################################
sub get_key_filename {
########################################################################
  my ( $self, @args ) = @_;

  my ( $key, $method, $filename, $headers, $uri_params, $verify_checksums );

  if ( ref $args[0] ) {
    ( $key, $method, $filename, $headers, $uri_params, $verify_checksums )
      = @{ $args[0] }{qw(key method filename headers uri_params verify_checksums)};
  }
  else {
    ( $key, $method, $filename, $headers, $uri_params ) = @args;
  }

  if ( !defined $filename ) {
    $filename = $key;
  }

  return $self->_get_key(
    key              => $key,
    method           => $method,
    filename         => \$filename,
    headers          => $headers,
    uri_params       => $uri_params,
    verify_checksums => $verify_checksums,
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

    $request_headers{'x-amz-copy-source'} = sprintf '%s/%s', $bucket, urlencode($source);
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

  return $account->send_request_expect_nothing(
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
    if ( reftype( $args[0] ) eq 'ARRAY' ) {  # list of keys, no version ids
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
        else {  # array of keys
          push @keys, { Key => [$key], };
        }
      }
    }
    elsif ( reftype( $args[0] ) eq 'CODE' ) {  # sub that returns key, version id
      while ( my (@object) = $args[0]->() ) {
        last if !@object || !defined $object[0];

        push @keys,
          {
          Key => [ $object[0] ],
          defined $object[1] ? ( VersionId => [ $object[1] ] ) : (),
          };
      }
    }
    else {  # list of keys
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

  return $account->send_request(
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

  return $account->send_request_expect_nothing(
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

  my $location = $account->send_request(
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
      croak "Error while reading upload content $filename ($remaining remaining) $OS_ERROR"
        if $OS_ERROR and $remaining;

      $fh->close  # otherwise, we found EOF
        or croak "close of upload content $filename failed: $OS_ERROR";

      $buffer ||= $EMPTY;  # LWP expects an empty string on finish, read returns 0
    }

    $remaining -= length $buffer;

    return $buffer;
  };
}

########################################################################
sub _create_multipart_upload_request {
########################################################################
  my ( $parts_hr, $algorithm ) = @_;

  my @parts;

  foreach my $part_num ( sort { $a <=> $b } keys %{$parts_hr} ) {
    my $part = $parts_hr->{$part_num};

    my $entry = { PartNumber => $part_num, };

    if ( ref $part ) {
      $entry->{ETag} = $part->{etag};

      if ( defined $part->{checksum} ) {
        my $checksum_name = 'Checksum' . uc $algorithm;

        $entry->{$checksum_name} = $part->{checksum};
      }
    }
    else {
      # Legacy part_number => etag representation
      $entry->{ETag} = $part;
    }

    push @parts, $entry;
  }

  return create_xml_request( { CompleteMultipartUpload => { Part => \@parts } } );
}

1;

__END__

=pod

=head1 NAME

Amazon::S3::Bucket - An Amazon S3 bucket and object interface

=head1 SYNOPSIS

  use Amazon::S3;

  my $s3 = Amazon::S3->new(
    { credentials => $credentials,
      region      => 'us-east-1',
    }
  );

  my $bucket = $s3->bucket('example-bucket');

  $bucket->add_key(
    'example.txt',
    'hello world',
    { content_type => 'text/plain',
    }
  );

  my $object = $bucket->get_key('example.txt');

  my $response = $bucket->list_v2(
    { prefix => 'logs/',
    }
  );

  $bucket->delete_key('example.txt');

=head1 DESCRIPTION

C<Amazon::S3::Bucket> represents an Amazon S3 bucket and provides
bucket-scoped object operations.

Instances are normally created by L<Amazon::S3/bucket> or
L<Amazon::S3/bucketv2> rather than by calling C<new()> directly.

This document is primarily a method reference. For broader discussion
of credentials, checksums, object listing, multipart uploads, error
handling, and directory buckets, see L<Amazon::S3>.

=head1 METHODS AND SUBROUTINES

=head2 CONSTRUCTOR

=head3 new

  my $bucket = Amazon::S3::Bucket->new(%options);

  my $bucket = Amazon::S3::Bucket->new(\%options);

Creates and returns a bucket object.

The constructor accepts either a list of key/value pairs or a hash
reference.

The following options are supported:

=over 4

=item account

Required. The L<Amazon::S3> object associated with this bucket.

=item bucket

Required. Bucket name.

=item buffer_size

Buffer size used when streaming object data.

The default is 4096 bytes.

=item logger

Logger used by the bucket object.

When omitted, the logger from C<account> is used.

=item region

Region containing the bucket.

When omitted and C<verify_region> is false, the region configured on
the associated L<Amazon::S3> object is used.

=item verify_region

When true and no region is supplied, determine the bucket region by
calling C<get_location_constraint()>.

The default is false.

=back

The constructor throws an exception when C<bucket> or C<account> is
not supplied.

On success, returns the new C<Amazon::S3::Bucket> object.

=head2 ACCESSORS

=head3 account

  my $s3 = $bucket->account;

Gets or sets the associated L<Amazon::S3> object.

=head3 bucket

  my $name = $bucket->bucket;

Gets or sets the bucket name.

=head3 buffer_size

  my $buffer_size = $bucket->buffer_size;

  $bucket->buffer_size($bytes);

Gets or sets the buffer size used when streaming object data.

=head3 creation_date

  my $creation_date = $bucket->creation_date;

Gets or sets the creation date associated with the bucket object.

Bucket objects returned by L<Amazon::S3/buckets> may have this value
populated from the ListBuckets response.

=head3 logger

  my $logger = $bucket->logger;

  $bucket->logger($logger);

Gets or sets the logger used by the bucket object.

=head3 region

  my $region = $bucket->region;

  $bucket->region($region);

Gets or sets the region containing the bucket.

=head3 verify_region

  my $verify_region = $bucket->verify_region;

  $bucket->verify_region($boolean);

Gets or sets whether the bucket constructor should determine the
bucket region when no region is supplied.

=head2 OBJECT OPERATIONS

=head3 add_key

  my $ok = $bucket->add_key( $key, $value );

  my $ok = $bucket->add_key( $key, $value, %configuration, );

  my $ok = $bucket->add_key(
    { key     => $key,
      data    => $data,
      headers => %headers,
    }
  );

  my $ok = $bucket->add_key(
    { key      => $key,
      filename => $filename,
      headers  => %headers,
    }
  );

  my $ok = $bucket->add_key(
    { key     => $key,
      fh      => $fh,
      headers => %headers,
    }
  );

  my $ok = $bucket->add_key(
    { key      => $key,
      callback => $callback,
      headers  => %headers,
    }
  );
  
Creates or replaces an object.

The traditional positional interface and the hash-reference interface are
both supported.

=head4 Positional interface

The positional interface accepts:

=over 4

=item key

Required. Object key.

=item value

Required. Object content.

A scalar value is uploaded directly.

A scalar reference is interpreted as a filename and the referenced file
is streamed to S3.

Use C<add_key_filename()> when uploading a file by name.

=item configuration

Optional hash reference containing request headers and object
configuration.

Entries are added to the request headers. A nested C<headers> hash
reference may also be supplied; entries in C<headers> take precedence
over duplicate top-level configuration entries.

The special C<acl_short> entry sets C<x-amz-acl> after validating the
canned ACL value.

=back

=head4 Hash-reference interface

The hash-reference interface requires C<key> and exactly one upload
source.

Supported upload sources are:

=over 4

=item data

Scalar object content.

=item filename

Name of a local file containing the object data.

The supplied file is used directly and is not copied to temporary
storage.

=item fh

Filehandle from which object data is read.

The complete contents of the filehandle are staged in a temporary file
before the request is sent.

=item callback

Code reference that supplies object data.

The callback is repeatedly invoked until it returns C<undef>. Each
successful invocation must return a scalar reference containing the next
chunk of object data.

For example:

  my $callback = sub {
    return
      if !@chunks;

    my $chunk = shift @chunks;
  
    return \$chunk;
  };

The complete contents produced by the callback are staged in a temporary
file before the request is sent.

=back

Only one of C<data>, C<filename>, C<fh>, or C<callback> may be supplied.

Other entries in the hash reference are treated in the same manner as
the positional C<configuration> hash.

=head4 Temporary storage

Uploads using C<fh> or C<callback> are staged completely in a temporary
file before the S3 request begins.

Staging allows C[Amazon::S3](Amazon::S3) to determine the complete object size,
calculate request checksums, and replay the upload if necessary.

The system temporary directory must therefore be writable and must have
sufficient free space to hold the complete object. An upload using
C<fh> or C<callback> may fail before contacting S3 if temporary storage
cannot be created or written.

Uploads using C<data> do not require temporary storage.

Uploads using C<filename> use the supplied file directly and do not
create an additional temporary copy.

Temporary files created for C<fh> or C<callback> uploads are removed
after the upload completes or fails.

=head4 Checksums

C<Content-MD5> is added automatically.

C[Amazon::S3](Amazon::S3) also calculates and sends an S3 checksum automatically.
By default, CRC64NVME is used. Most applications do not need to select
or calculate a checksum explicitly.

The checksum algorithm can be changed using the associated
L[Amazon::S3](Amazon::S3) object's C<checksum_algorithm> setting.

See L[Amazon::S3/CHECKSUMS](Amazon::S3/CHECKSUMS).

=head4 Return Value

On success, returns a true value.

On failure, returns C<undef> or throws an exception depending on the
underlying request failure.

=head3 add_key_filename

  my $ok = $bucket->add_key_filename($key, $filename, %configuration,);

Creates or replaces an object using the contents of a local file.

This is a convenience wrapper around the C<filename> form of
C<add_key()>.

The supplied file is streamed directly and is not copied to temporary
storage.

Returns the same value as C<add_key()>.

See L</add_key>.

=head3 copy_object

  my $result = $bucket->copy_object(
    { key    => $destination_key,
      source => $source_key,
      bucket => $source_bucket,
      headers => \%headers,
    }
  );

  my $result = $bucket->copy_object(
    key    => $destination_key,
    source => $source_key,
    bucket => $source_bucket,
  );

Copies an S3 object.

The bucket represented by this object is the destination bucket.

The following parameters are supported:

=over 4

=item bucket

Optional source bucket name.

The default is the destination bucket.

=item headers

Optional hash or array reference containing request headers.

C<x-amz-copy-source> may be supplied directly in these headers.

C<x-amz-tagging-directive> defaults to C<COPY>.

=item key

Required destination object key.

=item source

Source object key.

Either C<source> or the C<x-amz-copy-source> request header is
required.

=back

When C<x-amz-copy-source> is not supplied explicitly, it is generated
from C<bucket> and C<source>.

On success, returns the parsed C<CopyObjectResult> response.

On a non-2xx response, records the S3 error and throws an exception.

The HTTP response is available through C<last_response()>.

See
L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_CopyObject.html>.

=head3 delete_key

  my $ok = $bucket->delete_key($key);

  my $ok = $bucket->delete_key($key, $version_id);

Deletes an object.

=over 4

=item key

Required object key.

=item version_id

Optional version ID.

When supplied, the specified object version is deleted.

=back

Returns a true value on success.

=head3 delete_keys

  my $response = $bucket->delete_keys(@keys);

  my $response = $bucket->delete_keys(\@keys);

  my $response = $bucket->delete_keys(\@objects);

  my $response = $bucket->delete_keys($callback);

  my $response = $bucket->delete_keys(
    { keys    => \@objects,
      quiet   => 1,
      headers => \%headers,
    }
  );

Deletes multiple objects using the S3 DeleteObjects API.

The following input forms are supported:

=over 4

=item list of keys

  $bucket->delete_keys(qw(foo bar baz));

=item array reference of keys

  $bucket->delete_keys([qw(foo bar baz)]);

=item array reference of object hashes

Each hash contains C<Key> and may contain C<VersionId>.

  $bucket->delete_keys(
    [ { Key => 'foo', VersionId => '1' },
      { Key => 'bar' },
    ]
  );

=item callback

The callback is repeatedly invoked and should return a key and,
optionally, a version ID.

Iteration ends when the callback returns no key.

  $bucket->delete_keys(
    sub {
      return ( $key, $version_id );
    }
  );

=item configuration hash reference

The hash reference supports:

=over 8

=item headers

Optional request headers.

=item keys

Required key specification in one of the supported forms.

=item quiet

Optional boolean controlling DeleteObjects quiet mode.

The default is false.

=back

=back

A maximum of 1000 objects may be supplied in one call.

The request C<Content-MD5> header is generated automatically.

Returns the response from the DeleteObjects request.

Invalid input or more than 1000 objects causes an exception.

=head3 get_key

  my $object = $bucket->get_key($key);

  my $object = $bucket->get_key(
    $key,
    $method,
    $headers,
    $uri_params,
  );

  my $object = $bucket->get_key(
    { key              => $key,
      method           => 'GET',
      headers          => \%headers,
      uri_params       => \%uri_params,
      verify_checksums => 1,
    }
  );

Retrieves object data and metadata.

The positional and hash-reference forms are both supported.

=over 4

=item headers

Optional hash reference containing request headers.

=item key

Required object key.

=item method

Optional HTTP method.

The default is C<GET>.

C<HEAD> may be used to retrieve metadata without the object body.

=item uri_params

Optional hash reference containing GetObject URI parameters.

Examples include:

  partNumber
  response-cache-control
  response-content-disposition
  response-content-encoding
  response-content-language
  response-content-type
  response-expires
  versionId

=item verify_checksums

Optional per-request override for checksum verification.

When omitted, the value of
L<Amazon::S3/verify_checksums> is used.

This option is available only in the hash-reference form.

=back

When checksum verification is enabled for a C<GET>, the request asks
S3 to return checksum metadata.

On success, returns a hash reference containing:

=over 4

=item checksum_type

The value of C<x-amz-checksum-type>, when returned by S3.

=item checksums

Hash reference containing checksum values returned in
C<x-amz-checksum-*> response headers.

Keys are lowercase algorithm names.

=item content_length

Object content length.

=item content_range

C<Content-Range> header value, when present.

=item content_type

Object content type.

=item etag

ETag returned by S3.

The ETag must not be assumed to be a checksum of the complete object.

=item last_modified

C<Last-Modified> response header.

=item value

Object content.

=item x-amz-meta-*

User metadata headers are also added to the returned hash using
lowercase header names.

=back

Returns C<undef> when the object does not exist.

Other request errors throw an exception.

Supported C<FULL_OBJECT> checksums are verified when verification is
enabled. Partial-content responses and C<COMPOSITE> checksums are not
verified.

A checksum mismatch throws an exception.

See L<Amazon::S3/CHECKSUMS> and
L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetObject.html>.

=head3 get_key_filename

  my $object = $bucket->get_key_filename(
    $key,
    $method,
    $filename,
    $headers,
    $uri_params,
  );

  my $object = $bucket->get_key_filename(
    { key              => $key,
      filename         => $filename,
      method           => 'GET',
      headers          => \%headers,
      uri_params       => \%uri_params,
      verify_checksums => 1,
    }
  );

Retrieves an object and writes the body to a local file.

The accepted parameters and return metadata are the same as for
C<get_key()>, with the addition of:

=over 4

=item filename

Destination filename.

When omitted, the object key is used as the filename.

=back

Checksum verification, when enabled, is performed against the
downloaded file.

Returns C<undef> when the object does not exist.

Other request errors or checksum mismatches throw an exception.

See C<get_key()>.

=head3 get_key_v2

  my $object = $bucket->get_key_v2(
    $key,
    $method,
    $headers,
  );

Compatibility wrapper around the object retrieval implementation.

It accepts an object key, optional HTTP method, and optional headers
hash reference.

For new code, use C<get_key()>.

=head3 head_key

  my $metadata = $bucket->head_key($key);

Retrieves object metadata using an HTTP C<HEAD> request.

This is equivalent to:

  $bucket->get_key($key, 'HEAD');

Returns the same metadata structure as C<get_key()>.

The C<value> entry is empty because no object body is returned.

Returns C<undef> when the object does not exist.

Other request errors throw an exception.

=head2 LISTING METHODS

=head3 list

my $response = $bucket->list;

my $response = $bucket->list(%parameters);

Lists one page of objects in this bucket using the original S3
ListObjects API.

The bucket name is supplied automatically. C<%parameters> may contain
the same listing options accepted by L[Amazon::S3/list_bucket](Amazon::S3/list_bucket),
including:

=over 4

=item delimiter

Optional delimiter used to group keys into common prefixes.

=item headers

Optional hash reference containing additional HTTP request headers.

=item marker

Optional key from which listing should continue.

=item max-keys

Optional maximum number of objects returned by this request.

=item prefix

Optional prefix used to restrict the returned keys.

=back

This method retrieves a single page of results. If S3 indicates that
additional objects are available, the returned structure contains the
marker needed to request the next page.

Use C<list_all()> when all matching objects should be retrieved
automatically.

Returns the same normalized result as L[Amazon::S3/list_bucket](Amazon::S3/list_bucket).

See L<Amazon::S3/LISTING OBJECTS>.

=head3 list_v2

my $response = $bucket->list_v2;

my $response = $bucket->list_v2(%parameters);

Lists one page of objects in this bucket using the S3 ListObjectsV2
API.

The bucket name is supplied automatically. C<%parameters> may contain
the same listing options accepted by L[Amazon::S3/list_bucket_v2](Amazon::S3/list_bucket_v2),
including:

=over 4

=item continuation-token

Optional continuation token returned by a previous ListObjectsV2
request.

=item delimiter

Optional delimiter used to group keys into common prefixes.

=item encoding-type

Optional encoding type requested for returned keys.

=item fetch-owner

Optional value controlling whether owner information is returned.

=item headers

Optional hash reference containing additional HTTP request headers.

=item marker

Compatibility alias for C<continuation-token>.

=item max-keys

Optional maximum number of objects returned by this request.

=item prefix

Optional prefix used to restrict the returned keys.

=item start-after

Optional key after which S3 should begin the listing.

=back

This method retrieves a single page of results. C[Amazon::S3](Amazon::S3) presents
the ListObjectsV2 continuation value through its normalized marker
interface so that callers can paginate consistently with the original
listing API.

Use C<list_all_v2()> when all matching objects should be retrieved
automatically.

Returns the same normalized result as L[Amazon::S3/list_bucket_v2](Amazon::S3/list_bucket_v2).

See L<Amazon::S3/LISTING OBJECTS>.

=head3 list_all

my $response = $bucket->list_all;

my $response = $bucket->list_all(%parameters);

Lists all matching objects in this bucket using the original S3
ListObjects API.

The bucket name is supplied automatically. C<%parameters> may contain
the same listing options accepted by
L[Amazon::S3/list_bucket_all](Amazon::S3/list_bucket_all), including:

=over 4

=item delimiter

Optional delimiter used to group keys into common prefixes.

=item headers

Optional hash reference containing additional HTTP request headers.

=item marker

Optional key from which listing should continue.

=item max-keys

Optional maximum number of objects requested from S3 per request.

Because this method follows pagination automatically, C<max-keys>
limits the size of each request rather than the total number of objects
returned.

=item prefix

Optional prefix used to restrict the returned keys.

=back

Pagination is followed automatically until all matching objects have
been retrieved.

Returns the same normalized result as
L[Amazon::S3/list_bucket_all](Amazon::S3/list_bucket_all).

See L<Amazon::S3/LISTING OBJECTS>.

=head3 list_all_v2

my $response = $bucket->list_all_v2;

my $response = $bucket->list_all_v2(%parameters);

Lists all matching objects in this bucket using the S3 ListObjectsV2
API.

The bucket name is supplied automatically. C<%parameters> may contain
the same listing options accepted by
L[Amazon::S3/list_bucket_all_v2](Amazon::S3/list_bucket_all_v2), including:

=over 4

=item continuation-token

Optional continuation token returned by S3.

=item delimiter

Optional delimiter used to group keys into common prefixes.

=item encoding-type

Optional encoding type requested for returned keys.

=item fetch-owner

Optional value controlling whether owner information is returned.

=item headers

Optional hash reference containing additional HTTP request headers.

=item marker

Compatibility alias for C<continuation-token>.

=item max-keys

Optional maximum number of objects requested from S3 per request.

Because this method follows pagination automatically, C<max-keys>
limits the size of each request rather than the total number of objects
returned.

=item prefix

Optional prefix used to restrict the returned keys.

=item start-after

Optional key after which S3 should begin the listing.

=back

Pagination is followed automatically until all matching objects have
been retrieved.

Returns the same normalized result as
L[Amazon::S3/list_bucket_all_v2](Amazon::S3/list_bucket_all_v2).

See L<Amazon::S3/LISTING OBJECTS>.

=head2 ACCESS CONTROL AND BUCKET METADATA

=head3 delete_bucket

  my $ok = $bucket->delete_bucket;

Deletes this bucket.

This is equivalent to:

  $bucket->account->delete_bucket($bucket);

The bucket must be empty before S3 will delete it.

Returns the value returned by L<Amazon::S3/delete_bucket>.

=head3 get_acl

  my $xml = $bucket->get_acl;

  my $xml = $bucket->get_acl($key);

  my $xml = $bucket->get_acl($key, \%headers);

Retrieves the access control list for the bucket or an object.

=over 4

=item headers

Optional request headers.

=item key

Optional object key.

When omitted, retrieves the ACL for the bucket.

=back

On success, returns the ACL XML document as a scalar.

Returns C<undef> when S3 returns C<404 Not Found>.

Other request errors throw an exception.

=head3 get_location_constraint

  my $location = $bucket->get_location_constraint;

  my $location = $bucket->get_location_constraint(
    { bucket  => $bucket_name,
      headers => \%headers,
      region  => $region,
    }
  );

Returns the S3 location constraint for a bucket.

The optional parameters are:

=over 4

=item bucket

Bucket name.

The default is the current bucket.

=item headers

Optional request headers.

=item region

Region used to sign the request.

The default is the bucket region.

=back

For C<us-east-1>, S3 may return no location constraint.

Callers that require a normalized region name can use
L<Amazon::S3/get_bucket_location>.

See
L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_GetBucketLocation.html>.

=head3 set_acl

  my $ok = $bucket->set_acl(
    { acl_short => 'private',
      key       => $key,
      headers   => \%headers,
    }
  );

  my $ok = $bucket->set_acl(
    { acl_xml => $xml,
      key     => $key,
      headers => \%headers,
    }
  );

Sets the access control list for the bucket or an object.

Exactly one of C<acl_short> or C<acl_xml> is required.

=over 4

=item acl_short

Canned ACL value sent using C<x-amz-acl>.

=item acl_xml

ACL XML document.

=item headers

Request headers.

=item key

Optional object key.

When omitted, sets the ACL for the bucket.

=back

Returns a true value on success.

Invalid ACL configuration throws an exception.

=head2 ERROR AND RESPONSE ACCESSORS

=head3 err

Returns the most recent error code from the associated
L<Amazon::S3> object.

See L<Amazon::S3/ERROR HANDLING>.

=head3 error

Returns the most recent parsed structured error from the associated
L<Amazon::S3> object.

See L<Amazon::S3/ERROR HANDLING>.

=head3 errstr

Returns the most recent human-readable error message from the
associated L<Amazon::S3> object.

See L<Amazon::S3/ERROR HANDLING>.

=head3 last_response

Returns the most recent L<HTTP::Response> from the associated
L<Amazon::S3> object.

See L<Amazon::S3/ERROR HANDLING>.

=head2 MULTIPART UPLOAD METHODS

For normal multipart uploads, C<upload_multipart_object()> is the
preferred interface.

The remaining multipart methods expose the lower-level multipart
lifecycle for callers that need to manage initiation, individual
parts, completion, or abort behavior themselves.

See L<Amazon::S3/MULTIPART UPLOADS>.

=head3 abort_multipart_upload

  my $ok = $bucket->abort_multipart_upload(
    $key,
    $upload_id,
  );

Aborts an existing multipart upload.

=over 4

=item key

Required object key.

=item upload_id

Required multipart upload ID.

=back

Returns a true value on success.

Request errors throw an exception.

=head3 complete_multipart_upload

  my $ok = $bucket->complete_multipart_upload(
    $key,
    $upload_id,
    \%parts,
  );

  my $ok = $bucket->complete_multipart_upload(
    $key,
    $upload_id,
    \%parts,
    $algorithm,
  );

Completes an existing multipart upload.

=over 4

=item algorithm

Optional checksum algorithm associated with the multipart upload.

=item key

Required object key.

=item parts

Required hash reference keyed by part number.

For the historical interface, each value is the ETag returned for the
part:

  {
    1 => $etag_1,
    2 => $etag_2,
  }

When checksum information is needed, each value may instead be a hash
reference:

  {
    1 => {
      etag     => $etag_1,
      checksum => $checksum_1,
    },
  }

=item upload_id

Required multipart upload ID.

=back

Returns a true value on success.

Invalid arguments or request errors throw an exception.

=head3 initiate_multipart_upload

  my $upload_id = $bucket->initiate_multipart_upload(
    $key,
    \%headers,
  );

  my ( $upload_id, $algorithm )
    = $bucket->initiate_multipart_upload(
      $key,
      \%headers,
    );

Initiates a multipart upload.

=over 4

=item headers

Optional request headers.

When C<x-amz-checksum-algorithm> is supplied, the selected algorithm
is carried through the multipart workflow.

For CRC64NVME, CRC32, and CRC32C, C<x-amz-checksum-type> is set to
C<FULL_OBJECT>.

=item key

Required object key.

=back

In scalar context, returns the upload ID assigned by S3.

In list context, returns the upload ID and the lowercase checksum
algorithm selected for the upload.

Invalid arguments, unsupported explicitly requested checksum
algorithms, or request errors throw an exception.

=head3 list_multipart_upload_parts

  my $xml = $bucket->list_multipart_upload_parts(
    $key,
    $upload_id,
    \%headers,
  );

Lists parts already uploaded for an existing multipart upload.

=over 4

=item headers

Optional request headers.

=item key

Required object key.

=item upload_id

Required multipart upload ID.

=back

Returns the XML response body returned by S3.

Request errors throw an exception.

=head3 list_multipart_uploads

  my $xml = $bucket->list_multipart_uploads;

  my $xml = $bucket->list_multipart_uploads(\%headers);

Lists active multipart uploads for this bucket.

The optional argument is a request-headers hash reference.

Returns the XML response body returned by S3.

Request errors throw an exception.

=head3 upload_multipart_object

  my $parts = $bucket->upload_multipart_object(
    { key  => $key,
      data => $data,
    }
  );

Uploads an object using the multipart upload API and manages the
multipart lifecycle.

The method accepts a hash reference or a list of key/value pairs.

Exactly one usable data source must be supplied using C<data>,
C<callback>, or C<fh>.

The following parameters are supported:

=over 4

=item abort_on_error

When true, attempt to abort the multipart upload if an error occurs.

The default is true.

=item callback

Coderef used to provide object data.

The callback receives no arguments and should return:

  ( \$buffer, $length )

Returning no buffer ends the upload.

=item chunk_size

Requested multipart chunk size.

For file-handle uploads, values smaller than the S3 minimum multipart
part size are raised to that minimum.

=item data

Scalar or scalar reference containing object data.

When neither C<callback> nor C<fh> is supplied, the data is read
through an in-memory file handle.

=item fh

Open file handle containing the object data.

The file must be at least the minimum multipart upload size.

=item headers

Optional headers supplied when initiating the multipart upload.

When no C<x-amz-checksum-algorithm> header is supplied, the checksum
algorithm configured on the associated L<Amazon::S3> object is used.

=item key

Required destination object key.

=back

On success, returns a hash reference mapping part numbers to the ETags
returned by S3:

  {
    1 => $etag_1,
    2 => $etag_2,
  }

The method automatically initiates the upload, uploads each part, and
completes the upload.

When C<abort_on_error> is true, an error during the managed workflow
causes an abort attempt and the returned part hash is empty.

See L<Amazon::S3/MULTIPART UPLOADS> and L<Amazon::S3/CHECKSUMS>.

=head3 upload_part_of_multipart_upload

  my $etag = $bucket->upload_part_of_multipart_upload(
    $key,
    $upload_id,
    $part_number,
    $data,
    $length,
    $algorithm,
  );

  my ( $etag, $checksum )
    = $bucket->upload_part_of_multipart_upload(
      { key       => $key,
        id        => $upload_id,
        part      => $part_number,
        data      => $data,
        length    => $length,
        algorithm => $algorithm,
      }
    );

Uploads one part of an existing multipart upload.

The method accepts positional arguments, a hash reference, or an
array reference.

=over 4

=item algorithm

Optional checksum algorithm associated with the multipart upload.

When a local implementation is available, the checksum is calculated
and sent with the UploadPart request.

=item data

Required part data.

A scalar or scalar reference may be supplied.

=item id

Required multipart upload ID.

=item key

Required object key.

=item length

Optional data length.

When omitted, the length is calculated from C<data>.

=item part

Required part number.

=back

In scalar context, returns the ETag returned by S3.

In list context, returns the ETag and the Base64-encoded checksum
calculated for the part, when one was calculated.

Invalid arguments or request errors throw an exception.

=head1 SEE ALSO

L<Amazon::S3>

L<Amazon::S3::BucketV2>

=head1 AUTHOR

Please see L<Amazon::S3> for author, copyright, and license
information.

=head1 CONTRIBUTORS

Rob Lauer

Jojess Fournier

Tim Mullin

Todd Rinaldo

luiserd97

=cut
