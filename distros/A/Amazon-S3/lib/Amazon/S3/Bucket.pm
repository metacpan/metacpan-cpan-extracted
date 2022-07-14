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
use MIME::Base64;
use XML::LibXML;
use URI;

use parent qw{Class::Accessor::Fast};

our $VERSION = '0.54'; ## no critic

__PACKAGE__->mk_accessors(qw{bucket creation_date account buffer_size});

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

  return $self;
} ## end sub new

########################################################################
sub _uri {
########################################################################
  my ( $self, $key ) = @_;

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

  # If we're pushing to a bucket that's under DNS flux, we might get a 307
  # Since LWP doesn't support actually waiting for a 100 Continue response,
  # we'll just send a HEAD first to see what's going on

  if ( ref $value ) {
    return $self->account->_send_request_expect_nothing_probed( 'PUT',
      $self->_uri($key), $conf, $value );
  } ## end if ( ref $value )
  else {
    return $self->account->_send_request_expect_nothing( 'PUT',
      $self->_uri($key), $conf, $value );
  } ## end else [ if ( ref $value ) ]
} ## end sub add_key

########################################################################
sub add_key_filename {
########################################################################
  my ( $self, $key, $value, $conf ) = @_;

  return $self->add_key( $key, \$value, $conf );
} ## end sub add_key_filename

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

  my $request
    = $acct->_make_request( 'POST', $self->_uri($key) . '?uploads=', $conf );
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

  my ( $key, $upload_id, $part_number, $data, $length ) = @args;

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
  my $request
    = $acct->_make_request( 'PUT', $self->_uri($key) . $params, $conf,
    $data );

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

