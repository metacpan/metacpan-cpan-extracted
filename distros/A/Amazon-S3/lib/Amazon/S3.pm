package Amazon::S3;

use strict;
use warnings;

use Amazon::S3::Bucket;
use Amazon::S3::BucketV2;
use Amazon::S3::Constants qw(:all);

use Amazon::S3::Util qw(
  set_md5_header
  urlencode
  get_parameters
  create_xml_request
  create_api_uri
  create_query_string
);

use Amazon::S3::Logger;
use Amazon::S3::Signature::V4;

use Carp;
use Data::Dumper;
use Digest::HMAC_SHA1;
use Digest::MD5 qw(md5_hex);
use English qw(-no_match_vars);
use HTTP::Date;
use LWP::UserAgent::Determined;
use List::Util qw( any pairs none );
use MIME::Base64 qw(encode_base64 decode_base64);
use Module::Load;
use Scalar::Util qw( reftype blessed );
use URI;
use XML::Simple;

use parent qw(Class::Accessor::Fast Exporter);

__PACKAGE__->mk_accessors(
  qw(
    aws_access_key_id
    aws_secret_access_key
    token
    buffer_size
    cache_signer
    checksum_types
    checksum_algorithm
    credentials
    dns_bucket_names
    digest
    err
    errstr
    error
    express
    host
    last_request
    last_response
    logger
    log_level
    raise_error
    retry
    _region
    secure
    _signer
    timeout
    ua
    verify_checksums
  ),
);

our $VERSION = '2.1.0'; ## no critic (RequireInterpolation)

our @EXPORT_OK = qw(is_domain_bucket);

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my %options = ref $args[0] ? %{ $args[0] } : @args;

  $options{timeout}            //= $DEFAULT_TIMEOUT;
  $options{cache_signer}       //= $FALSE;
  $options{retry}              //= $FALSE;
  $options{express}            //= $FALSE;
  $options{verify_checksums}   //= $TRUE;
  $options{checksum_algorithm} //= 'crc64nvme';
  $options{raise_error}        //= $FALSE;

  if ( my $endpoint_url = delete $options{endpoint_url} ) {
    croak "ERROR: use endpoint_url or host but not both\n"
      if $options{host};

    croak "ERROR: use endpoint_url or secure but not both\n"
      if defined $options{secure};

    my $uri    = URI->new($endpoint_url);
    my $scheme = $uri->scheme;

    croak "ERROR: endpoint_url must include a host\n"
      if !defined $uri->host || !length $uri->host;

    croak "ERROR: endpoint_url must use http or https\n"
      if !defined $scheme || ( $scheme ne 'http' && $scheme ne 'https' );

    croak "ERROR: endpoint_url must not contain a query or fragment\n"
      if defined $uri->query || defined $uri->fragment;

    croak "ERROR: endpoint_url must not contain a path\n"
      if $uri->path && $uri->path ne $SLASH;

    $options{secure} = $scheme eq 'https' ? $TRUE : $FALSE;
    $options{host}   = $uri->host_port;
  }

  $options{secure}           //= $TRUE;
  $options{host}             //= $DEFAULT_HOST;
  $options{dns_bucket_names} //= $TRUE;

  croak sprintf "ERROR: invalid checksum_algorithm: '%s'\nMust be one of: %s\n", $options{checksum_algorithm}, join q{,},
    @AWS_CHECKSUM_TYPES
    if none { $options{checksum_algorithm} eq $_ } @AWS_CHECKSUM_TYPES;

  $options{_region} = delete $options{region};
  $options{_signer} = delete $options{signer};

  # convenience for level => 'debug' & for consistency with
  # Amazon::Credentials only do this if we are using internal logger,
  # call should NOT use debug flag but rather use their own logger's
  # level to turn on higher levels of logging...

  if ( !$options{logger} ) {
    if ( delete $options{debug} ) {
      $options{level} = 'debug';
    }

    $options{log_level} = delete $options{level};
    $options{log_level} //= $DEFAULT_LOG_LEVEL;

    $options{logger}
      = Amazon::S3::Logger->new( log_level => $options{log_level} );
  }

  my $self = $class->SUPER::new( \%options );

  # setup logger internal logging

  $self->get_logger->debug(
    sub {
      my %safe_options = %options;

      if ( $safe_options{aws_secret_access_key} ) {
        $safe_options{aws_secret_access_key} = '****';
        $safe_options{aws_access_key_id}     = '****';
      }

      return Dumper( [ options => \%safe_options ] );
    },
  );

  if ( !$self->credentials ) {

    croak 'No aws_access_key_id'
      if !$self->aws_access_key_id;

    croak 'No aws_secret_access_key'
      if !$self->aws_secret_access_key;

    # encrypt credentials
    $self->aws_access_key_id( _encrypt( $self->aws_access_key_id ) );
    $self->aws_secret_access_key( _encrypt( $self->aws_secret_access_key ) );
    $self->token( _encrypt( $self->token ) );
  }

  my $ua;

  if ( $self->retry ) {
    $ua = LWP::UserAgent::Determined->new(
      keep_alive            => $KEEP_ALIVE_CACHESIZE,
      requests_redirectable => [qw(GET HEAD DELETE)],
    );

    $ua->timing( join $COMMA, map { 2**$_ } 0 .. $MAX_RETRIES );
  }
  else {
    $ua = LWP::UserAgent->new(
      keep_alive            => $KEEP_ALIVE_CACHESIZE,
      requests_redirectable => [qw(GET HEAD DELETE)],
    );
  }

  $ua->timeout( $self->timeout );
  $ua->env_proxy;
  $self->ua($ua);

  $self->region( $self->_region // $DEFAULT_REGION );

  if ( !$self->_signer && $self->cache_signer ) {
    $self->_signer( $self->signer );
  }

  if ( $self->express ) {
    $self->use_express_one_zone();
  }

  $self->turn_on_special_retry();

  $self->_init_checksum_types;

  return $self;
}

########################################################################
sub _init_checksum_types {
########################################################################
  my ($self) = @_;

  my %checksum_types;
  $self->checksum_types( \%checksum_types );

  foreach my $algorithm (@AWS_CHECKSUM_TYPES) {
    next
      if !exists $CHECKSUM_TYPES{$algorithm};

    my $checksum_type = $CHECKSUM_TYPES{$algorithm};
    my $module        = $checksum_type->{module};

    my $loaded = eval {
      load $module;
      return $TRUE;
    };

    next
      if !$loaded;

    # since our module has already been loaded we only need the code
    # ref to the implementation
    $checksum_types{$algorithm} = $checksum_type->{digest};
  }

  return $self;
}

########################################################################
sub use_express_one_zone {
########################################################################
  my ($self) = @_;

  my $express = $self->express;

  $self->express($TRUE);

  $self->host( sprintf 's3express-control.%s.amazonaws.com', $self->region );
  $self->secure($TRUE);
  $self->dns_bucket_names($FALSE);

  return $express;
}

########################################################################
{
  my $encryption_key;

########################################################################
  sub _encrypt {
########################################################################
    my ($text) = @_;

    return $text if !$text;

    if ( !defined $encryption_key ) {
      $encryption_key = eval {
        if ( !defined $encryption_key ) {
          require Crypt::Blowfish;
          require Crypt::CBC;

          return md5_hex( rand $PID );
        }
      };

      return $text if $EVAL_ERROR;
    }

    return $text if !$encryption_key;

    my $cipher = Crypt::CBC->new(
      -pass        => $encryption_key,
      -key         => $encryption_key,
      -cipher      => 'Crypt::Blowfish',
      -nodeprecate => $TRUE,
    );

    return $cipher->encrypt($text);
  }

########################################################################
  sub _decrypt {
########################################################################
    my ($secret) = @_;

    return $secret
      if !$secret || !$encryption_key;

    my $cipher = Crypt::CBC->new(
      -pass   => $encryption_key,
      -key    => $encryption_key,
      -cipher => 'Crypt::Blowfish',
    );

    return $cipher->decrypt($secret);
  }

}

########################################################################
sub get_bucket_location {
########################################################################
  my ( $self, $bucket ) = @_;

  my $region;

  if ( !ref $bucket || ref $bucket !~ /Amazon::S3::Bucket/xsm ) {
    $bucket = Amazon::S3::Bucket->new( bucket => $bucket, account => $self );
  }

  return $bucket->get_location_constraint // $DEFAULT_REGION;
}

########################################################################
sub get_default_region {
########################################################################
  my ($self) = @_;

  my $region = $ENV{AWS_REGION} || $ENV{AWS_DEFAULT_REGION};

  return $region
    if $region;

  my $url = $AWS_METADATA_BASE_URL . 'placement/availability-zone';

  my $request = HTTP::Request->new( 'GET', $url );

  my $ua = LWP::UserAgent->new;
  $ua->timeout(0);

  my $response = eval { return $ua->request($request); };

  if ( $response && $response->is_success ) {
    if ( $response->content =~ /\A([[:lower:]]+[-][[:lower:]]+[-]\d+)/xsm ) {
      $region = $1;
    }
  }

  return $region || $DEFAULT_REGION;
}

# Amazon::Credentials compatibility methods
########################################################################
sub get_aws_access_key_id {
########################################################################
  my ($self) = @_;

  return _decrypt( $self->aws_access_key_id );
}

########################################################################
sub get_aws_secret_access_key {
########################################################################
  my ($self) = @_;

  return _decrypt( $self->aws_secret_access_key );
}

########################################################################
sub get_token {
########################################################################
  my ($self) = @_;

  return _decrypt( $self->token );
}

########################################################################
sub turn_on_special_retry {
########################################################################
  my ($self) = @_;

  return
    if !$self->retry;

  # In the field we are seeing issue of Amazon returning with a 400
  # code in the case of timeout.  From AWS S3 logs: REST.PUT.PART
  # Backups/2017-05-04/<account>.tar.gz "PUT
  # /Backups<path>?partNumber=27&uploadId=<id> - HTTP/1.1" 400
  # RequestTimeout 360 20971520 20478 - "-" "libwww-perl/6.15"
  my $http_codes_hr = $self->ua->codes_to_determinate();
  $http_codes_hr->{$HTTP_BAD_REQUEST} = $TRUE;

  return;
}

