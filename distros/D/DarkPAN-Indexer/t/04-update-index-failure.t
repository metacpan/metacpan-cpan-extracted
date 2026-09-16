#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::More;

use DarkPAN::Indexer;

########################################################################
sub slurp_file {
########################################################################
  my ($file) = @_;

  local $RS = undef;

  open my $fh, '<', $file
    or die "ERROR: could not open $file for reading\n$OS_ERROR";

  binmode $fh;
  my $content = <$fh>;

  close $fh
    or die "ERROR: could not close $file\n$OS_ERROR";

  return $content;
}

my $root = tempdir( CLEANUP => 1 );
make_path "$root/authors/id";

my $share   = File::Spec->catdir( $Bin, '..', 'share' );
my $foo_100 = File::Spec->catfile( $share, 'Foo-1.0.0.tar.gz' );

ok( -f $foo_100, 'Foo 1.0.0 fixture exists' );

my $distribution = 'authors/id/Foo-current.tar.gz';
my $dist_file    = "$root/$distribution";

copy $foo_100, $dist_file
  or die "ERROR: could not copy $foo_100\n$OS_ERROR";

my $indexer = DarkPAN::Indexer->new(
  config => {
    storage                => { type => 'Filesystem', root => $root },
    format                 => { type => 'SQLite' },
    packages_version_index => 'modules/packages.db.gz',
  }
);

my $packages_index = "$root/modules/packages.db.gz";
my $index_key      = 'modules/packages.db.gz';

########################################################################
subtest 'failed update preserves published index' => sub {
########################################################################
  my $stats = $indexer->create_index;

  is( $stats->{distributions_indexed}, 1, 'created initial index' );
  ok( -f $packages_index, 'initial packages index exists' );

  my $before = slurp_file($packages_index);

  unlink $dist_file
    or die "ERROR: could not remove $dist_file\n$OS_ERROR";

  local $EVAL_ERROR;
  my $ok = eval {
    $indexer->update_index( distribution => $distribution );
    return 1;
  };

  my $error = $EVAL_ERROR;
  diag $error if $error;

  ok( !$ok, 'update_index failed when distribution could not be fetched' );
  like( $error, qr/could not fetch \Q$distribution\E/, 'update_index reported fetch failure' );

  my $after = slurp_file($packages_index);

  is( $after, $before, 'failed update did not alter published packages index' );

  my $guard = $indexer->get_storage->lock($index_key);
  ok( $guard, 'lock was released after failed update' );
};

done_testing;

1;
