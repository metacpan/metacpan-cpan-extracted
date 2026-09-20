use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use Test::More;

our $TRUE         = 1;
our $FALSE        = 0;
our $DEFAULT_HOST = 's3.amazonaws.com';

use_ok(qw(Amazon::S3));

########################################################################
subtest 'endpoint_url' => sub {
########################################################################
  my %options = (
    endpoint_url          => 'http://localhost:4566',
    aws_access_key_id     => 'test',
    aws_secret_access_key => 'test',
  );

  my $s3 = Amazon::S3->new(%options);

  is( $s3->host, 'localhost:4566', 'host' );

  ok( !$s3->secure, 'secure' );
};

########################################################################
subtest 'endpoint_url and host' => sub {
########################################################################
  my %options = (
    endpoint_url          => 'http://localhost:4566',
    aws_access_key_id     => 'test',
    aws_secret_access_key => 'test',
    host                  => 'localstack:4566',
  );

  my $s3 = eval { Amazon::S3->new(%options); };

  like( $EVAL_ERROR, qr/error/i, 'throws' );
};

########################################################################
subtest 'default host' => sub {
########################################################################
  my %options = (
    aws_access_key_id     => 'test',
    aws_secret_access_key => 'test',
  );

  my $s3 = eval { Amazon::S3->new(%options); };

  is( $s3->host, 's3.us-east-1.amazonaws.com', 'default host' );
};

done_testing;

1;
