#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use HTTP::Headers;
use HTTP::Response;
use MIME::Base64 qw(encode_base64);

use Test::More;

use Amazon::S3;

########################################################################
subtest 'checksum capabilities' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  is( $s3->checksum_algorithm, 'crc64nvme', 'default checksum algorithm is crc64nvme', );

  ok( $s3->verify_checksums, 'checksum verification enabled by default', );

  my $checksum_types = $s3->checksum_types;

  ok( exists $checksum_types->{crc64nvme}, 'crc64nvme implementation is available', );

  my $digest = $checksum_types->{crc64nvme}->( data => '123456789', );

  is( uc( unpack 'H*', $digest ), 'AE8B14860A799888', 'crc64nvme capability produces correct digest', );
};

########################################################################
subtest 'capabilities independent of verification' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
      verify_checksums      => 0,
    }
  );

  ok( !$s3->verify_checksums, 'checksum verification disabled', );

  ok( exists $s3->checksum_types->{crc64nvme}, 'crc64nvme capability remains available', );
};

########################################################################
subtest 'add_key sends crc64nvme checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  my $request;

  {
    no warnings 'redefine';

    local *Amazon::S3::send_request_expect_nothing = sub {
      my ( $self, $args ) = @_;

      $request = $args;

      return 1;
    };

    ok( $bucket->add_key( 'test-key', '123456789' ), 'add_key succeeds', );
  }

  ok( defined $request, 'request captured', );

  is( $request->{headers}->{'x-amz-checksum-crc64nvme'}, 'rosUhgp5mIg=', 'crc64nvme checksum header is correct', );

  is( $request->{data}, '123456789', 'request data is unchanged', );
};

########################################################################
subtest 'add_key file sends crc64nvme checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  my ( $fh, $filename ) = tempfile();

  binmode $fh;

  print {$fh} '123456789'
    or die "Could not write $filename: $OS_ERROR";

  close $fh
    or die "Could not close $filename: $OS_ERROR";

  my $request;

  {
    no warnings 'redefine';

    local *Amazon::S3::send_request_expect_nothing_probed = sub {
      my ( $self, $args ) = @_;

      $request = $args;

      return 1;
    };

    ok( $bucket->add_key( 'test-key', \$filename ), 'add_key file succeeds', );
  }

  ok( defined $request, 'request captured', );

  is( $request->{headers}->{'x-amz-checksum-crc64nvme'}, 'rosUhgp5mIg=', 'crc64nvme checksum header is correct', );

  isa_ok( $request->{data}, 'CODE', 'request data', );

  is( $request->{headers}->{'x-amz-content-sha256'}, 'UNSIGNED-PAYLOAD', 'file upload uses unsigned payload', );
};

########################################################################
subtest 'verify crc64nvme checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  ok(
    $bucket->_verify_checksums(
      checksums     => { crc64nvme => 'rosUhgp5mIg=', },
      checksum_type => 'FULL_OBJECT',
      data          => '123456789',
    ),
    'matching crc64nvme checksum verifies',
  );
};

########################################################################
subtest 'crc64nvme checksum mismatch' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  eval {
    $bucket->_verify_checksums(
      checksums     => { crc64nvme => 'AAAAAAAAAAA=', },
      checksum_type => 'FULL_OBJECT',
      data          => '123456789',
    );
  };

  like( $EVAL_ERROR, qr/Computed and response CRC64NVME checksums do not match/, 'checksum mismatch croaks', );
};

########################################################################
subtest 'composite checksum is not verified' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  ok(
    $bucket->_verify_checksums(
      checksums     => { crc64nvme => 'AAAAAAAAAAA=', },
      checksum_type => 'COMPOSITE',
      data          => '123456789',
    ),
    'composite checksum is skipped',
  );
};

########################################################################
subtest 'unsupported checksum is ignored' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  ok(
    $bucket->_verify_checksums(
      checksums     => { xxhash128 => 'not-a-real-checksum', },
      checksum_type => 'FULL_OBJECT',
      data          => '123456789',
    ),
    'unsupported checksum is skipped',
  );
};

########################################################################
subtest 'get_key requests checksum verification' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  my $request;

  {
    no warnings 'redefine';

    local *Amazon::S3::_make_request = sub {
      my ( $self, $args ) = @_;

      $request = $args;

      return $args;
    };

    local *Amazon::S3::_do_http = sub {
      return HTTP::Response->new(
        200, 'OK',
        HTTP::Headers->new(
          'Content-Length' => 9,
          'Content-Type'   => 'text/plain',
        ),
        '123456789',
      );
    };

    my $response = $bucket->get_key('test-key');

    ok( defined $response, 'get_key succeeds', );
  }

  is( $request->{headers}->{'x-amz-checksum-mode'}, 'ENABLED', 'checksum mode requested', );
};

########################################################################
subtest 'get_key rejects bad crc64nvme checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  {
    no warnings 'redefine';

    local *Amazon::S3::_make_request = sub {
      my ( $self, $args ) = @_;

      return $args;
    };

    local *Amazon::S3::_do_http = sub {
      return HTTP::Response->new(
        200, 'OK',
        HTTP::Headers->new(
          'Content-Length'           => 9,
          'Content-Type'             => 'text/plain',
          'x-amz-checksum-crc64nvme' => 'AAAAAAAAAAA=',
          'x-amz-checksum-type'      => 'FULL_OBJECT',
        ),
        '123456789',
      );
    };

    eval { $bucket->get_key('test-key'); };
  }

  like( $EVAL_ERROR, qr/Computed and response CRC64NVME checksums do not match/, 'get_key rejects checksum mismatch', );
};

