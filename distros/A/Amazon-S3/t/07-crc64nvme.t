#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use Test::More;
use Digest::CRC64NVME;

########################################################################
subtest 'add' => sub {
########################################################################
  my $ctx = Digest::CRC64NVME->new;

  $ctx->add('123456789');

  is( uc( $ctx->hexdigest ), 'AE8B14860A799888', 'digest calculated correctly: AE8B14860A799888' );
};

########################################################################
subtest 'incremental' => sub {
########################################################################
  my $ctx = Digest::CRC64NVME->new;

  $ctx->add('123456789');

  is( $ctx->hexdigest, 'AE8B14860A799888', 'digest calculated correctly', );

  $ctx->add('1234');
  $ctx->add('56789');

  is( $ctx->hexdigest, 'AE8B14860A799888', 'incremental digest calculated correctly', );

  $ctx->add('1234')->add('56789');

  is( $ctx->hexdigest, 'AE8B14860A799888', 'chained incremental digest calculated correctly', );

  my $digest = Digest::CRC64NVME->new('123456789')->digest;

  is( uc( unpack 'H*', $digest ), 'AE8B14860A799888', 'binary digest calculated correctly', );
};

########################################################################
subtest 'addfile' => sub {
########################################################################
  my ( $fh, $filename ) = tempfile();

  binmode $fh;

  print {$fh} '123456789'
    or die "Could not write $filename: $OS_ERROR";

  seek $fh, 0, 0
    or die "Could not seek $filename: $OS_ERROR";

  my $ctx = Digest::CRC64NVME->new;

  $ctx->addfile($fh);

  is( $ctx->hexdigest, 'AE8B14860A799888', 'file digest calculated correctly', );

  close $fh
    or die "Could not close $filename: $OS_ERROR";
};

done_testing;

1;