########################################################################
sub turn_off_special_retry {
########################################################################
  my ($self) = @_;

  return
    if !$self->retry;

  # In the field we are seeing issue with Amazon returning a 400
  # code in the case of timeout.  From AWS S3 logs: REST.PUT.PART
  # Backups/2017-05-04/<account>.tar.gz "PUT
  # /Backups<path>?partNumber=27&uploadId=<id> - HTTP/1.1" 400
  # RequestTimeout 360 20971520 20478 - "-" "libwww-perl/6.15"
  my $http_codes_hr = $self->ua->codes_to_determinate();
  delete $http_codes_hr->{$HTTP_BAD_REQUEST};

  return;
}

########################################################################
sub region {
########################################################################
  my ( $self, @args ) = @_;

  if (@args) {
    $self->_region( $args[0] );
  }

  $self->get_logger->debug( sub { return 'region: ' . ( $self->_region // $EMPTY ) } );

  if ( $self->_region ) {
    my $host = $self->host;
    $self->get_logger->debug( sub { return 'host: ' . $self->host } );

    if ( $host =~ /\As3[.](.*)?amazonaws/xsm ) {
      $self->host( sprintf 's3.%s.amazonaws.com', $self->_region );
    }
  }

  return $self->_region;
}

########################################################################
sub buckets {
########################################################################
  my ( $self, $verify_region ) = @_;

  # The "default" region for Amazon is us-east-1
  # This is the region to set it to for listing buckets
  # You may need to reset the signer's endpoint to 'us-east-1'

  # temporarily cache signer
  my $region = $self->_region;
  my $bucket_list;

  $self->reset_signer_region($DEFAULT_REGION);  # default region for buckets op

  my $r = $self->send_request(
    { method  => 'GET',
      path    => $EMPTY,
      headers => {},
      region  => $DEFAULT_REGION,
    },
  );

  return $bucket_list
    if !$r || $self->errstr;

  my $owner_id          = $r->{Owner}{ID};
  my $owner_displayname = $r->{Owner}{DisplayName};

  my @buckets;

  if ( ref $r->{Buckets} ) {
    my $buckets = $r->{Buckets}{Bucket};

    if ( !ref $buckets || reftype($buckets) ne 'ARRAY' ) {
      $buckets = [$buckets];
    }

    foreach my $node ( @{$buckets} ) {
      push @buckets,
        Amazon::S3::Bucket->new(
        { bucket        => $node->{Name},
          creation_date => $node->{CreationDate},
          account       => $self,
          buffer_size   => $self->buffer_size,
          verify_region => $verify_region // $FALSE,
        },
        );

    }
  }

  $self->reset_signer_region($region);  # restore original region

  $bucket_list = {
    owner_id          => $owner_id,
    owner_displayname => $owner_displayname,
    buckets           => \@buckets,
  };

  return $bucket_list;
}

########################################################################
sub reset_signer_region {
########################################################################
  my ( $self, $region ) = @_;

  # reset signer's region, if the region wasn't us-east-1...note this
  # is probably not needed anymore since bucket operations now send
  # the region of the bucket to the signer
  if ( $self->cache_signer ) {
    if ( $self->region && $self->region ne $DEFAULT_REGION ) {
      if ( $self->signer->can('region') ) {
        $self->signer->region($region);
      }
    }
  }
  else {
    $self->region($region);
  }

  return $self->region;
}

########################################################################
sub add_bucket {
########################################################################
  my ( $self, $conf ) = @_;

  my $bucket = $conf->{bucket};

  croak 'must specify bucket'
    if !$bucket;

  my $headers = $conf->{headers} // {};

  if ( $conf->{acl_short} ) {
    $self->_validate_acl_short( $conf->{acl_short} );

    $headers->{'x-amz-acl'}              //= $conf->{acl_short};
    $headers->{'x-amz-object-ownership'} //= 'ObjectWriter';
  }

  my $region = $conf->{location_constraint} // $conf->{region};

  $region //= $self->region;

  if ( $region && $region eq $DEFAULT_REGION ) {
    undef $region;
  }

  return $self->_add_bucket(
    { headers           => $headers,
      bucket            => $conf->{bucket},
      region            => $region,
      availability_zone => $conf->{availability_zone},
    }
  );
}

########################################################################
sub _add_bucket {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $bucket, $headers, $region, $availability_zone )
    = @{$parameters}{qw(bucket headers region availability_zone)};

  $region  //= $EMPTY;
  $headers //= {};

  my $request = { CreateBucketConfiguration => { LocationConstraint => $region, } };

  if ($availability_zone) {
    $request->{CreateBucketConfiguration}->{Location} = {
      Name => $availability_zone,
      Type => 'AvailabilityZone',
    };

    $request->{CreateBucketConfiguration}->{Bucket} = {
      DataRedundancy => 'SingleAvailabilityZone',
      Type           => 'Directory',
    };

    delete $request->{CreateBucketConfiguration}->{LocationConstraint};
  }

  $self->dns_bucket_names(0);

  my $data
    = ( $region || $availability_zone )
    ? create_xml_request($request)
    : $EMPTY;

  $headers->{'Content-Length'} = length $data;

  my $retval = $self->send_request_expect_nothing(
    { method  => 'PUT',
      path    => "$bucket/",
      headers => $headers,
      data    => $data,
      region  => $region,
    },
  );

  my $bucket_obj = $retval ? $self->bucket($bucket) : undef;

  return $bucket_obj;
}

########################################################################
sub bucket {
########################################################################
  my ( $self, @args ) = @_;

  my ( $bucketname, $region, $verify_region );

  if ( ref $args[0] && reftype( $args[0] ) eq 'HASH' ) {
    ( $bucketname, $region, $verify_region )
      = @{ $args[0] }{qw(bucket region verify_region)};
  }
  else {
    ( $bucketname, $region ) = @args;
  }

  # only set to default region if a region wasn't passed or region
  # verification not requested
  if ( !$region && !$verify_region ) {
    $region = $self->region;
  }

  return Amazon::S3::Bucket->new(
    { bucket        => $bucketname,
      account       => $self,
      region        => $region,
      verify_region => $verify_region,
    },
  );
}

########################################################################
sub delete_bucket {
########################################################################
  my ( $self, $conf ) = @_;

  my $bucket;
  my $region;
  my $headers;

  if ( eval { return $conf->isa('Amazon::S3::Bucket'); } ) {
    $bucket = $conf->bucket;
    $region = $conf->region;
  }
  else {
    $bucket  = $conf->{bucket};
    $region  = $conf->{region} || $self->get_bucket_location($bucket);
    $headers = $conf->{headers};
  }

  croak 'must specify bucket'
    if !$bucket;

  return $self->send_request_expect_nothing(
    { method  => 'DELETE',
      path    => $bucket . $SLASH,
      headers => $headers // {},
      region  => $region,
    },
  );
}

########################################################################
sub list_directory_buckets {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my $express = $self->use_express_one_zone;

  my $result = $self->send_request(
    { method     => 'GET',
      headers    => {},
      path       => $SLASH,
      uri_params => $parameters->{uri_params} // {},
      region     => $self->region,
    }
  );

  $self->express($express);

  return $result;
}

########################################################################
sub list_bucket_v2 {
########################################################################
  my ( $self, $conf ) = @_;

  $conf->{'list-type'} = '2';

  goto &list_bucket;
}

########################################################################
sub list_bucket {
########################################################################
  my ( $self, $conf ) = @_;

  my $bucket = delete $conf->{bucket};

  croak 'must specify bucket'
    if !$bucket;

  $conf //= {};

  my $bucket_list;  # return this
  my $path = $bucket . $SLASH;

  my $headers = delete $conf->{headers};

  my $list_type = $conf->{'list-type'} // '1';

  my ( $marker, $next_marker, $query_next )
    = @{ $LIST_OBJECT_MARKERS{$list_type} };

  if ( $conf->{marker} ) {
    $conf->{$query_next} = delete $conf->{marker};
  }

  if ( %{$conf} ) {

    my @vars = keys %{$conf};

    # remove undefined elements
    foreach (@vars) {
      next if defined $conf->{$_};

      delete $conf->{$_};
    }

    my $query_string = $QUESTION_MARK . join $AMPERSAND, map { $_ . $EQUAL_SIGN . urlencode( $conf->{$_} ) }
      keys %{$conf};

    $path .= $query_string;
  }

  $self->get_logger->debug( sprintf 'PATH: %s', $path );

  my $r = $self->send_request(
    { method  => 'GET',
      path    => $path,
      headers => $headers // {},  # { 'Content-Length' => 0 },
      region  => $self->region,
    },
  );

  $self->get_logger->trace(
    Dumper(
      [ r      => $r,
        errstr => $self->errstr,
      ]
    )
  );

  return $bucket_list
    if !$r || $self->errstr;

  $self->get_logger->trace(
    sub {
      return Dumper(
        [ marker      => $marker,
          next_marker => $next_marker,
          response    => $r,
        ],
      );
    },
  );

  $bucket_list = {
    bucket       => $r->{Name},
    prefix       => $r->{Prefix}       // $EMPTY,
    marker       => $r->{$marker}      // $EMPTY,
    next_marker  => $r->{$next_marker} // $EMPTY,
    max_keys     => $r->{MaxKeys},
    is_truncated => (
      ( defined $r->{IsTruncated} && scalar $r->{IsTruncated} eq 'true' )
      ? $TRUE
      : $FALSE
    ),
  };

  my @keys;

  foreach my $node ( @{ $r->{Contents} } ) {
    my $etag = $node->{ETag};

    if ( defined $etag ) {
      $etag =~ s{(^"|"$)}{}gxsm;
    }

    push @keys,
      {
      key               => $node->{Key},
      last_modified     => $node->{LastModified},
      etag              => $etag,
      size              => $node->{Size},
      storage_class     => $node->{StorageClass},
      owner_id          => $node->{Owner}{ID},
      owner_displayname => $node->{Owner}{DisplayName},
      };
  }

  $bucket_list->{keys} = \@keys;

  if ( $conf->{delimiter} ) {
    my @common_prefixes;
    my $strip_delim = qr/$conf->{delimiter}$/xsm;

    foreach my $node ( $r->{CommonPrefixes} ) {
      if ( ref $node ne 'ARRAY' ) {
        $node = [$node];
      }

      foreach my $n ( @{$node} ) {
        next if !exists $n->{Prefix};
        my $prefix = $n->{Prefix};

        # strip delimiter from end of prefix
        if ($prefix) {
          $prefix =~ s/$strip_delim//xsm;
        }

        push @common_prefixes, $prefix;
      }
    }

    $bucket_list->{common_prefixes} = \@common_prefixes;
  }

  $self->get_logger->trace( Dumper( [ bucket_list => $bucket_list ] ) );

  return $bucket_list;
}
########################################################################
sub list_bucket_all_v2 {
########################################################################
  my ( $self, $conf ) = @_;
  $conf ||= {};

  $conf->{'list-type'} = '2';

  return $self->list_bucket_all($conf);
}

########################################################################
sub list_bucket_all {
########################################################################
  my ( $self, $conf ) = @_;
  $conf ||= {};

  my $bucket = $conf->{bucket};

  croak 'must specify bucket'
    if !$bucket;

  my $response = $self->list_bucket($conf);

  croak $EVAL_ERROR
    if !$response;

  return $response
    if !$response->{is_truncated};

  my $all = $response;

  while ($TRUE) {
    my $next_marker = $response->{next_marker}
      || $response->{keys}->[-1]->{key};

    $conf->{marker} = $next_marker;
    $conf->{bucket} = $bucket;

    $response = $self->list_bucket($conf);

    croak $EVAL_ERROR
      if !$response;

    push @{ $all->{keys} }, @{ $response->{keys} };

    last if !$response->{is_truncated};
  }

  delete $all->{is_truncated};
  delete $all->{next_marker};

  return $all;
}

########################################################################
# API: ListObjectVersions
#########################################################################
# Documentation:
#  https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectVersions.html
#
# Request:
#  GET /?versions
#  HOST: Bucket.s3.amazonaws.com
#  x-amz-expected-bucket-owner: ExpectedBucketOwner
#  x-amz-request-payer: RequestPayer
#  x-amz-optional-object-attributes: OptionalObjectAtttributes
#
# Parameters:
#   delimiter         => Delimiter
#   encoding-type     => EncodingType
#   key-marker        => KeyMarker
#   max-keys          => MaxKeys
#   prefix            => Prefix
#   version-id-marker => VersionIdMarker
#
# Response

########################################################################
sub list_object_versions {
########################################################################
  my ( $self, $conf ) = @_;

  my $bucket = delete $conf->{bucket};

  die 'no bucket'
    if !$bucket;

  my $headers = delete $conf->{headers};

  croak 'must specify bucket'
    if !$bucket;

  $conf ||= {};

  my ( $marker, $next_marker, $query_next )
    = @{ $LIST_OBJECT_MARKERS{'3'} };

  if ( $conf->{'key-marker'} ) {
    $conf->{$query_next} = delete $conf->{'key-marker'};
  }

  if ( %{$conf} ) {

    # remove undefined elements
    foreach ( keys %{$conf} ) {
      next if defined $conf->{$_};

      delete $conf->{$_};
    }
  }

  my $path = create_api_uri( path => "$bucket/", api => 'versions', %{$conf} );

  my $r = $self->send_request(
    { method  => 'GET',
      path    => $path,
      headers => $headers // {},
      region  => $self->region,
    },
  );

  return
    if !$r || $self->errstr;

  $self->get_logger->debug(
    sub {
      return Dumper(
        [ marker      => $marker,
          next_marker => $next_marker,
          response    => $r,
        ],
      );
    },
  );

  return $r;
}

########################################################################
sub get_credentials {
########################################################################
  my ($self) = @_;

  my $aws_access_key_id;
  my $aws_secret_access_key;
  my $token;

  if ( $self->credentials ) {
    $aws_access_key_id     = $self->credentials->get_aws_access_key_id;
    $aws_secret_access_key = $self->credentials->get_aws_secret_access_key;
    $token                 = $self->credentials->get_token;
  }
  else {
    $aws_access_key_id     = $self->aws_access_key_id;
    $aws_secret_access_key = $self->aws_secret_access_key;
    $token                 = $self->token;
  }

  return ( $aws_access_key_id, $aws_secret_access_key, $token );
}

# Log::Log4perl compatibility routines
########################################################################
sub get_logger {
########################################################################
  my ($self) = @_;

  return $self->logger;
}

########################################################################
sub level {
########################################################################
  my ( $self, @args ) = @_;

  if (@args) {
    $self->log_level( $args[0] );

    $self->get_logger->level( uc $args[0] );
  }

  return $self->get_logger->level;
}

########################################################################
sub signer {
########################################################################
  my ($self) = @_;

  return $self->_signer
    if $self->_signer;

  my $creds   = $self->credentials ? $self->credentials : $self;
  my $express = $self->express;

  my $signer = Amazon::S3::Signature::V4->new(
    { access_key_id  => $creds->get_aws_access_key_id,
      secret         => $creds->get_aws_secret_access_key,
      region         => $self->region || $self->get_default_region,
      service        => $express ? 's3express' : 's3',
      security_token => $creds->get_token,
    },
  );

  if ( $self->cache_signer ) {
    $self->_signer($signer);
  }

  return $signer;
}

########################################################################
sub _validate_acl_short {
########################################################################
  my ( $self, $policy_name ) = @_;

  croak sprintf '%s is not a supported canned access policy', $policy_name
    if none { $policy_name eq $_ } qw(private public-read public-read-write authenticated-read);

  return;
}

########################################################################
# Determine if a bucket can used as subdomain for the host
# Specifying the bucket in the URL path is being deprecated
# So, if the bucket name is suitable, we need to use it
# as a subdomain in the host name instead.
#
# Currently buckets with periods in their names cannot be handled in
# that manner due to SSL certificate issues, they will have to remain
# in the url path instead.
#
########################################################################
sub is_domain_bucket { goto &_can_bucket_be_subdomain; }
########################################################################

########################################################################
sub _can_bucket_be_subdomain {
########################################################################
  my ($bucketname) = @_;

  return $FALSE
    if length $bucketname > $MAX_BUCKET_NAME_LENGTH - 1;

  return $FALSE
    if length $bucketname < $MIN_BUCKET_NAME_LENGTH;

  return $FALSE
    if $bucketname !~ m{\A[[:lower:]][[:lower:]\d-]*\z}xsm;

  return $FALSE
    if $bucketname !~ m{[[:lower:]\d]\z}xsm;

  return $TRUE;
}

########################################################################
sub _make_request {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $method, $path, $headers, $data, $metadata, $region )
    = @{$parameters}{qw(method path headers data metadata region)};

  # reset region on every call...every bucket can have it's own region
  $self->region( $region // $self->_region );

  croak 'must specify method'
    if !$method;

  croak 'must specify path'
    if !defined $path;

  $headers //= {};

  $metadata //= {};

  $data //= $EMPTY;
  $headers->{'Content-Length'} //= length $data;

  my $http_headers = $self->_merge_meta( $headers, $metadata );

  my $protocol = $self->secure ? 'https' : 'http';

  my $host = $self->host;

  $path =~ s/\A\///xsm;
  my $url = sprintf '%s://%s/%s', $protocol, $host, $path;

  #  if ( $path =~ m{\A([^/?]+)([^?]+)(.*)}xsm
  if ( $path =~ /\A([^\/?]+)([^?]+)(.*)/xsm
    && $self->dns_bucket_names
    && is_domain_bucket($1) ) {

    my $bucket = $1;
    $path = $2;

    my $query_string = $3;

    $self->logger->debug(
      sub {
        return Dumper(
          [ bucket       => $bucket,
            path         => $path,
            query_string => $query_string,
          ]
        );
      }
    );

    if ( $host =~ /([^:]+):([^:]\d+)$/xsm ) {

      my $port;

      $url = eval {
        $port = $2;
        $host = $1;

        my $uri = URI->new;

        $uri->scheme('http');
        $uri->host("$bucket.$host");
        $uri->port($port);
        $uri->path($path);

        return $uri . $query_string;
      };

      die sprintf
        "error creating uri for bucket: [%s], host: [%s], path: [%s], port: [%s]\n%s",
        $bucket, $host, $path, $port, $EVAL_ERROR

        if !$url || $EVAL_ERROR;
    }
    else {
      $url = sprintf '%s://%s.%s%s%s', $protocol, $bucket, $host, $path, $query_string;
    }
  }

  my $request = HTTP::Request->new( $method, $url, $http_headers );

  $self->last_request($request);

  if ($data) {
    $request->content($data);
  }

  $self->signer->region($region);  # always set regional endpoint for signing

  $self->signer->sign($request);

  return $request;
}

########################################################################
sub send_request {
########################################################################
  my ( $self, @args ) = @_;

  my $logger = $self->get_logger;

  $logger->trace(
    sub {
      return Dumper( [ args => \@args ] );
    },
  );

  my $keep_root = $FALSE;

  my $request = eval {
    return $args[0]
      if ref( $args[0] ) =~ /HTTP::Request/xsm;

    return {@args}
      if @args > 1 && !@args % 2;

    return $args[0]
      if ref $args[0];

    croak 'invalid argument to send_request';
  };

  if ( ref($request) !~ /HTTP::Request/xsm ) {
    $keep_root = delete $request->{keep_root};

    $request = $self->_make_request($request);
  }

  my $response = $self->_do_http($request);

  $self->last_response($response);

  $logger->debug(
    sub {
      return Dumper( [ response => $response ] );
    }
  );

  return $self->_decode_response( $response, $keep_root );
}

########################################################################
sub _decode_response {
########################################################################
  my ( $self, $response, $keep_root ) = @_;

  my $content;

  if ( $response->code !~ /\A2\d{2}\z/xsm ) {
    $self->_handle_response_error($response);
    $content = undef;
  }
  elsif ( is_xml_response($response) ) {
    $content = $self->_xpc_of_content( $response->content, $keep_root );
  }

  return $content;
}

########################################################################
sub is_xml_response {
########################################################################
  my ($rsp) = @_;

  return $FALSE
    if !$rsp->content;

  return $TRUE
    if $rsp->content_type eq 'application/xml';

  return $TRUE
    if $rsp->content =~ /\A\s*<[?]xml/xsm;

  return $FALSE;
}

#
# This is the necessary to find the region for a specific bucket
# and set the signer object to use that region when signing requests
########################################################################
sub adjust_region {
########################################################################
  my ( $self, $bucket, $called_from_redirect ) = @_;

  my $url = sprintf 'https://%s.%s', $bucket, $self->host;

  my $request = HTTP::Request->new( GET => $url );

  $self->{'signer'}->sign($request);

  # We have to turn off our special retry since this will deliberately
  # trigger that code
  $self->turn_off_special_retry();

  # If the bucket name has a period in it, the certificate validation
  # will fail since it will expect a certificate for a subdomain.
  # Setting it to verify against the expected host guards against
  # that while still being secure since we will have verified
  # the response as coming from the expected server.
  $self->ua->ssl_opts( SSL_verifycn_name => $self->host );

  my $response = $self->_do_http($request);

  # Turn this off, since all other requests have the bucket after
  # the host in the URL, and the host may change depending on the region
  $self->ua->ssl_opts( SSL_verifycn_name => undef );

  $self->turn_on_special_retry();

  # If No error, then nothing to do
  return $TRUE
    if $response->is_success();

  # If the error is due to the wrong region, then we will get
  # back a block of XML with the details
  return $FALSE
    if !is_xml_response($response);

  my $error_hash = $self->_xpc_of_content( $response->content );

  my ( $endpoint, $code, $region, $message )
    = @{$error_hash}{qw(Endpoint Code Region Message)};

  my $condition = eval {
    return 'PermanentRedirect'
      if $code eq 'PermanentRedirect' && $endpoint;

    return 'AuthorizationHeaderMalformed'
      if $code eq 'AuthorizationHeaderMalformed' && $region;

    return 'IllegalLocationConstraintException'
      if $code eq 'IllegalLocationConstraintException';

    return 'Other';
  };

  my %error_handlers = (
    PermanentRedirect => sub {
      # Don't recurse through multiple redirects
      return $FALSE
        if $called_from_redirect;

      # With a permanent redirect error, they are telling us the explicit
      # host to use.  The endpoint will be in the form of bucket.host
      my $host = $endpoint;

      # Remove the bucket name from the front of the host name
      # All the requests will need to be of the form https://host/bucket
      $host =~ s/\A$bucket[.]//xsm;
      $self->host($host);

      # We will need to call ourselves again in order to trigger the
      # AuthorizationHeaderMalformed error in order to get the region
      return $self->adjust_region( $bucket, $TRUE );
    },
    AuthorizationHeaderMalformed => sub {
      # Set the signer to use the correct reader evermore
      $self->{signer}->{endpoint} = $region;

      # Only change the host if we haven't been called as a redirect
      # where an exact host has been given
      if ( !$called_from_redirect ) {
        $self->host( sprintf 's3-%s-amazonaws.com', $region );
      }

      return $TRUE;
    },
    IllegalLocationConstraintException => sub {
      # This is hackish; but in this case the region name only appears in the message
      if ( $message =~ /The (\S+) location/xsm ) {
        my $new_region = $1;

        # Correct the region for the signer
        $self->{signer}->{endpoint} = $new_region;

        # Set the proper host for the region
        $self->host( sprintf 's3.%s.amazonaws.com', $new_region );

        return $TRUE;
      }
    },
    'Other' => sub {
      # Some other error
      $self->_remember_errors( $response->content, 1 );
      return $FALSE;
    },
  );

  return $error_handlers{$condition}->();
}

########################################################################
sub reset_errors {
########################################################################
  my ($self) = @_;

  $self->err(undef);
  $self->errstr(undef);
  $self->error(undef);

  return $self;
}

########################################################################
sub _do_http {
########################################################################
  my ( $self, $request, $filename ) = @_;

  # convenient time to reset any error conditions
  $self->reset_errors;

  my $response = $self->ua->request( $request, $filename );

  # For new buckets at non-standard locations, amazon will sometimes
  # respond with a temporary redirect.  In this case it is necessary
  # to try again with the new URL
  my $location = $response->header('Location');

  if ( $response->code =~ /\A3/xsm and defined $location ) {

    $self->get_logger->debug(
      sub {
        return { sprintf 'Redirecting to:  %s', $location };
      }
    );

    $request->uri($location);
    $response = $self->ua->request( $request, $filename );
  }

  $self->get_logger->debug( sub { return Dumper( [$response] ) } );

  $self->last_response($response);

  return $response;
}

# Call this if handling any temporary redirect issues
# (Like needing to probe with a HEAD request when file handle are involved)

########################################################################
sub _do_http_no_redirect {
########################################################################
  my ( $self, $request, $filename ) = @_;

  # convenient time to reset any error conditions
  $self->reset_errors;

  my $response = $self->ua->request( $request, $filename );

  $self->get_logger->debug( sub { return Dumper( [$response] ) } );

  $self->last_response($response);

  return $response;
}

########################################################################
sub send_request_expect_nothing {
########################################################################
  my ( $self, @args ) = @_;

  my $request = $self->_make_request(@args);

  my $response = $self->_do_http($request);

  my $content = $response->content;

  return $TRUE
    if $response->code =~ /^2\d\d$/xsm;

  # anything else is a failure, and we save the parsed result
  $self->_handle_response_error($response);

  return $FALSE;
}

# Send a HEAD request first, to find out if we'll be hit with a 307 redirect.
# Since currently LWP does not have true support for 100 Continue, it simply
# slams the PUT body into the socket without waiting for any possible redirect.
# Thus when we're reading from a filehandle, when LWP goes to reissue the request
# having followed the redirect, the filehandle's already been closed from the
# first time we used it. Thus, we need to probe first to find out what's going on,
# before we start sending any actual data.
########################################################################
sub send_request_expect_nothing_probed {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $method, $path, $conf, $value, $region )
    = @{$parameters}{qw(method path headers data region)};

  $region = $region // $self->region;

  my $request = $self->_make_request(
    { method => 'HEAD',
      path   => $path,
      region => $region,
    },
  );

  my $override_uri;

  my $old_redirectable = $self->ua->requests_redirectable;
  $self->ua->requests_redirectable( [] );

  my $response = $self->_do_http_no_redirect($request);

  if ( $response->code =~ /^3/xsm ) {
    if ( defined $response->header('Location') ) {
      $override_uri = $response->header('Location');
    }
    else {
      $self->_handle_response_error( $response, $TRUE );
    }

    $self->get_logger->debug(
      sub {
        return sprintf 'setting override URI: [%s]', $override_uri;
      }
    );
  }

  $request = $self->_make_request(
    { method  => $method,
      path    => $path,
      headers => $conf,
      data    => $value,
      region  => $region,
    },
  );

  if ( defined $override_uri ) {
    $request->uri($override_uri);
  }

  $response = $self->_do_http_no_redirect($request);

  $self->ua->requests_redirectable($old_redirectable);

  my $content = $response->content;

  return $TRUE
    if $response->code =~ /^2\d\d$/xsm;

  # anything else is a failure, and we save the parsed result
  $self->_handle_response_error($response);

  return $FALSE;
}

########################################################################
sub _croak_if_response_error {
########################################################################
  my ( $self, $response ) = @_;

  return
    if $response->code =~ /^2\d{2}$/xsm;

  return $self->_handle_response_error( $response, $TRUE );
}

########################################################################
sub _xpc_of_content {
########################################################################
  my ( $self, $src, $keep_root ) = @_;

  my $xml_hr
    = eval { XMLin( $src, SuppressEmpty => $EMPTY, ForceArray => ['Contents'], KeepRoot => $keep_root, NoAttr => $TRUE, ); };

  if ( !$xml_hr && $EVAL_ERROR ) {
    confess "Error parsing $src:  $EVAL_ERROR";
  }

  return $xml_hr;
}

########################################################################
sub _handle_response_error {
########################################################################
  my ( $self, $response, $force_raise ) = @_;

  my $remembered = eval { return $self->_remember_errors( $response->content, $TRUE ); };

  if ( !$remembered ) {
    $self->err('network_error');
    $self->errstr( $response->status_line );
  }

  if ( $self->raise_error || $force_raise ) {
    croak sprintf '%s - %s: %s', $response->status_line, $self->err, $self->errstr;
  }

  return $TRUE;
}
# returns 1 if errors were found
########################################################################
sub _remember_errors {
########################################################################
  my ( $self, $src, $keep_root ) = @_;

  return
    if !$src;

  if ( !ref $src && $src !~ /^[[:space:]]*</xsm ) {
    ( my $code = $src ) =~ s/^[[:space:]]*[(]([\d]*)[)].*$/$1/xsm;

    $self->err($code);
    $self->errstr($src);

    return $TRUE;
  }

  my $r = ref $src ? $src : $self->_xpc_of_content( $src, $keep_root );

  $self->error($r);

  # apparently buckets() does not keep_root
  if ( $r->{Error} ) {
    $r = $r->{Error};
  }

  my ( $code, $message ) = @{$r}{qw(Code Message)};

  return $FALSE
    if !$code;

  $self->err($code);
  $self->errstr($message);

  return $TRUE;
}

# Deprecated - this adds a header for the old V2 auth signatures
########################################################################
sub _add_auth_header { ## no critic (ProhibitUnusedPrivateSubroutines)
########################################################################
  my ( $self, $headers, $method, $path ) = @_;

  my ( $aws_access_key_id, $aws_secret_access_key, $token ) = $self->get_credentials;

  if ( not $headers->header('Date') ) {
    $headers->header( Date => time2str(time) );
  }

  if ($token) {
    $headers->header( $AMAZON_HEADER_PREFIX . 'security-token' => $token );
  }

  my $canonical_string = $self->_canonical_string( $method, $path, $headers );

  $self->get_logger->trace(
    sub {
      return Dumper(
        [ headers          => $headers,
          canonincal_sring => $canonical_string,
        ]
      );
    }
  );

  my $encoded_canonical = $self->_encode( $aws_secret_access_key, $canonical_string );

  $headers->header(
    Authorization => sprintf 'AWS %s:%s',
    $aws_access_key_id, $encoded_canonical
  );

  return;
}

# generates an HTTP::Headers objects given one hash that represents http
# headers to set and another hash that represents an object's metadata.
########################################################################
sub _merge_meta {
########################################################################
  my ( $self, $headers, $metadata ) = @_;

  $headers  //= {};
  $metadata //= {};

  my $http_header = HTTP::Headers->new;

  foreach my $p ( pairs %{$headers} ) {
    my ( $k, $v ) = @{$p};
    $http_header->header( $k => $v );
  }

  foreach my $p ( pairs %{$metadata} ) {
    my ( $k, $v ) = @{$p};
    $http_header->header( "$METADATA_PREFIX$k" => $v );
  }

  return $http_header;
}

# generate a canonical string for the given parameters.  expires is optional and is
# only used by query string authentication.
########################################################################
sub _canonical_string {
########################################################################
  my ( $self, $method, $path, $headers, $expires ) = @_;

  # initial / meant to force host/bucket-name instead of DNS based name
  $path =~ s/^\///xsm;

  my %interesting_headers = ();

  foreach my $p ( pairs %{$headers} ) {
    my ( $key, $value ) = @{$p};
    my $lk = lc $key;

    if ( $lk eq 'content-md5'
      or $lk eq 'content-type'
      or $lk eq 'date'
      or $lk =~ /^$AMAZON_HEADER_PREFIX/xsm ) {
      $interesting_headers{$lk} = $self->_trim($value);
    }
  }

  # these keys get empty strings if they don't exist
  $interesting_headers{'content-type'} ||= $EMPTY;
  $interesting_headers{'content-md5'}  ||= $EMPTY;

  # just in case someone used this.  it's not necessary in this lib.
  if ( $interesting_headers{'x-amz-date'} ) {
    $interesting_headers{'date'} = $EMPTY;
  }

  # if you're using expires for query string auth, then it trumps date
  # (and x-amz-date)
  if ($expires) {
    $interesting_headers{'date'} = $expires;
  }

  my $buf = "$method\n";

  foreach my $key ( sort keys %interesting_headers ) {
    if ( $key =~ /^$AMAZON_HEADER_PREFIX/xsm ) {
      $buf .= "$key:$interesting_headers{$key}\n";
    }
    else {
      $buf .= "$interesting_headers{$key}\n";
    }
  }

  # don't include anything after the first ? in the resource...
  #  $path =~ /^([^?]*)/xsm;
  #  $buf .= "/$1";
  $path =~ /\A([^?]*)/xsm;
  $buf .= "/$1";

  # ...unless there any parameters we're interested in...
  if ( $path =~ /[&?](acl|torrent|location|uploads|delete)([=&]|$)/xsm ) {
    #  if ( $path =~ /[&?](acl|torrent|location|uploads|delete)([=&])?/xsm ) {
    $buf .= "?$1";
  }
  elsif ( my %query_params = URI->new($path)->query_form ) {
    # see if the remaining parsed query string provides us with any
    # query string or upload id

    if ( $query_params{partNumber} && $query_params{uploadId} ) {
      # re-evaluate query string, the order of the params is important
      # for request signing, so we can't depend on URI to do the right
      # thing
      $buf .= sprintf '?partNumber=%s&uploadId=%s', $query_params{partNumber}, $query_params{uploadId};
    }
    elsif ( $query_params{uploadId} ) {
      $buf .= sprintf '?uploadId=%s', $query_params{uploadId};
    }
  }

  return $buf;
}

########################################################################
sub _trim {
########################################################################
  my ( $self, $value ) = @_;

  $value =~ s/^\s+//xsm;
  $value =~ s/\s+$//xsm;

  return $value;
}

# finds the hmac-sha1 hash of the canonical string and the aws secret access key and then
# base64 encodes the result (optionally urlencoding after that).
########################################################################
sub _encode {
########################################################################
  my ( $self, $aws_secret_access_key, $str, $urlencode ) = @_;

  my $hmac = Digest::HMAC_SHA1->new($aws_secret_access_key);
  $hmac->add($str);

  my $b64 = encode_base64( $hmac->digest, $EMPTY );

  return $urlencode ? urlencode($b64) : return $b64;
}

########################################################################
sub bucketv2 {
########################################################################
  my ( $self, @args ) = @_;

  my $parameters = get_parameters(@args);

  my ( $bucketname, $region, $verify_region )
    = @{$parameters}{qw(bucket region verify_region)};

  # only set to default region if a region wasn't passed or region
  # verification not requested
  if ( !$region && !$verify_region ) {
    $region = $self->region;
  }

  return Amazon::S3::BucketV2->new(
    { bucket        => $bucketname,
      account       => $self,
      region        => $region,
      verify_region => $verify_region,
    },
  );
}

########################################################################
sub delete_public_access_block {
########################################################################
  my ( $self, $bucket ) = @_;

  my $bucketv2 = bless $bucket, 'Amazon::S3::BucketV2';

  return $bucketv2->DeletePublicAccessBlock;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Amazon::S3 - A Perl client library for working with and managing
Amazon S3 buckets and objects.

=head1 SYNOPSIS

  use Amazon::S3;

  my $s3 = Amazon::S3->new(
    { credentials => $credentials,
      region      => 'us-east-1',
    }
  );

  my $bucket = $s3->bucket('example-bucket');

  $bucket->add_key(
    'testing.txt',
    'T',
    { content_type        => 'text/plain',
      'x-amz-meta-colour' => 'orange',
    }
  );

  my $response = $bucket->list
    or die $s3->err . ': ' . $s3->errstr;

  for my $key ( @{ $response->{keys} } ) {
    print $key->{key} . "\n";
  }

  my $object = $bucket->get_key('testing.txt')
    or die $s3->err . ': ' . $s3->errstr;

  print $object->{value};

=head1 DESCRIPTION

C<Amazon::S3> provides a Perl interface to Amazon Simple Storage
Service (S3).

The distribution separates account-level S3 operations from
bucket and object operations.

C<Amazon::S3> represents the S3 client and AWS account context. It
manages credentials, request signing, regions, service endpoints,
bucket creation and discovery, and account-level listing operations.

L<Amazon::S3::Bucket> represents an individual bucket. Object
operations such as uploads, downloads, deletes, ACLs, multipart
uploads, and bucket-scoped listing operations are provided primarily
through that class.

L<Amazon::S3::BucketV2> is a subclass of L<Amazon::S3::Bucket> that
provides a more general interface to S3 APIs. It accepts API
parameters, headers, URI parameters, and request payload structures
using a consistent calling convention.

C<Amazon::S3> originated as a fork of L<Net::Amazon::S3>, but the two
distributions have diverged substantially. Current versions should
not be considered interchangeable.

Version 2.1.0 adds modern S3 checksum support while preserving the
existing C<Amazon::S3> and L<Amazon::S3::Bucket> interfaces. Managed
uploads use CRC64NVME by default, and downloads can request and verify
checksum metadata returned by S3.

=head1 AUTHENTICATION AND CREDENTIALS

C<Amazon::S3> supports either explicit AWS access keys or a credentials
object.

Explicit credentials may be supplied to the constructor:

  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => $aws_access_key_id,
      aws_secret_access_key => $aws_secret_access_key,
      token                 => $session_token,
    }
  );

