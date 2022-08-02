package Amazon::S3::Bucket;

use strict;
use warnings;

use Amazon::S3::Constants qw{:all};

use Carp;
use Data::Dumper;
use Digest::MD5 qw(md5 md5_hex);
use Digest::MD5::File qw(file_md5 file_md5_hex);
use English qw{-no_match_vars};
use File::stat;
use IO::File;
use IO::Scalar;
use MIME::Base64;
use Scalar::Util qw{reftype};
use URI;

use parent qw{Class::Accessor::Fast};

our $VERSION = '0.55'; ## no critic

__PACKAGE__->mk_accessors(
  qw{bucket creation_date account buffer_size region logger verify_region });

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my %options = ref $args[0] ? %{ $args[0] } : @args;
  $options{buffer_size} ||= $DEFAULT_BUFFER_SIZE;

  my $self = $class->SUPER::new( \%options );

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
} ## end sub new

########################################################################
sub _uri {
########################################################################
  my ( $self, $key ) = @_;

  if ($key) {
    $key =~ s/^\///xsm;
  }

  my $uri
    = ($key)
    ? $self->bucket . $SLASH . $self->account->_urlencode($key)
    : $self->bucket . $SLASH;

  if ( $self->account->dns_bucket_names ) {
    $uri =~ s/^\///xsm;
  } ## end if ( $self->account->dns_bucket_names)

  return $uri;
} ## end sub _uri

########################################################################
sub add_key {
########################################################################
  my ( $self, $key, $value, $conf ) = @_;

  croak 'must specify key'
    if !$key || !length $key;

  if ( $conf->{acl_short} ) {
    $self->account->_validate_acl_short( $conf->{acl_short} );

    $conf->{'x-amz-acl'} = $conf->{acl_short};

    delete $conf->{acl_short};
  } ## end if ( $conf->{acl_short...})

  if ( ref $value eq 'SCALAR' ) {
    my $md5_hex = file_md5_hex( ${$value} );
    my $md5     = pack 'H*', $md5_hex;

    my $md5_base64 = encode_base64($md5);
    chomp $md5_base64;

    $conf->{'Content-MD5'} = $md5_base64;

    $conf->{'Content-Length'} ||= -s ${$value};
    $value = _content_sub( ${$value}, $self->buffer_size );

    $conf->{'x-amz-content-sha256'} = 'UNSIGNED-PAYLOAD';
  } ## end if ( ref $value eq 'SCALAR')
  else {
    $conf->{'Content-Length'} ||= length $value;

    my $md5        = md5($value);
    my $md5_hex    = unpack 'H*', $md5;
    my $md5_base64 = encode_base64($md5);

    $conf->{'Content-MD5'} = $md5_base64;
  } ## end else [ if ( ref $value eq 'SCALAR')]

  # If we're pushing to a bucket that's under
  # DNS flux, we might get a 307 Since LWP doesn't support actually
  # waiting for a 100 Continue response, we'll just send a HEAD first
  # to see what's going on
  my $retval = eval {
    return $self->_add_key(
      { headers => $conf,
        data    => $value,
        key     => $key
      }
    );
  };

  # one more try? if someone specified the wrong region, we'll get a
  # 301 and you'll only know the region of redirection - no location
  # header provided...
  if ($EVAL_ERROR) {
    my $rsp = $self->account->last_response;
    if ( $rsp->code eq '301' ) {
      $self->region( $rsp->headers->{'x-amz-bucket-region'} );
    }

    return $self->_add_key(
      { headers => $conf,
        data    => $value,
        key     => $key
      }
    );
  }

} ## end sub add_key

