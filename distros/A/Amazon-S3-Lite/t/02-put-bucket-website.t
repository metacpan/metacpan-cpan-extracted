#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(-no_match_vars);
use HTTP::Tiny;
use Test::More;
use Amazon::S3::Lite;

if ( !$ENV{TEST_LOCALSTACK} ) {
  plan skip_all => 'no localstack';
}

########################################################################
sub get_s3 {
########################################################################
  my $credentials = eval { require Amazon::Credentials; return Amazon::Credentials->new; };

  return eval {

    if ( !$credentials ) {
      die "ERROR: Unable to find source for credentials\n"
        if !$credentials && ( !$ENV{AWS_ACCESS_KEY_ID} || !$ENV{AWS_SECRET_ACCESS_KEY} );
    }

    return Amazon::S3::Lite->new(
      { region => 'us-east-1',
        $credentials
        ? ( credential => $credentials )
        : (
          aws_access_key_id     => $ENV{AWS_ACCESS_KEY_ID},
          aws_secret_access_key => $ENV{AWS_SECRET_ACCESS_KEY},
          $ENV{SESSION_TOKEN} ? ( token => $ENV{SESSION_TOKEN} ) : (),
        ),
      }
    );
  };
}

########################################################################
sub upload_index {
########################################################################
  my ( $s3, $bucket ) = @_;

  my $index = <<'END_OF_INDEX';
<html>
Hello World!
</html>
END_OF_INDEX

  $s3->put_object( $bucket, 'index.html', $index, 'Content-type' => 'text/html' );

  return;
}

my $s3 = get_s3() or do {
  BAIL_OUT("could not instantiate an Amazon::S3::Lite object: $EVAL_ERROR");
};

my $bucket = $ENV{WEBSITE_BUCKET} or do {
  BAIL_OUT("set WEBSITE_BUCKET to valid domain name (Ex: foo.my-domain.com)\n");
};

########################################################################
subtest 'put-website-bucket' => sub {
########################################################################

  ok( eval { $s3->create_bucket($bucket); } ) or do {
    BAIL_OUT("Could not create bucket $bucket: $EVAL_ERROR");
  };

  ok( eval { $s3->put_bucket_website($bucket); } ) or do {
    BAIL_OUT("Could not create bucket website: $EVAL_ERROR");
  };

  upload_index( $s3, $bucket );

  my $response = eval { HTTP::Tiny->new->get( sprintf 'http://%s/index.html', $bucket ); };
  ok( $response && $response->{success} && $response->{content} =~ /hello\sworld/sxmi )
    or do {
    diag( Dumper( [ response => $response ] ) );
    };

  $s3->delete_object( $bucket, 'index.html' );

  $s3->delete_bucket($bucket);
};

done_testing;