The C<token> option is required only when temporary AWS credentials
include a session token.

For applications that obtain credentials dynamically, a credentials
object is preferred:

  my $s3 = Amazon::S3->new({ credentials => $credentials } );

The credentials object must provide:

  get_aws_access_key_id()
  get_aws_secret_access_key()
  get_token()

L<Amazon::Credentials> is one implementation of this interface.

Using a credentials object allows the credential provider to manage
credential discovery and refresh independently of C<Amazon::S3>.

C<Amazon::S3> uses Signature Version 4 for AWS API requests.

The signer normally uses the credentials associated with the
C<Amazon::S3> object. A signer may also be supplied to the constructor
using the C<signer> option.

By default, signers are not cached. Setting C<cache_signer> to true
causes C<Amazon::S3> to retain and reuse the signer object.

Applications should avoid dumping C<Amazon::S3>, credential, or signer
objects to logs. These objects participate in request authentication
and may contain or provide access to sensitive authentication
material.

=head1 CHECKSUMS

Version 2.1.0 adds checksum generation for uploads and checksum
verification for downloads.

The default upload checksum algorithm is C<crc64nvme>.

C<Amazon::S3> provides local implementations for:

  crc64nvme
  crc32
  crc32c
  md5
  sha1
  sha256
  sha512