sub _add_key {
  my ( $self, @args ) = @_;

  my ( $data, $headers, $key ) = @{ $args[0] }{qw{data headers key}};

  if ( ref $data ) {
    return $self->account->_send_request_expect_nothing_probed(
      { method  => 'PUT',
        path    => $self->_uri($key),
        headers => $headers,
        data    => $data,
        region  => $self->region,
      }
    );
  } ## end if ( ref $value )
  else {
    return $self->account->_send_request_expect_nothing(
      { method  => 'PUT',
        path    => $self->_uri($key),
        headers => $headers,
        data    => $data,
        region  => $self->region,
      }
    );
  }
} ## end else [ if ( ref $value ) ]
########################################################################
sub add_key_filename {
########################################################################
  my ( $self, $key, $value, $conf ) = @_;

  return $self->add_key( $key, \$value, $conf );
} ## end sub add_key_filename

########################################################################
sub upload_multipart_object {
########################################################################
  my ( $self, @args ) = @_;

  my $logger = $self->logger;

  my %parameters;

  if ( @args == 1 && reftype( $args[0] ) eq 'HASH' ) {
    %parameters = %{ $args[0] };
  }
  else {
    %parameters = @args;
  }

  croak 'no key!'
    if !$parameters{key};

  croak 'either data, callback or fh must be set!'
    if !$parameters{data} && !$parameters{callback} && !$parameters{fh};

  croak 'callback must be a reference to a subroutine!'
    if $parameters{callback} && reftype( $parameters{callback} ) ne 'CODE';

  $parameters{abort_on_error} //= $TRUE;
  $parameters{chunk_size}     //= $MIN_MULTIPART_UPLOAD_CHUNK_SIZE;

  if ( !$parameters{callback} && !$parameters{fh} ) {
    #...but really nobody should be passing a >5MB scalar
    my $data = ref $parameters{data} ? $parameters{data} : \$parameters{data};

    $parameters{fh} = IO::Scalar->new($data);
  }

  # ...having a file handle implies, we use this callback
  if ( $parameters{fh} ) {
    my $fh = $parameters{fh};

    $fh->seek( 0, 2 );

    my $length = $fh->tell;
    $fh->seek( 0, 0 );

    $logger->trace( sub { return sprintf 'length of object: %s', $length; } );

    croak 'length of the object must be >= '
      . $MIN_MULTIPART_UPLOAD_CHUNK_SIZE
      if $length < $MIN_MULTIPART_UPLOAD_CHUNK_SIZE;

    my $chunk_size
      = ( $parameters{chunk_size} && $parameters{chunk_size} )
      > $MIN_MULTIPART_UPLOAD_CHUNK_SIZE
      ? $parameters{chunk_size}
      : $MIN_MULTIPART_UPLOAD_CHUNK_SIZE;

    $parameters{callback} = sub {
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

  my $headers = $parameters{headers} || {};

  my $id = $self->initiate_multipart_upload( $parameters{key}, $headers );

  $logger->trace( sprintf 'multipart id: %s', $id );

  my $part = 1;
  my %parts;
  my $key = $parameters{key};

  eval {
    while (1) {
      my ( $buffer, $length ) = $parameters{callback}->();
      last if !$buffer;

      my $etag = $self->upload_part_of_multipart_upload(
        { id => $id, key => $key, data => $buffer, part => $part } );

      $parts{ $part++ } = $etag;
    }

    $self->complete_multipart_upload( $parameters{key}, $id, \%parts );
  };

  if ( $EVAL_ERROR && $parameters{abort_on_error} ) {
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
  my ( $self, $key, $conf ) = @_;

  croak 'Object key is required'
    if !$key;

  my $acct = $self->account;

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'POST',
      path    => $self->_uri($key) . '?uploads=',
      headers => $conf
    }
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  my $r = $acct->_xpc_of_content( $response->content );

  return $r->{UploadId};
} ## end sub initiate_multipart_upload

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

  my $conf = {};
  my $acct = $self->account;

  # Make sure length and md5 are set
  my $md5        = md5($data);
  my $md5_hex    = unpack 'H*', $md5;
  my $md5_base64 = encode_base64($md5);

  $conf->{'Content-MD5'}    = $md5_base64;
  $conf->{'Content-Length'} = $length;

  my $params = "?partNumber=${part_number}&uploadId=${upload_id}";

  $self->logger->debug( 'uploading ' . sprintf 'part: %s length: %s',
    $part_number, length $data );

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'PUT',
      path    => $self->_uri($key) . $params,
      headers => $conf,
      data    => $data
    }
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  # We'll need to save the etag for later when completing the transaction
  my $etag = $response->header('ETag');

  if ($etag) {
    $etag =~ s/^"//xsm;
    $etag =~ s/"$//xsm;
  } ## end if ($etag)

  return $etag;
} ## end sub upload_part_of_multipart_upload

