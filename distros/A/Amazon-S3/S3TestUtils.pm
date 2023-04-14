package S3TestUtils;

use strict;
use warnings;

use Data::Dumper;
use English    qw(-no_match_vars);
use List::Util qw(any);
use Readonly;
use Test::More;

use parent qw(Exporter);

# chars
Readonly our $EMPTY => q{};
Readonly our $SLASH => q{/};

# booleans
Readonly our $TRUE  => 1;
Readonly our $FALSE => 0;

# mocking services
Readonly our $DEFAULT_LOCAL_STACK_HOST => 'localhost:4566';
Readonly our $DEFAULT_MINIO_HOST       => 'localhost:9000';

# http codes
Readonly our $HTTP_OK        => '200';
Readonly our $HTTP_FORBIDDEN => '403';
Readonly our $HTTP_CONFLICT  => '409';

# misc
Readonly our $TEST_BUCKET_PREFIX => 'net-amazon-s3-test';

# create a domain name for this if AMAZON_S3_DNS_BUCKET_NAMES is true
Readonly our $MOCK_SERVICES_BUCKET_NAME => $TEST_BUCKET_PREFIX . '-test';

Readonly our $PUBLIC_READ_POLICY => <<END_OF_POLICY;
<Grant>
    <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:type="Group">
        <URI>http://acs.amazonaws.com/groups/global/AllUsers</URI>
    </Grantee>
    <Permission>READ</Permission>
</Grant>
END_OF_POLICY

our %EXPORT_TAGS = (
  constants => [
    qw(
      $EMPTY
      $SLASH
      $TRUE
      $FALSE
      $DEFAULT_LOCAL_STACK_HOST
      $HTTP_OK
      $HTTP_CONFLICT
      $HTTP_FORBIDDEN
      $TEST_BUCKET_PREFIX
      $MOCK_SERVICES_BUCKET_NAME
      $PUBLIC_READ_POLICY
    )
  ],
  subs => [
    qw(
      add_keys
      check_test_bucket
      create_bucket
      get_s3_service
      is_aws
      make_bucket_name
      set_s3_host
    )
  ],
);

our @EXPORT_OK = map { @{ $EXPORT_TAGS{$_} } } ( keys %EXPORT_TAGS );

########################################################################
sub make_bucket_name {
########################################################################
  return $MOCK_SERVICES_BUCKET_NAME
    if !is_aws();

  my $suffix = eval {
    require Data::UUID;

    return lc Data::UUID->new->create_str();
  };

  $suffix //= join $EMPTY, map { ( 'A' .. 'Z', 'a' .. 'z', 0 .. 9 )[$_] }
    map { int rand 62 } ( 0 .. 15 );

  my $bucket_name = sprintf '%s-%s', $TEST_BUCKET_PREFIX, $suffix;

  return $bucket_name;
}

########################################################################
sub is_aws {
########################################################################
  return ( $ENV{AMAZON_S3_LOCALSTACK} || $ENV{AMAZON_S3_MINIO} )
    ? $FALSE
    : $TRUE;
}

########################################################################
sub check_test_bucket {
########################################################################
  my ($s3) = @_;

  # list all buckets that I own
  my $response = eval { return $s3->buckets; };

  if ( $EVAL_ERROR || !$response ) {
    diag(
      Dumper( [ error => [ $response, $s3->err, $s3->errstr, $s3->error ] ] )
    );

    BAIL_OUT($EVAL_ERROR);
  }

  my ( $owner_id, $owner_displayname )
    = @{$response}{qw(owner_id owner_displayname)};

  my $bucket_name = make_bucket_name();

  my @buckets = map { $_->{bucket} } @{ $response->{buckets} };

  if ( any { $_ =~ /$bucket_name/xsm } @buckets ) {
    BAIL_OUT( 'test bucket already exists: ' . $bucket_name );
  }

  return ( $owner_id, $owner_displayname );
}

########################################################################
sub set_s3_host {
########################################################################
  my $host = $ENV{AMAZON_S3_HOST};

  $host //= 's3.amazonaws.com';

  ## no critic (RequireLocalizedPunctuationVars)

  if ( exists $ENV{AMAZON_S3_LOCALSTACK} ) {

    $host //= $DEFAULT_LOCAL_STACK_HOST;

    $ENV{AWS_ACCESS_KEY_ID} = 'test';

    $ENV{AWS_SECRET_ACCESS_KEY} = 'test';

    $ENV{AMAZON_S3_EXPENSIVE_TESTS} = $TRUE;

    $ENV{AMAZON_S3_SKIP_PERMISSIONS} = $TRUE;
  }
  elsif ( exists $ENV{AMAZON_S3_MINIO} ) {

    $host //= $DEFAULT_MINIO_HOST;

    $ENV{AMAZON_S3_SKIP_ACLS} = $TRUE;

    $ENV{AMAZON_S3_EXPENSIVE_TESTS} = $TRUE;

    $ENV{AMAZON_S3_SKIP_REGION_CONSTRAINT_TEST} = $TRUE;
  }

  return $host;
}

########################################################################
sub get_s3_service {
########################################################################
  my ($host) = @_;

  my $s3 = eval {

    if ( $ENV{AMAZON_S3_CREDENTIALS} ) {
      require Amazon::Credentials;

      return Amazon::S3->new(
        { credentials      => Amazon::Credentials->new,
          host             => $host,
          secure           => is_aws(),
          dns_bucket_names => $ENV{AMAZON_S3_DNS_BUCKET_NAMES},
          level            => $ENV{DEBUG} ? 'trace' : 'error',
        }
      );

    }
    else {
      return Amazon::S3->new(
        { aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
          aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
          token                 => $ENV{AWS_SESSION_TOKEN},
          host                  => $host,
          secure                => is_aws(),
          dns_bucket_names      => $ENV{AMAZON_S3_DNS_BUCKET_NAMES},
          level                 => $ENV{DEBUG} ? 'trace' : 'error',
        }
      );
    }
  };

  return $s3;
}

########################################################################
sub create_bucket {
########################################################################
  my ( $s3, $bucket_name ) = @_;

  $bucket_name = $SLASH . $bucket_name;

  my $bucket_obj
    = eval { return $s3->add_bucket( { bucket => $bucket_name } ); };

  return $bucket_obj;
}

########################################################################
sub add_keys {
########################################################################
  my ( $bucket_obj, $max_keys, $prefix ) = @_;

  $prefix //= q{};

  foreach my $key ( 1 .. $max_keys ) {
    my $keyname = sprintf '%stesting-%02d.txt', $prefix, $key;
    my $value   = 'T';

    $bucket_obj->add_key( $keyname, $value );
  }

  return $max_keys;
}

1;
