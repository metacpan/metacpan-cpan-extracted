#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Copy;
use File::Path qw(make_path);
use File::Spec;
use File::Temp;
use FindBin qw($Bin);
use Test::More;

use_ok(qw(DarkPAN::Indexer));

########################################################################
subtest 'update_index requires existing index' => sub {
########################################################################
  my $root = File::Temp->newdir;

  make_path "$root/authors/id";

  my $share = File::Spec->catdir( $Bin, '..', 'share' );
  my $source = File::Spec->catfile( $share, 'Foo-1.0.0.tar.gz' );

  ok( -e $source, 'Foo 1.0.0 fixture exists' )
    or BAIL_OUT("$source does not exist");

  my $distribution = 'authors/id/Foo-1.0.0.tar.gz';
  my $destination  = File::Spec->catfile( "$root", $distribution );

  copy $source, $destination
    or BAIL_OUT("could not copy $source to $destination: $OS_ERROR");

  my $index_key      = 'modules/packages.db.gz';
  my $packages_index = File::Spec->catfile( "$root", $index_key );

  ok( !-e $packages_index, 'packages index does not exist initially' );

  my $indexer = DarkPAN::Indexer->new(
    config => {
      storage                => { type => 'Filesystem', root => "$root" },
      format                 => { type => 'SQLite' },
      packages_version_index => $index_key,
    }
  );

  local $EVAL_ERROR;

  my $result = eval {
    return $indexer->update_index(
      distribution => $distribution,
    );
  };

  my $error = $EVAL_ERROR;

  diag $error if $error;

  ok( !$result, 'update_index failed without an existing index' );
  ok( $error, 'update_index reported an error' );
  ok( !-e $packages_index, 'update_index did not create packages index' );

  my $guard = eval {
    return $indexer->get_storage->lock($index_key);
  };

  ok( $guard, 'lock was released after failed update' );
};

done_testing;

1;