########################################################################
subtest 'multipart crc64nvme initiation uses full object checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  my $request;

  {
    no warnings 'redefine';

    local *Amazon::S3::_make_request = sub {
      my ( $self, $args ) = @_;

      $request = $args;

      return $args;
    };

    local *Amazon::S3::_do_http = sub {
      return HTTP::Response->new( 200, 'OK', HTTP::Headers->new,
        '<InitiateMultipartUploadResult><UploadId>test-upload</UploadId></InitiateMultipartUploadResult>',
      );
    };

    my ( $id, $algorithm ) = $bucket->initiate_multipart_upload( 'test-key', { 'x-amz-checksum-algorithm' => 'CRC64NVME', }, );
    is( $id, 'test-upload', 'upload id returned', );

    is( $algorithm, 'crc64nvme', 'crc64nvme algorithm returned', );
  }

  is( $request->{headers}->{'x-amz-checksum-algorithm'}, 'CRC64NVME', 'crc64nvme checksum algorithm requested', );

  is( $request->{headers}->{'x-amz-checksum-type'}, 'FULL_OBJECT', 'full object checksum requested', );
};

my $checksum;

########################################################################
subtest 'multipart crc64nvme part sends checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  my $request;

  my $digest = $s3->checksum_types->{crc64nvme}->( data => '123456789', );

  my $expected_checksum = encode_base64( $digest, q{} );

  {
    no warnings 'redefine';

    local *Amazon::S3::_make_request = sub {
      my ( $self, $args ) = @_;

      $request = $args;

      return $args;
    };

    local *Amazon::S3::_do_http = sub {
      return HTTP::Response->new( 200, 'OK', HTTP::Headers->new( ETag => '"test-etag"', ), );
    };

    my $etag;

    ( $etag, $checksum ) = $bucket->upload_part_of_multipart_upload(
      { key       => 'test-key',
        id        => 'test-upload',
        part      => 1,
        data      => '123456789',
        algorithm => 'crc64nvme',
      }
    );

    is( $etag, 'test-etag', 'part etag returned' );
  }

  is( $request->{headers}{'x-amz-checksum-crc64nvme'}, $expected_checksum, 'crc64nvme part checksum sent', );

  is( $checksum, $expected_checksum, 'crc64nvme checksum returned', );
};

########################################################################
subtest 'multipart crc64nvme completion includes part checksum' => sub {
########################################################################
  my $xml = Amazon::S3::Bucket::_create_multipart_upload_request(
    { 1 => {
        etag     => 'test-etag',
        checksum => $checksum,
      },
    },
    'crc64nvme',
  );

  like( $xml, qr/<ETag>test-etag<\/ETag>/, 'etag included', );

  like( $xml, qr/<ChecksumCRC64NVME>/, 'crc64nvme part checksum included', );
};

########################################################################
subtest 'multipart sha256 initiation uses composite checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  my $request;

  {
    no warnings 'redefine';

    local *Amazon::S3::_make_request = sub {
      my ( $self, $args ) = @_;

      $request = $args;

      return $args;
    };

    local *Amazon::S3::_do_http = sub {
      return HTTP::Response->new( 200, 'OK', HTTP::Headers->new,
        '<InitiateMultipartUploadResult><UploadId>test-upload</UploadId></InitiateMultipartUploadResult>',
      );
    };

    my ( $id, $algorithm ) = $bucket->initiate_multipart_upload( 'test-key', { 'x-amz-checksum-algorithm' => 'SHA256', }, );

    is( $id, 'test-upload', 'upload id returned', );

    is( $algorithm, 'sha256', 'sha256 algorithm returned', );
  }

  is( $request->{headers}->{'x-amz-checksum-algorithm'}, 'SHA256', 'sha256 checksum algorithm requested', );

  ok( !exists $request->{headers}->{'x-amz-checksum-type'}, 'full object checksum not requested', );
};

########################################################################
subtest 'multipart sha256 part sends checksum' => sub {
########################################################################
  my $s3 = Amazon::S3->new(
    { aws_access_key_id     => 'test',
      aws_secret_access_key => 'test',
    }
  );

  my $bucket = $s3->bucket('test-bucket');

  my $request;

  {
    no warnings 'redefine';

    local *Amazon::S3::_make_request = sub {
      my ( $self, $args ) = @_;

      $request = $args;

      return $args;
    };

    local *Amazon::S3::_do_http = sub {
      return HTTP::Response->new( 200, 'OK', HTTP::Headers->new( ETag => '"test-etag"', ), );
    };

    my ( $etag, $checksum ) = $bucket->upload_part_of_multipart_upload(
      { key       => 'test-key',
        id        => 'test-upload',
        part      => 1,
        data      => '123456789',
        algorithm => 'sha256',
      }
    );

    is( $etag, 'test-etag', 'part etag returned', );

    is( $request->{headers}->{'x-amz-checksum-sha256'}, $checksum, 'sha256 part checksum sent', );

    ok( defined $checksum, 'sha256 checksum returned', );
  }
};
########################################################################
subtest 'multipart sha256 completion includes part checksum' => sub {
########################################################################
  my $xml = Amazon::S3::Bucket::_create_multipart_upload_request(
    { 1 => {
        etag     => 'test-etag',
        checksum => 'test-checksum',
      },
    },
    'sha256',
  );

  like( $xml, qr/<ETag>test-etag<\/ETag>/, 'etag included', );

  like( $xml, qr/<ChecksumSHA256>test-checksum<\/ChecksumSHA256>/, 'sha256 part checksum included', );
};

done_testing;

1;