Amazon S3 also defines XXHash checksum algorithms. They are recognized
by C<Amazon::S3> but are not implemented locally in this release.

=head2 Uploads

When an upload is performed through L<Amazon::S3::Bucket>,
C<Amazon::S3> calculates the configured checksum when that operation
supports checksum submission.

The checksum algorithm is selected using C<checksum_algorithm>. The
default is C<crc64nvme>.

Managed multipart uploads performed by
C<Amazon::S3::Bucket::upload_multipart_object()> also use the
configured checksum algorithm.

Low-level multipart methods do not implicitly enable an additional
checksum algorithm. Applications that directly manage the multipart
workflow are responsible for selecting and carrying the checksum
algorithm through that workflow.

=head2 Downloads

Checksum verification is enabled by default.

When C<verify_checksums> is true, object downloads request checksum
metadata from S3. C<Amazon::S3> verifies supported C<FULL_OBJECT>
checksums returned by the service.

Verification is opportunistic. If S3 does not return a checksum, or
returns a checksum for an algorithm that C<Amazon::S3> cannot
calculate locally, the object can still be downloaded.

C<COMPOSITE> checksums are not independently verified.

Partial and ranged downloads are not checksum verified because the
checksum returned for an object describes the complete object rather
than the requested byte range.

The C<verify_checksums> setting controls download verification only.
It does not disable checksum generation for uploads.

