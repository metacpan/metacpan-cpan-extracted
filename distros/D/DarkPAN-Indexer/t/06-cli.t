#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use File::Path qw(mkpath);
use File::Copy;
use Path::Tiny;
use File::Temp qw(tempfile);
use JSON;
use Test::Output;

use_ok('DarkPAN::Indexer::CLI');
use_ok('DarkPAN::Indexer');

########################################################################
subtest 'index' => sub {
########################################################################
  # real filesystem darkpan in a tempdir (as 02/04 do)
  my $root = Path::Tiny->tempdir;
  mkpath "$root/authors/id/M/MI/MIYAGAWA";

  copy 't/dat/Acme-YakiniQ-0.01.tar.gz', "$root/authors/id/M/MI/MIYAGAWA";

  my ( $fh, $config_file ) = tempfile( DIR => '/tmp', UNLINK => 1, SUFFIX => '.json' );

  print {$fh} JSON->new->pretty->encode(
    { storage                => { type => 'Filesystem', root => "$root" },
      format                 => { type => 'SQLite' },
      packages_version_index => 'modules/packages.db.gz'
    }
  );

  close $fh;

  local @ARGV = ( '--config', $config_file, 'index-darkpan' );

  # construct the CLI with options set directly (no @ARGV simulation)
  my $cli = DarkPAN::Indexer::CLI->new(
    option_specs    => [qw(config|c=s)],
    default_options => {},
    extra_options   => [qw(indexer)],
    commands        => { 'index-darkpan' => \&DarkPAN::Indexer::CLI::cmd_index_darkpan },
  );

  stdout_like( sub { $cli->run }, qr/indexed 1/, 'indexed 1 distribution' );

  ok -f "$root/modules/packages.db.gz", 'CLI index built the db';
};

done_testing;

1;