########################################################################
sub make_xml_document_simple {
########################################################################
  my ($parts_hr) = @_;

  my $xml = q{<?xml version="1.0" encoding="UTF-8"?>};
  my $xml_template
    = '<Part><PartNumber>%s</PartNumber><ETag>%s</ETag></Part>';
  my @parts;

  foreach my $part_num ( sort { $a <=> $b } keys %{$parts_hr} ) {
    push @parts, sprintf $xml_template, $part_num, $parts_hr->{$part_num};
  }

  $xml .= sprintf "\n<CompleteMultipartUpload>%s</CompleteMultipartUpload>\n",
    join q{}, @parts;

  return $xml;
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

  # build XML doc

  my $content = make_xml_document_simple($parts_hr);

  $self->logger->debug("content: \n$content");

  my $md5        = md5($content);
  my $md5_base64 = encode_base64($md5);
  chomp $md5_base64;

  my $conf = {
    'Content-MD5'    => $md5_base64,
    'Content-Length' => length $content,
    'Content-Type'   => 'application/xml'
  };

  my $acct   = $self->account;
  my $params = "?uploadId=${upload_id}";

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'POST',
      path    => $self->_uri($key) . $params,
      headers => $conf,
      data    => $content
    }
  );

  my $response = $acct->_do_http($request);

  if ( $response->code !~ /\A2\d\d\z/xsm ) {
    $acct->_remember_errors( $response->content, 1 );
    croak $response->status_line;
  }

  return $TRUE;
} ## end sub complete_multipart_upload

#
# Stop a multipart upload
#
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
      path   => $self->_uri($key) . $params
    }
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  return $TRUE;
} ## end sub abort_multipart_upload

#
# List all the uploaded parts for an ongoing multipart upload
# It returns the block of XML returned from Amazon
#
########################################################################
sub list_multipart_upload_parts {
########################################################################
  my ( $self, $key, $upload_id, $conf ) = @_;

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
      headers => $conf
    }
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  # Just return the XML, let the caller figure out what to do with it
  return $response->content;
} ## end sub list_multipart_upload_parts

#
# List all the currently active multipart upload operations
# Returns the block of XML returned from Amazon
#
########################################################################
sub list_multipart_uploads {
########################################################################
  my ( $self, $conf ) = @_;

  my $acct = $self->account;

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'GET',
      path    => $self->_uri() . '?uploads',
      headers => $conf
    }
  );

  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

  # Just return the XML, let the caller figure out what to do with it
  return $response->content;
} ## end sub list_multipart_uploads

########################################################################
sub head_key {
########################################################################
  my ( $self, $key ) = @_;

  return $self->get_key( $key, 'HEAD' );
} ## end sub head_key

