#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempfile tempdir);
use FindBin qw($Bin);
use IO::Uncompress::Gunzip qw(gunzip);
use Test::More;

use DarkPAN::Indexer;

########################################################################
sub open_database {
########################################################################
  my ($packages_index) = @_;

  local $RS = undef;

  open my $fh, '<', $packages_index
    or die "ERROR: could not open $packages_index for reading\n$OS_ERROR";

  binmode $fh;

  my $compressed_db = <$fh>;
  close $fh;

  my $db = q{};
  gunzip( \$compressed_db, \$db )
    or die "ERROR: could not gunzip $packages_index\n";

  my ( $out_fh, $database ) = tempfile( UNLINK => 0, DIR => '/tmp' );
  binmode $out_fh;
  print {$out_fh} $db;
  close $out_fh;

  my $dbh = DBI->connect(
    "dbi:SQLite:dbname=$database",
    q{}, q{},
    { AutoCommit => 1,
      RaiseError => 1,
      PrintError => 0,
    }
  );

  return ( $dbh, $database );
}

########################################################################
sub rows_for_distribution {
########################################################################
  my ( $packages_index, $distribution ) = @_;

  my ( $dbh, $database ) = open_database($packages_index);

  my $rows = $dbh->selectall_arrayref(
    q{
      SELECT module, version
      FROM modules
      WHERE distribution = ?
      ORDER BY module, version
    },
    undef,
    $distribution,
  );

  $dbh->disconnect;
  unlink $database;

  return $rows;
}

my $root = tempdir( CLEANUP => 1 );
make_path "$root/authors/id";

my $share   = File::Spec->catdir( $Bin, '..', 'share' );
my $foo_100 = File::Spec->catfile( $share, 'Foo-1.0.0.tar.gz' );
my $foo_101 = File::Spec->catfile( $share, 'Foo-1.0.1.tar.gz' );

ok( -f $foo_100, 'Foo 1.0.0 fixture exists' );
ok( -f $foo_101, 'Foo 1.0.1 fixture exists' );

my $current_key = 'authors/id/Foo-current.tar.gz';
my $other_key   = 'authors/id/Foo-other.tar.gz';

copy $foo_100, "$root/$current_key"
  or die "ERROR: could not copy $foo_100\n$OS_ERROR";
copy $foo_100, "$root/$other_key"
  or die "ERROR: could not copy $foo_100\n$OS_ERROR";

my $indexer = DarkPAN::Indexer->new(
  config => {
    storage                => { type => 'Filesystem', root => $root },
    format                 => { type => 'SQLite' },
    packages_version_index => 'modules/packages.db.gz',
  }
);

my $packages_index = "$root/modules/packages.db.gz";

########################################################################
subtest 'update_index replaces only the requested distribution' => sub {
########################################################################
  my $stats = $indexer->create_index;

  is( $stats->{distributions_indexed}, 2, 'created index from both distributions' );

  is_deeply(
    rows_for_distribution( $packages_index, $current_key ),
    [ [ 'Foo', 'v1.0.0' ] ],
    'current distribution initially indexes Foo 1.0.0',
  );

  is_deeply(
    rows_for_distribution( $packages_index, $other_key ),
    [ [ 'Foo', 'v1.0.0' ] ],
    'unrelated distribution initially indexes Foo 1.0.0',
  );

  copy $foo_101, "$root/$current_key"
    or die "ERROR: could not replace $current_key\n$OS_ERROR";

  $indexer->update_index( distribution => $current_key );

  is_deeply(
    rows_for_distribution( $packages_index, $current_key ),
    [ [ 'Foo', 'v1.0.1' ] ],
    'updated distribution was re-fetched and replaced with Foo 1.0.1',
  );

  is_deeply(
    rows_for_distribution( $packages_index, $other_key ),
    [ [ 'Foo', 'v1.0.0' ] ],
    'update preserved rows for unrelated distribution',
  );
};

########################################################################
subtest 'delete_from_index removes only the requested distribution' => sub {
########################################################################
  $indexer->delete_from_index( distribution => $other_key );

  is_deeply(
    rows_for_distribution( $packages_index, $other_key ),
    [],
    'deleted distribution has no remaining rows',
  );

  is_deeply(
    rows_for_distribution( $packages_index, $current_key ),
    [ [ 'Foo', 'v1.0.1' ] ],
    'delete preserved rows for unrelated distribution',
  );
};

done_testing;

1;