=head1 WORKING WITH BUCKETS AND OBJECTS

C<Amazon::S3> creates bucket objects that provide the object-oriented
interface used for most S3 operations.

=head2 Creating and Representing Buckets

C<add_bucket()> creates a bucket in S3.

C<bucket()> and C<bucketv2()> do not create a bucket. They construct
client-side objects representing a bucket.

A bucket region can be supplied explicitly when constructing a bucket
object. Region verification can also be requested when the bucket
region is not already known; doing so requires an additional service
request.

Amazon S3 applies public-access-block settings to new buckets by
default. Applications that intentionally create public buckets or
apply public ACLs must ensure that the account and bucket public access
settings permit the requested policy.

Directory buckets have additional creation requirements. See
L</DIRECTORY BUCKETS>.


  my $bucket = $s3->bucket('example-bucket');

Calling C<bucket()> does not create the bucket and does not verify
that it exists. It constructs an L<Amazon::S3::Bucket> object
associated with the C<Amazon::S3> client.

A bucket can be assigned a region explicitly:

  my $bucket = $s3->bucket(
    { bucket => 'example-bucket',
      region => 'us-west-2',
    }
  );

The bucket interface provides operations including:

  add_key()
  add_key_filename()
  copy_object()
  delete_key()
  delete_keys()
  get_acl()
  get_key()
  get_key_filename()
  head_key()
  set_acl()

See L<Amazon::S3::Bucket> for the method reference for bucket and
object operations.

=head1 LISTING OBJECTS

The distribution provides both the original S3 ListObjects API and
ListObjectsV2.

At the C<Amazon::S3> level these are exposed as:

  list_bucket()
  list_bucket_v2()

The corresponding convenience methods:

  list_bucket_all()
  list_bucket_all_v2()

follow pagination automatically and return the combined result.

L<Amazon::S3::Bucket> provides bucket-oriented wrappers for these
operations.

=head2 Choosing a Listing API