########################################################################
sub get_key {
########################################################################
  my ( $self, $key, $method, $filename ) = @_;

  $method ||= 'GET';

  if ( ref $filename ) {
    $filename = ${$filename};
  } ## end if ( ref $filename )

  my $acct = $self->account;

  my $uri = $self->_uri($key);

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => $method,
      path    => $uri,
      headers => {}
    }
  );

  my $response = $acct->_do_http( $request, $filename );

  return if $response->code == 404;

  $acct->_croak_if_response_error($response);

  my $etag = $response->header('ETag');

  if ($etag) {
    $etag =~ s/^"//xsm;
    $etag =~ s/"$//xsm;
  } ## end if ($etag)

  my $return = {
    content_length => $response->content_length || 0,
    content_type   => $response->content_type,
    etag           => $etag,
    value          => $response->content,
  };

  # Validate against data corruption by verifying the MD5
  if ( $method eq 'GET' ) {
    my $md5
      = ( $filename and -f $filename )
      ? file_md5_hex($filename)
      : md5_hex( $return->{value} );

    # Some S3-compatible providers return an all-caps MD5 value in the
    # etag so it should be lc'd for comparison.
    croak "Computed and Response MD5's do not match:  $md5 : $etag"
      if $md5 ne lc $etag;
  } ## end if ( $method eq 'GET' )

  foreach my $header ( $response->headers->header_field_names ) {
    next if $header !~ /x-amz-meta-/ixsm;
    $return->{ lc $header } = $response->header($header);
  } ## end foreach my $header ( $response...)

  return $return;
} ## end sub get_key

########################################################################
sub get_key_filename {
########################################################################
  my ( $self, $key, $method, $filename ) = @_;

  if ( !defined $filename ) {
    $filename = $key;
  } ## end if ( !defined $filename)

  return $self->get_key( $key, $method, \$filename );
} ## end sub get_key_filename

# returns bool
########################################################################
sub delete_key {
########################################################################
  my ( $self, $key ) = @_;

  croak 'must specify key'
    if !$key && length $key;

  return $self->account->_send_request_expect_nothing(
    { method  => 'DELETE',
      region  => $self->region,
      path    => $self->_uri($key),
      headers => {}
    }
  );
} ## end sub delete_key

########################################################################
sub delete_bucket {
########################################################################
  my ($self) = @_;

  croak 'Unexpected arguments'
    if @_ > 1;

  return $self->account->delete_bucket($self);
} ## end sub delete_bucket

########################################################################
sub list_v2 {
########################################################################
  my ( $self, $conf ) = @_;

  $conf ||= {};

  $conf->{bucket}      = $self->bucket;
  $conf->{'list-type'} = '2';

  if ( $conf->{'marker'} ) {
    $conf->{'continuation-token'} = delete $conf->{'marker'};
  } ## end if ( $conf->{'marker'})

  return $self->list($conf);
} ## end sub list_v2

########################################################################
sub list {
########################################################################
  my ( $self, $conf ) = @_;

  $conf ||= {};

  $conf->{bucket} = $self->bucket;

  return $self->account->list_bucket($conf);
} ## end sub list

########################################################################
sub list_all_v2 {
########################################################################
  my ( $self, $conf ) = @_;

  $conf ||= {};

  $conf->{bucket} = $self->bucket;

  return $self->account->list_bucket_all_v2($conf);
} ## end sub list_all_v2

########################################################################
sub list_all {
########################################################################
  my ( $self, $conf ) = @_;

  $conf ||= {};

  $conf->{bucket} = $self->bucket;

  return $self->account->list_bucket_all($conf);
} ## end sub list_all

########################################################################
sub get_acl {
########################################################################
  my ( $self, $key ) = @_;

  my $acct = $self->account;

  my $request = $acct->_make_request(
    { region  => $self->region,
      method  => 'GET',
      path    => $self->_uri($key) . '?acl=',
      headers => {}
    }
  );

  my $old_redirectable = $acct->ua->requests_redirectable;
  $acct->ua->requests_redirectable( [] );

  my $response = $acct->_do_http($request);

  if ( $response->code =~ /^30/xsm ) {
    my $xpc = $self->account->_xpc_of_content( $response->content );
    my $uri = URI->new( $response->header('location') );

    my $old_host = $acct->host;
    $acct->host( $uri->host );

    my $request = $acct->_make_request(
      { region  => $self->region,
        method  => 'GET',
        path    => $uri->path,
        headers => {}
      }
    );

    $response = $acct->_do_http($request);

    $acct->ua->requests_redirectable($old_redirectable);
    $acct->host($old_host);
  } ## end if ( $response->code =~...)

  return if $response->code == 404;

  $acct->_croak_if_response_error($response);

  return $response->content;
} ## end sub get_acl

