#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib qw(lib);

use English qw{-no_match_vars};

use Test::More;
use Test::Output;

plan tests => 12;

use_ok('Amazon::S3');

########################################################################
sub test_levels {
########################################################################
  my ($s3) = @_;

  print {*STDERR} "\n---[" . $s3->level . "]---\n";

  $s3->get_logger->trace("test trace\n");
  $s3->get_logger->debug("test debug\n");
  $s3->get_logger->info("test info\n");
  $s3->get_logger->warn("test warn\n");
  $s3->get_logger->error("test error\n");
  $s3->get_logger->fatal("test fatal\n");

  return;
} ## end sub test_levels

########################################################################
sub test_all_levels {
########################################################################
  my ($s3) = @_;

  $s3->level('trace');
  stderr_like( sub { test_levels($s3); },
    qr/trace\n.*debug\n.*info\n.*warn\n.*error\n.*fatal\n/xsm, 'trace' );

  $s3->level('debug');
  stderr_like( sub { test_levels($s3); },
    qr/debug\n.*info\n.*warn\n.*error\n.*fatal\n/xsm, 'debug' );
  stderr_unlike( sub { test_levels($s3); },
    qr/trace/, 'debug - not like trace' );

  $s3->level('info');
  stderr_like( sub { test_levels($s3); },
    qr/info\n.*warn\n.*error\n.*fatal\n/xsm, 'info' );
  stderr_unlike( sub { test_levels($s3); },
    qr/trace|debug/, 'info - not like trace, debug' );

  $s3->level('warn');
  stderr_like( sub { test_levels($s3); },
    qr/warn\n.*error\n.*fatal\n/xsm, 'warn' );
  stderr_unlike( sub { test_levels($s3); },
    qr/trace|debug|info/, 'warn - not like trace, debug, info' );

  $s3->level('error');
  stderr_like( sub { test_levels($s3); }, qr/error\n.*fatal\n/xsm, 'error' );
  stderr_unlike( sub { test_levels($s3); },
    qr/trace|debug|info|warn/, 'error - not like trace, debug, info, warn' );

  $s3->level('fatal');
  stderr_like( sub { test_levels($s3); }, qr/fatal\n/xsm, 'fatal' );
  stderr_unlike(
    sub { test_levels($s3); },
    qr/trace|debug|info|warn|error/,
    'fatal - not like trace, debug, info, warn, error'
  );

} ## end sub test_all_levels

########################################################################

my $s3 = Amazon::S3->new(
  { aws_access_key_id     => 'test',
    aws_secret_access_key => 'test',
  }
);

test_all_levels($s3);