ListObjectsV2 is generally preferred for new code.

C<list_bucket()> uses the original marker-based pagination model.

C<list_bucket_v2()> uses the continuation-token model introduced by
ListObjectsV2 and also supports C<start-after>.

Applications that need control over individual result pages should
use C<list_bucket()> or C<list_bucket_v2()> directly.

Applications that simply need all matching objects can use the
corresponding C<_all> method.

=head2 Prefixes and Delimiters

S3 keys are not filesystem paths. However, C<prefix> and C<delimiter>
can be used to present a hierarchy-like view of keys.

For example, given these keys:

  bar/baz
  bar/buz
  bar/buz/biz
  bar/buz/zip

a request using:

  prefix    => 'bar/'
  delimiter => '/'

returns the keys at that level and rolls deeper keys into a common
prefix.

A typical request is:

  my $response = $s3->list_bucket_v2(
    { bucket    => 'example-bucket',
      prefix    => 'bar/',
      delimiter => '/',
    }
  );

The rolled-up prefixes are returned in C<common_prefixes>.

=head2 Pagination

C<list_bucket()> resumes a truncated listing using C<marker>.

When a delimiter is used, the normalized response can contain
C<next_marker>. Without a delimiter, the last returned key can be
used as the marker for the next request.

C<list_bucket_v2()> resumes a truncated listing using the continuation
token returned by S3. In the normalized C<Amazon::S3> result,
C<next_marker> contains C<NextContinuationToken>.

For example:

  my $response = $s3->list_bucket_v2(
    { bucket => 'example-bucket',
    }
  );

  while ( $response->{is_truncated} ) {
    $response = $s3->list_bucket_v2(
      { bucket               => 'example-bucket',
        'continuation-token' => $response->{next_marker},
      }
    );
  }

When application code does not need to process individual pages,
C<list_bucket_all()> and C<list_bucket_all_v2()> perform this work
automatically.

=head2 Listing Results

C<list_bucket()> and C<list_bucket_v2()> normalize their results into
the same general structure:

  {
    bucket          => $bucket_name,
    prefix          => $prefix,
    marker          => $marker,
    next_marker     => $next_marker,
    max_keys        => $max_keys,
    is_truncated    => $boolean,
    keys            => \@keys,
    common_prefixes => \@prefixes,
  }

C<common_prefixes> is present when the request uses a delimiter and S3
returns rolled-up prefixes.

Each element of C<keys> is a hash reference containing object metadata:

  {
    key               => $key,
    last_modified     => $last_modified,
    etag              => $etag,
    size              => $size,
    storage_class     => $storage_class,
    owner_id          => $owner_id,
    owner_displayname => $owner_displayname,
  }

The C<etag> value is the ETag returned by S3. It must not be assumed
to be a checksum of the complete object.

C<list_object_versions()> is different: it returns the parsed
ListObjectVersions service response rather than this normalized
listing structure and does not automatically follow pagination.

See the corresponding entries under L</METHODS AND SUBROUTINES> for
the method contracts.

=head1 MULTIPART UPLOADS

Multipart upload operations are provided by L<Amazon::S3::Bucket>.

For normal application use,
C<Amazon::S3::Bucket::upload_multipart_object()> is the preferred
interface. It manages initiation, part uploads, completion, checksum
state, and optional abort-on-error behavior.

  my $parts = $bucket->upload_multipart_object(
    { key  => 'large-object.dat',
      data => $data,
    }
  );

The method can also consume data from a file handle or callback.

The lower-level multipart methods are available for applications that
need to control the multipart lifecycle themselves:

  initiate_multipart_upload()
  upload_part_of_multipart_upload()
  complete_multipart_upload()
  abort_multipart_upload()
  list_multipart_upload_parts()
  list_multipart_uploads()

These methods should generally be considered building blocks for
specialized workflows rather than the default multipart API.

See L<Amazon::S3::Bucket> for their complete method documentation.

=head1 DIRECTORY BUCKETS

C<Amazon::S3> provides limited support for Amazon S3 directory
buckets.

Directory buckets use the S3 Express One Zone storage class.

C<Amazon::S3> can currently create and list directory buckets.
Object access within directory buckets is not yet supported because
that requires creating an S3 Express session and using the resulting
temporary credentials when signing requests to the directory bucket's
Zonal endpoint.

A directory bucket can be created by supplying an availability zone
to C<add_bucket()>:

  my $bucket = $s3->add_bucket(
    { bucket            => $bucket_name,
      availability_zone => 'use1-az5',
    }
  );

Directory buckets owned by the account can be listed with
C<list_directory_buckets()>.

See
L<https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-overview.html>.

=head1 ERROR HANDLING

C[Amazon::S3](Amazon::S3) uses both return-value errors and exceptions.

For backward compatibility, many service operations return C<undef> or
a false value when an S3 request fails and record information about the
most recent error on the C[Amazon::S3](Amazon::S3) object.

The primary error accessors are:

err()
errstr()
error()

C<err()> contains the S3 error code when one is available.

C<errstr()> contains the human-readable service error message.

C<error()> contains the parsed structured error response when the
service returned one.

Typical error handling using the historical interface therefore looks
like:

my $response = $s3->buckets;

if (!$response) {
die $s3->err . ': ' . $s3->errstr;
}

Applications that prefer request failures to throw exceptions can
enable C<raise_error> when constructing the client:

my $s3 = Amazon::S3->new(
credentials => $credentials,
raise_error => 1,
);

With C<raise_error> enabled, S3 request failures that would normally
return a failure value instead throw an exception. The error state is
still recorded in C<err()>, C<errstr()>, and C<error()> before the
exception is raised.

When available, the exception includes the HTTP status together with
the S3 error code and message.

Some request, protocol, multipart, checksum verification, and
validation failures always throw exceptions because the operation
cannot safely continue.

The most recent HTTP request and response can be inspected using
C<last_request()> and C<last_response()>.

These accessors are especially useful when diagnosing signing,
endpoint, header, or protocol problems.

C<raise_error> defaults to false to preserve the historical
C[Amazon::S3](Amazon::S3) interface. New applications may prefer to enable it when
they want request failures to be impossible to overlook.

=head1 METHODS AND SUBROUTINES

This section documents methods provided directly by C<Amazon::S3>.

Methods implemented by L<Amazon::S3::Bucket> or
L<Amazon::S3::BucketV2> are documented by those classes and are not
duplicated here.

Unless otherwise noted, a service operation returns C<undef> when an
error occurs and records error information on the C<Amazon::S3>
object. Some request, protocol, and validation failures throw an
exception instead.

See L</ERROR HANDLING>.

=head2 CONSTRUCTOR

=head3 new

  my $s3 = Amazon::S3->new(%options);

  my $s3 = Amazon::S3->new(\%options);

Creates and returns a new C<Amazon::S3> client object.

The constructor accepts either a list of key/value pairs or a hash
reference.

At least one of the following credential configurations is required:

=over 4

=item *

A C<credentials> object that provides C<get_aws_access_key_id()>,
C<get_aws_secret_access_key()>, and C<get_token()>.

=item *

Both C<aws_access_key_id> and C<aws_secret_access_key>.

=back

The following options are supported:

=over 4

=item aws_access_key_id

AWS access key ID.

This option is required when a C<credentials> object is not supplied.

When explicit credentials are supplied, C<Amazon::S3> stores them
internally for use when signing requests. Applications should avoid
dumping the client object to logs.

See L</AUTHENTICATION AND CREDENTIALS>.

=item aws_secret_access_key

AWS secret access key.

This option is required when a C<credentials> object is not supplied.

See L</AUTHENTICATION AND CREDENTIALS>.

=item buffer_size

Default buffer size, in bytes, used by operations that stream object
data.

The default is 4096.

=item cache_signer

When true, retain and reuse the Signature Version 4 signer.

When false, construct a signer when one is needed.

The default is false.

See L</AUTHENTICATION AND CREDENTIALS>.

=item checksum_algorithm

Checksum algorithm used when C<Amazon::S3> supplies a checksum with an
upload.

The default is C<crc64nvme>.

Recognized S3 checksum algorithm names are validated by the
constructor. Local checksum implementations provided by this release
are described in L</CHECKSUMS>.

=item credentials

Credentials provider object.

The object must provide:

  get_aws_access_key_id()
  get_aws_secret_access_key()
  get_token()

L<Amazon::Credentials> is one implementation of this interface.

See L</AUTHENTICATION AND CREDENTIALS>.

=item debug

Compatibility option that sets the default logger level to C<debug>.

Applications should normally use C<level> instead.

This option affects the internally created logger only.

=item dns_bucket_names

Controls whether virtual-hosted-style bucket names are used when
possible.

The default is true.

A bucket name that cannot be used as a DNS subdomain is placed in the
request path instead.

=item endpoint_url

A fully qualified HTTP or HTTPS service endpoint. The URL may include a
port. This constructor option is a convenience for setting C<host> and
C<secure> together.

For example:

  endpoint_url => 'http://localhost:4566'

C<endpoint_url> cannot be used together with C<host> or C<secure> and
must not contain a path.

=item host

S3 service endpoint.

The default is C<s3.amazonaws.com>.

When C<region()> is set and the host is a standard Amazon S3 endpoint,
C<Amazon::S3> adjusts the host for the configured region.

This option can also be used with S3-compatible and local testing
services.

=item level

Logging level used when C<Amazon::S3> creates its default logger.

The default is C<error>.

See L</LOGGING AND DEBUGGING>.

=item logger

Logger object.

If omitted, C<Amazon::S3::Logger> is used.

A caller-supplied logger is expected to provide the logging methods
used by C<Amazon::S3>.

See L</LOGGING AND DEBUGGING>.

=item raise_error

When true, S3 request failures that would normally be reported through
the return value and the C<err()>, C<errstr()>, and C<error()> accessors
instead throw an exception.

The exception includes the HTTP status and, when available, the S3
error code and message.

The default is false for backward compatibility.

See L</ERROR HANDLING>.

=item region

AWS region used for account-level requests and as the default region
for newly constructed bucket objects.

The default is C<us-east-1>.

=item retry

When true, use retry-aware HTTP handling.

Retries use exponential delays of 1, 2, 4, 8, 16, and 32 seconds.

The default is false.

=item secure

When true, use HTTPS when communicating with the service.

The default is true.

=item signer

Optional Signature Version 4 signer object.

When supplied, this signer is used instead of constructing one from
the configured credentials.

See L</AUTHENTICATION AND CREDENTIALS>.