########################################################################
sub set_acl {
########################################################################
  my ( $self, $conf ) = @_;

  $conf ||= {};

  croak 'need either acl_xml or acl_short'
    if !$conf->{acl_xml} && !$conf->{acl_short};

  croak 'cannot provide both acl_xml and acl_short'
    if $conf->{acl_xml} && $conf->{acl_short};

  my $path = $self->_uri( $conf->{key} ) . '?acl=';

  my $hash_ref
    = ( $conf->{acl_short} )
    ? { 'x-amz-acl' => $conf->{acl_short} }
    : {};

  my $xml = $conf->{acl_xml} || $EMPTY;

  return $self->account->_send_request_expect_nothing(
    { method  => 'PUT',
      path    => $path,
      headers => $hash_ref,
      data    => $xml,
      region  => $self->region
    }
  );
} ## end sub set_acl

########################################################################
sub get_location_constraint {
########################################################################
  my ($self) = @_;

  my $xpc = $self->account->_send_request(
    { region => $self->region,
      method => 'GET',
      path   => $self->bucket . '/?location='
    }
  );

  if ( !$xpc ) {
    $self->account->_remember_errors($xpc);

    return;
  } ## end if ( !$xpc )

  my $lc = $xpc->{content};

  if ( defined $lc && $lc eq $EMPTY ) {
    $lc = undef;
  } ## end if ( defined $lc && $lc...)

  return $lc;
} ## end sub get_location_constraint

# proxy up the err requests

########################################################################
sub last_response {
########################################################################
  my ($self) = @_;

  return $self->account->last_reponse;
}

########################################################################
sub err {
########################################################################
  my ($self) = @_;

  return $self->account->err;
} ## end sub err

########################################################################
sub errstr {
########################################################################
  my ($self) = @_;

  return $self->account->errstr;
} ## end sub errstr

########################################################################
sub error {
########################################################################
  my ($self) = @_;

  return $self->account->error;
} ## end sub err

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
    } ## end if ( !$fh->opened )

    my $read = $fh->read( $buffer, $blksize );

    if ( !$read ) {
      croak
        "Error while reading upload content $filename ($remaining remaining) $OS_ERROR"
        if $OS_ERROR and $remaining;

      $fh->close # otherwise, we found EOF
        or croak "close of upload content $filename failed: $OS_ERROR";

      $buffer ||= $EMPTY; # LWP expects an empty string on finish, read returns 0
    } ## end if ( !$read )

    $remaining -= length $buffer;

    return $buffer;
  };
} ## end sub _content_sub

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

Sets the logger object (should be an object capable of providing at
least a C<debug> and C<trace> method for recording log messages. If no
logger object is passed the C<account> object's logger object will be used.

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

A SCALAR string representing the contents of the object..

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

=head2 get_key $key_name, [$method]

Takes a key and an optional HTTP method and fetches it from
S3. The default HTTP method is GET.

The method returns C<undef> if the key does not exist in the
bucket and throws an exception (dies) on server errors.

On success, the method returns a HASHREF containing:

=over

=item content_type

=item etag

=item value

=item @meta

=back

=head2 get_key_filename $key_name, $method, $filename

This method works like C<get_key>, but takes an added
filename that the S3 resource will be written to.

=head2 delete_key $key_name

Permanently removes C<$key_name> from the bucket. Returns a
boolean value indicating the operations success.

=head2 delete_bucket

Permanently removes the bucket from the server. A bucket
cannot be removed if it contains any keys (contents).

This is an alias for C<$s3->delete_bucket($bucket)>.

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

Retrieves the Access Control List (ACL) for the bucket or
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
bucket.

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

=cut