#
# Inform Amazon that the multipart upload has been completed
# You must supply a hash of part Numbers => eTags
# For amazon to use to put the file together on their servers.
#
########################################################################
sub complete_multipart_upload {
########################################################################
  my ( $self, $key, $upload_id, $parts_hr ) = @_;

  croak 'Object key is required'
    if !$key;

  croak 'Upload id is required'
    if !$upload_id;

  croak 'Part number => etag hashref is required'
    if ref $parts_hr ne 'HASH';

  # The complete command requires sending a block of xml containing all
  # the part numbers and their associated etags (returned from the upload)

  #build XML doc
  my $xml_doc      = XML::LibXML::Document->new( '1.0', 'UTF-8' );
  my $root_element = $xml_doc->createElement('CompleteMultipartUpload');
  $xml_doc->addChild($root_element);

  # Add the content
  foreach my $part_num ( sort { $a <=> $b } keys %{$parts_hr} ) {

    # For each part, create a <Part> element with the part number & etag
    my $part = $xml_doc->createElement('Part');
    $part->appendTextChild( 'PartNumber' => $part_num );
    $part->appendTextChild( 'ETag'       => $parts_hr->{$part_num} );
    $root_element->addChild($part);
  } ## end foreach my $part_num ( sort...)

  my $content    = $xml_doc->toString;
  my $md5        = md5($content);
  my $md5_base64 = encode_base64($md5);
  chomp $md5_base64;

  my $conf = {
    'Content-MD5'    => $md5_base64,
    'Content-Length' => length $content,
    'Content-Type'   => 'application/xml'
  };

  my $acct    = $self->account;
  my $params  = "?uploadId=${upload_id}";
  my $request = $acct->_make_request( 'POST', $self->_uri($key) . $params,
    $conf, $content );
  my $response = $acct->_do_http($request);

  $acct->_croak_if_response_error($response);

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

  my $acct    = $self->account;
  my $params  = "?uploadId=${upload_id}";
  my $request = $acct->_make_request( 'DELETE', $self->_uri($key) . $params );
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
  my $request
    = $acct->_make_request( 'GET', $self->_uri($key) . $params, $conf );

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
  my $request
    = $acct->_make_request( 'GET', $self->_uri() . '?uploads', $conf );

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

  my $request = $acct->_make_request( $method, $uri, {} );

  my $response = $acct->_do_http( $request, $filename );

  $acct->get_logger->debug(
    sub {
      return Dumper( [ $request, $response ] );
    }
  );

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

    # Some S3-compatible providers return an all-caps MD5 value in the etag so it should be lc'd for comparison.
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

  return $self->account->_send_request_expect_nothing( 'DELETE',
    $self->_uri($key), {} );
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

  my $request
    = $acct->_make_request( 'GET', $self->_uri($key) . '?acl=', {} );

  my $old_redirectable = $acct->ua->requests_redirectable;
  $acct->ua->requests_redirectable( [] );

  my $response = $acct->_do_http($request);

  if ( $response->code =~ /^30/xsm ) {
    my $xpc = $self->account->_xpc_of_content( $response->content );
    my $uri = URI->new( $response->header('location') );

    my $old_host = $acct->host;
    $acct->host( $uri->host );

    my $request = $acct->_make_request( 'GET', $uri->path, {} );

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

  return $self->account->_send_request_expect_nothing( 'PUT', $path,
    $hash_ref, $xml );
} ## end sub set_acl

########################################################################
sub get_location_constraint {
########################################################################
  my ($self) = @_;

  my $xpc
    = $self->account->_send_request( 'GET', $self->bucket . '/?location=' );

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

Requires a hash containing two arguments:

=over

=item bucket

The name (identifier) of the bucket.

=item account

The L<S3::Amazon> object (representing the S3 account) this
bucket is associated with.

=back

NOTE: This method does not check if a bucket actually
exists. It simply instaniates the bucket.

Typically a developer will not call this method directly,
but work through the interface in L<S3::Amazon> that will
handle their creation.

=head2 add_key

Takes three positional parameters:

=over

=item key

A string identifier for the resource in this bucket

=item value

A SCALAR string representing the contents of the resource.

=item configuration

A HASHREF of configuration data for this key. The configuration
is generally the HTTP headers you want to pass the S3
service. The client library will add all necessary headers.
Adding them to the configuration hash will override what the
library would send and add headers that are not typically
required for S3 interactions.

In addition to additional and overriden HTTP headers, this
HASHREF can have a C<acl_short> key to set the permissions
(access) of the resource without a seperate call via
C<add_acl> or in the form of an XML document.  See the
documentation in C<add_acl> for the values and usage. 

=back

Returns a boolean indicating its success. Check C<err> and
C<errstr> for error message if this operation fails.

=head2 add_key_filename

The method works like C<add_key> except the value is assumed
to be a filename on the local file system. The file will 
be streamed rather then loaded into memory in one big chunk.

=head2 head_key $key_name

Returns a configuration HASH of the given key. If a key does
not exist in the bucket C<undef> will be returned.

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

List all keys in this bucket without having to worry about
'marker'. This may make multiple requests to S3 under the
hood.

See L<Amazon::S3/list_bucket_all_v2> for documentation of this
method.

=head2 abort_multipart_upload

Abort a multipart upload

=head2 complete_multipart_upload

Signal completion of a multipart upload

=head2 initiate_multipart_upload

Initiate a multipart upload

=head2 list_multipart_upload_parts

List all the uploaded parts of a multipart upload

=head2 list_multipart_uploads

List multipart uploads in progress

=head2 upload_part_of_multipart_upload

Upload a portion of a multipart upload

=head2 get_acl

Retrieves the Access Control List (ACL) for the bucket or
resource as an XML document.

=over

=item key

The key of the stored resource to fetch. This parameter is
optional. By default the method returns the ACL for the
bucket itself.

=back

=head2 set_acl $conf

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

Returns the location constraint data on a bucket.

For more information on location constraints, refer to the
Amazon S3 Developer Guide.

=head2 err

The S3 error code for the last error the account encountered.

=head2 errstr

A human readable error string for the last error the account encountered.

=head1 SEE ALSO

L<Amazon::S3>

=head1 AUTHOR

Please see the L<Amazon::S3> manpage for author, copyright, and
license information.

=cut