=item timeout

HTTP request timeout in seconds.

The default is 30.

=item token

Optional AWS session token used with temporary credentials.

=item verify_checksums

Controls checksum verification when downloading objects.

The default is true.

See L</CHECKSUMS>.

=back

If neither a credentials provider nor both explicit access key values
are supplied, the constructor throws an exception.

An invalid C<checksum_algorithm> also causes the constructor to throw
an exception.

On success, returns the new C<Amazon::S3> object.

=head2 ACCESSORS

=head3 buffer_size

  my $buffer_size = $s3->buffer_size;

  $s3->buffer_size($bytes);

Gets or sets the default streaming buffer size in bytes.

The constructor default is 4096.

=head3 cache_signer

  my $cache_signer = $s3->cache_signer;

  $s3->cache_signer($boolean);

Gets or sets whether a generated request signer is retained for reuse.

The constructor default is false.

See L</AUTHENTICATION AND CREDENTIALS>.

=head3 checksum_algorithm

  my $algorithm = $s3->checksum_algorithm;

  $s3->checksum_algorithm('sha256');

Gets or sets the checksum algorithm selected for uploads.

The constructor default is C<crc64nvme>.

The constructor validates the initial value. Callers that change this
accessor after construction are responsible for supplying an
algorithm supported by the operation being performed.

See L</CHECKSUMS>.

=head3 checksum_types

  my $checksum_types = $s3->checksum_types;

Returns the checksum implementations initialized for this client.

The value is a hash reference keyed by algorithm name.

This accessor is intended for introspection. The internal checksum
implementation entries are not a public plugin interface in this
release.

See L</CHECKSUMS>.

=head3 credentials

  my $credentials = $s3->credentials;

  $s3->credentials($credentials);

Gets or sets the credentials provider object.

See L</AUTHENTICATION AND CREDENTIALS>.

=head3 dns_bucket_names

  my $enabled = $s3->dns_bucket_names;

  $s3->dns_bucket_names($boolean);

Gets or sets whether virtual-hosted-style bucket addressing is used
when possible.

The constructor default is true.

=head3 err

Returns the most recent S3 error code or short error identifier.

See L</ERROR HANDLING>.

=head3 error

Returns the most recent parsed structured error response.

See L</ERROR HANDLING>.

=head3 errstr

Returns the most recent human-readable error message.

See L</ERROR HANDLING>.

=head3 host

  my $host = $s3->host;

  $s3->host($endpoint);

Gets or sets the configured S3 endpoint.

The constructor default is C<s3.amazonaws.com>.

See L</S3-COMPATIBLE SERVICES>.

=head3 last_request

Returns the most recent L<HTTP::Request> generated by C<Amazon::S3>.

See L</ERROR HANDLING>.

=head3 last_response

Returns the most recent L<HTTP::Response> received by C<Amazon::S3>.

See L</ERROR HANDLING>.

=head3 logger

  my $logger = $s3->logger;

  $s3->logger($logger);

Gets or sets the logger used by C<Amazon::S3>.

See L</LOGGING AND DEBUGGING>.

=head3 retry

  my $retry = $s3->retry;

  $s3->retry($boolean);

Gets or sets whether retry-aware HTTP handling is enabled.

The constructor default is false.

=head3 secure

  my $secure = $s3->secure;

  $s3->secure($boolean);

Gets or sets whether HTTPS is used.

The constructor default is true.

=head3 timeout

  my $timeout = $s3->timeout;

  $s3->timeout($seconds);

Gets or sets the HTTP request timeout in seconds.

The constructor default is 30.

=head3 verify_checksums

  my $verify_checksums = $s3->verify_checksums;

  $s3->verify_checksums($boolean);

Gets or sets whether supported checksums returned for downloaded
objects are verified.

The constructor default is true.

See L</CHECKSUMS>.

=head2 AUTHENTICATION AND CONFIGURATION METHODS

=head3 get_credentials

  my ( $access_key_id, $secret_access_key, $token )
    = $s3->get_credentials;

Returns the credentials used by the client.

When a C<credentials> provider is configured, this method obtains the
three values from that provider.

Otherwise it returns the credentials stored by the C<Amazon::S3>
object.

The return values, in order, are:

=over 4

=item 1.

AWS access key ID.

=item 2.

AWS secret access key.

=item 3.

Session token, or C<undef> when no token is configured.

=back

See L</AUTHENTICATION AND CREDENTIALS>.

=head3 get_default_region

  my $region = $s3->get_default_region;

Attempts to determine the default AWS region.

The method checks, in order:

=over 4

=item 1.

C<AWS_REGION>.

=item 2.

C<AWS_DEFAULT_REGION>.

=item 3.

The EC2 instance metadata availability-zone endpoint.

=back

When an availability zone is obtained from instance metadata, the
zone suffix is removed to derive the region.

If no region can be determined, C<us-east-1> is returned.

=head3 get_logger

  my $logger = $s3->get_logger;

Returns the logger associated with the client.

If no logger was supplied to C<new()>, this is the
L<Amazon::S3::Logger> instance created by the constructor.

This method is provided for compatibility with logger interfaces that
expect C<get_logger()>.

See L</LOGGING AND DEBUGGING>.

=head3 level

  my $level = $s3->level;

  $s3->level('debug');

Gets or sets the logging level.

When a level is supplied, both the stored logging level and the
associated logger level are updated.

When called without an argument, returns the current logger level.

The constructor default is C<error>.

See L</LOGGING AND DEBUGGING>.

=head3 region

  my $region = $s3->region;

  $s3->region('us-west-2');

Gets or sets the region used by the client.

The region is used for account-level requests and as the default
region assigned to bucket objects when no bucket-specific region is
supplied.

When the configured host uses the standard C<s3.amazonaws.com> form,
setting the region also adjusts the host to the regional Amazon S3
endpoint.

The constructor default is C<us-east-1>.

=head3 signer

  my $signer = $s3->signer;

Returns the Signature Version 4 signer used for requests.

If a signer was supplied to the constructor, that signer is returned.

Otherwise a signer is constructed from the current credentials,
region, and session token.

When C<cache_signer> is true, a generated signer is retained and
reused. When it is false, a signer can be generated as needed.

This method does not accept a signer argument. Supply a custom signer
using the C<signer> constructor option.

See L</AUTHENTICATION AND CREDENTIALS>.

=head2 BUCKET MANAGEMENT

=head3 add_bucket

  my $bucket = $s3->add_bucket(\%configuration);

Creates a bucket.

The argument is a hash reference containing the bucket configuration.

=over 4

=item bucket

Required. Bucket name.

=item acl_short

Optional canned ACL.

Optional canned ACL applied when creating the bucket.

See L</WORKING WITH BUCKETS AND OBJECTS>.

=item location_constraint

Compatibility name for the region in which the bucket should be
created.

When both C<location_constraint> and C<region> are supplied,
C<location_constraint> takes precedence.

=item region

Region in which the bucket should be created.

If neither C<region> nor C<location_constraint> is supplied, the
client region is used.

For C<us-east-1>, no location constraint is sent.

=item headers

Optional hash reference containing additional request headers.

=item availability_zone

When supplied, create an S3 directory bucket in the specified
availability zone.

See L</DIRECTORY BUCKETS>.

=back

On success, returns an L<Amazon::S3::Bucket> object for the newly
created bucket.

On failure, returns C<undef> and records error information on the
client.

=head3 bucket

  my $bucket = $s3->bucket($bucket_name);

  my $bucket = $s3->bucket($bucket_name, $region);

  my $bucket = $s3->bucket(
    { bucket        => $bucket_name,
      region        => $region,
      verify_region => $boolean,
    }
  );

Constructs and returns an L<Amazon::S3::Bucket> object.

This method does not create an S3 bucket and does not otherwise verify
that the bucket exists.

The hash-reference form accepts:

=over 4

=item bucket

Bucket name.

=item region

Region containing the bucket.

When no region is supplied and C<verify_region> is false, the client
region is used.

=item verify_region

When true, allow the L<Amazon::S3::Bucket> constructor to determine
the bucket region using the bucket location API.

This incurs an additional service request.

=back

The returned bucket object is associated with this C<Amazon::S3>
client.

See L<Amazon::S3::Bucket>.

=head3 buckets

  my $response = $s3->buckets;

  my $response = $s3->buckets($verify_region);

Lists the general-purpose buckets owned by the account.

C<verify_region> is an optional boolean. When true, each returned
L<Amazon::S3::Bucket> object is constructed with region verification
enabled.

Region verification can require an additional service request for
each bucket and can therefore significantly increase the cost and
latency of C<buckets()>.

The default is false.

On success, returns a hash reference containing:

=over 4

=item owner_id

Owner ID returned by S3.

=item owner_displayname

Owner display name returned by S3.

=item buckets

Array reference of L<Amazon::S3::Bucket> objects.

When the account has no returned buckets, this is an empty array
reference.

=back

On failure, returns C<undef> and records error information on the
client.

=head3 bucketv2

  my $bucket = $s3->bucketv2(
    { bucket        => $bucket_name,
      region        => $region,
      verify_region => $boolean,
    }
  );

Constructs and returns an L<Amazon::S3::BucketV2> object.

The accepted parameters are:

=over 4

=item bucket

Bucket name.

=item region

Region containing the bucket.

When no region is supplied and C<verify_region> is false, the client
region is used.

=item verify_region

When true, allow the bucket object to determine its region.

=back

Like C<bucket()>, this method constructs a client-side object. It does
not create the S3 bucket.

=head3 delete_bucket

  my $ok = $s3->delete_bucket($bucket);

  my $ok = $s3->delete_bucket(
    { bucket  => $bucket_name,
      region  => $region,
      headers => $headers,
    }
  );

Deletes an S3 bucket.

The first form accepts an L<Amazon::S3::Bucket> object and uses its
bucket name and region.

The hash-reference form accepts:

=over 4

=item bucket

Required. Bucket name.

=item region

Region containing the bucket.

If omitted, C<get_bucket_location()> is called to determine the
region.

=item headers

Optional hash reference containing additional request headers.

=back

The bucket must be empty before Amazon S3 will delete it.

Returns a true value on success.

On failure, returns C<undef> and records error information on the
client.

=head3 delete_public_access_block

  my $response = $s3->delete_public_access_block($bucket);

Removes the public access block configuration from a bucket.

The argument is expected to be an L<Amazon::S3::Bucket> object.

The method performs the C<DeletePublicAccessBlock> operation through
the L<Amazon::S3::BucketV2> interface and returns that operation's
result.

This operation may be required before applying public ACLs or public
bucket policies to buckets whose public access block settings prohibit
them.

=head3 get_bucket_location

  my $region = $s3->get_bucket_location($bucket_name);

  my $region = $s3->get_bucket_location($bucket);

Returns the region containing a bucket.

The argument may be a bucket name or an L<Amazon::S3::Bucket> object.

For a bucket name, a temporary L<Amazon::S3::Bucket> object is
constructed and its C<get_location_constraint()> method is called.

Amazon S3 represents C<us-east-1> with a null location constraint.
When the bucket location call returns no region,
C<get_bucket_location()> returns C<us-east-1>.

=head3 list_directory_buckets

  my $response = $s3->list_directory_buckets;

  my $response = $s3->list_directory_buckets(
    { uri_params => \%params,
    }
  );

Lists directory buckets owned by the account.

The optional C<uri_params> hash reference is passed as URI parameters
to the S3 Express control endpoint.

The method temporarily switches the client to the S3 Express control
endpoint for the request and restores the previous express-mode state
afterward.

On success, returns the parsed S3 response.

On failure, returns C<undef> and records error information on the
client.

See L</DIRECTORY BUCKETS>.

=head2 OBJECT LISTING AND VERSIONING

=head3 list_bucket

  my $response = $s3->list_bucket(\%parameters);

Lists objects using the original S3 ListObjects API.

The argument is a hash reference. C<bucket> is required. Other defined
entries are sent as ListObjects query parameters.

Common parameters are:

=over 4

=item bucket

Required. Bucket name.

=item delimiter

Optional delimiter used to group matching keys into common prefixes.

=item headers

Optional hash reference containing additional request headers.

=item marker

Optional key after which listing should resume.

=item max-keys

Optional maximum number of results returned by S3.

=item prefix

Optional prefix used to restrict returned keys.

=back

On success, returns the normalized listing structure described in
L</LISTING OBJECTS>.

On failure, returns C<undef> and records error information on the
client.

See L</LISTING OBJECTS>.
=head3 list_bucket_all

  my $response = $s3->list_bucket_all(\%parameters);

Lists all matching objects using the original ListObjects API.

The accepted parameters are the same as for C<list_bucket()>.

The method follows pagination automatically and can therefore make
multiple S3 requests.

On success, returns the combined normalized listing result.

On a pagination failure, the method throws an exception.

See L</LISTING OBJECTS>.
=head3 list_bucket_all_v2

  my $response = $s3->list_bucket_all_v2(\%parameters);

Lists all matching objects using ListObjectsV2.

The accepted parameters are the same as for C<list_bucket_v2()>.

The method follows pagination automatically and can therefore make
multiple S3 requests.

On success, returns the combined normalized listing result.

On a pagination failure, the method throws an exception.

See L</LISTING OBJECTS>.
=head3 list_bucket_v2

  my $response = $s3->list_bucket_v2(\%parameters);

Lists objects using the S3 ListObjectsV2 API.

The argument is a hash reference. C<bucket> is required. Other defined
entries are sent as ListObjectsV2 query parameters.

Common parameters are:

=over 4

=item bucket

Required. Bucket name.

=item continuation-token

Optional continuation token returned by a previous ListObjectsV2
request.

=item delimiter

Optional delimiter used to group matching keys into common prefixes.

=item encoding-type

Optional S3 response encoding type.

=item fetch-owner

Optional boolean controlling whether owner information is returned.

=item headers

Optional hash reference containing additional request headers.

=item marker

Compatibility alias for C<continuation-token>.

=item max-keys

Optional maximum number of results returned by S3.

=item prefix

Optional prefix used to restrict returned keys.

=item start-after

Optional key after which S3 should begin the listing.

=back

On success, returns the normalized listing structure described in
L</LISTING OBJECTS>.

On failure, returns C<undef> and records error information on the
client.

See L</LISTING OBJECTS>.
=head3 list_object_versions

  my $response = $s3->list_object_versions(\%parameters);

Lists object versions in a bucket.

The argument is a hash reference.

=over 4

=item bucket

Required. Bucket name.

This operation is not available for directory buckets.

=item delimiter

Optional delimiter used to group matching keys.

=item encoding-type

Optional S3 response encoding type.

=item headers

Optional hash reference containing additional request headers.

=item key-marker

Optional key marker used when continuing a paginated listing.

=item max-keys

Optional maximum number of results returned by S3.

The S3 default is 1000.

=item prefix

Optional prefix used to restrict returned keys.

=item version-id-marker

Optional version ID marker used with C<key-marker> when continuing a
paginated listing.

=back

On success, returns the parsed ListObjectVersions service response.
This method does not automatically follow pagination.

On failure, returns C<undef> and records error information on the
client.

See L</LISTING OBJECTS> and
L<https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectVersions.html>.
=head2 ADVANCED AND COMPATIBILITY METHODS

=head3 turn_off_special_retry

  $s3->turn_off_special_retry;

Removes the additional HTTP 400 retry condition installed by
C<turn_on_special_retry()>.

When retry handling is disabled, this method has no effect.

This method exists primarily for internal and compatibility use.

=head3 turn_on_special_retry

  $s3->turn_on_special_retry;

When retry handling is enabled, adds HTTP 400 to the conditions
handled by the retry-aware user agent.

This behavior exists because some S3 request timeouts have historically
been returned as HTTP 400 responses.

The constructor calls this method automatically.

When retry handling is disabled, this method has no effect.

This method exists primarily for internal and compatibility use.

=head1 LOGGING AND DEBUGGING

Logging is controlled by the configured logger and logging level.

When no logger is supplied, C<Amazon::S3::Logger> is used.

Valid levels include:

  fatal
  error
  warn
  info
  debug
  trace

The default level is C<error>.

At C<debug> level, C<Amazon::S3> records higher-level request and
configuration information.

At C<trace> level, HTTP request and response information may also be
logged.

Applications should review trace output before retaining or sharing
it. Request and response data may contain sensitive application
information even when authentication values are sanitized.

=head1 S3-COMPATIBLE SERVICES

C<Amazon::S3> can be used with S3-compatible services and local S3
implementations by configuring the service endpoint and related
connection options.

The C<host>, C<secure>, and C<dns_bucket_names> settings are commonly
relevant when using a non-AWS endpoint.

S3-compatible implementations may differ from AWS in supported APIs,
request validation, checksum behavior, or edge cases.

The integration tests used during development include LocalStack, but
applications targeting another S3-compatible implementation should
test against that implementation directly.

=head1 COMPARISON TO OTHER PERL S3 MODULES

Perl applications have several choices for accessing Amazon S3,
including L<Net::Amazon::S3>, L<Paws::S3>, L<Amazon::S3::Lite>, and
L<Amazon::API::S3>. Each takes a different approach.

C<Amazon::S3> provides a dedicated S3 interface with a long-established
API. The distribution combines the account-level C<Amazon::S3>
interface with L<Amazon::S3::Bucket> for common object workflows and
L<Amazon::S3::BucketV2> for broader low-level API access.

C<Net::Amazon::S3> is the project from which C<Amazon::S3> originally
forked. The distributions have since diverged and should not be
considered drop-in replacements for one another.

C<Paws::S3> is part of the larger L<Paws> AWS SDK for Perl and follows
AWS service APIs through its generated service model.

L<Amazon::S3::Lite> is a smaller client intended for applications
where dependency size and startup cost are important.

L<Amazon::API::S3> is generated from the AWS Botocore service model
and is intended to closely reflect the current low-level S3 API.

The appropriate client depends primarily on the interface and level of
abstraction required by the application.

=head1 COMPATIBILITY AND LIMITATIONS

=head2 Minimum Perl Version

C<Amazon::S3> declares Perl 5.10 as its minimum supported Perl
version.

Dependencies may impose additional constraints on older Perl
installations.

Applications using an older Perl should run the complete distribution
test suite after installation.

=head2 Signature Version 4

AWS API requests are signed using Signature Version 4.

Signature Version 2 is not supported.

Because Signature Version 4 includes the AWS region in the signature,
bucket operations must use the region containing the bucket.

A bucket region can be supplied explicitly or determined using bucket
region verification.

=head2 Directory Buckets

Directory bucket support is currently limited to account-level create
and list operations.

See L</DIRECTORY BUCKETS>.

=head1 TESTING

The distribution includes unit tests and integration tests that
exercise behavior requiring an S3 endpoint.

Run the normal distribution test suite with:

  make test

Integration testing during development includes LocalStack.

See F<README-TESTING.md> in the distribution root for test
environment setup, integration-test requirements, and additional
testing instructions.

=head1 SUPPORT

Bug reports and feature requests should be submitted through the
project issue tracker.

When reporting a problem, include the C<Amazon::S3> version, Perl
version, operating system, and enough information to reproduce the
behavior.

For request or protocol problems, debug or trace logging may also be
useful. Review logs before sharing them to ensure that they do not
contain credentials, authorization information, or sensitive object
data.

=head1 REPOSITORY

The source repository, issue tracker, and development history are
available at:

L<https://github.com/rlauer6/Amazon-S3>

=head1 AUTHOR

Original author: Timothy Appnel <tima@cpan.org>

Current maintainer: Rob Lauer <bigfoot@cpan.org>

=head1 SEE ALSO

L<Amazon::S3::Bucket>

L<Amazon::S3::BucketV2>

L<Amazon::S3::Constants>

L<Amazon::S3::Logger>

L<Amazon::Credentials>

L<Net::Amazon::S3>

L<Amazon S3 API Reference|https://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html>

L<Amazon S3 bucket naming rules|https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html>

L<Amazon S3 bucket restrictions and limitations|https://docs.aws.amazon.com/AmazonS3/latest/userguide/BucketRestrictions.html>

L<AWS Signature Version 4|https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-authenticating-requests.html>

L<Amazon S3 directory buckets|https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-buckets-overview.html>

L<LocalStack|https://localstack.io>

=head1 LICENCE

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

Portions of this distribution contain code modified from Amazon. That
code is made available under the following notice:

  #  This software code is made available "AS IS" without warranties of any
  #  kind.  You may copy, display, modify and redistribute the software
  #  code either by itself or as incorporated into your code; provided that
  #  you do not remove any proprietary notices.  Your use of this software
  #  code is at your own risk and you waive any claim against Amazon
  #  Digital Services, Inc. or its affiliates with respect to your use of
  #  this software code. (c) 2006 Amazon Digital Services, Inc. or its
  #  affiliates.

=cut
