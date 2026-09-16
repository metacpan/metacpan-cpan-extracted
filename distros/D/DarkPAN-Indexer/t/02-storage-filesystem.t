#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp;
use File::Path qw(make_path);
use File::Basename qw(basename);
use File::Copy;
use File::Spec;
use FindBin qw($Bin);
use File::Temp qw(tempfile);
use IO::Uncompress::Gunzip qw(gunzip);
use Test::More;

use_ok(qw(DarkPAN::Indexer));

########################################################################
sub create_database {
########################################################################
  my ($packages_index) = @_;

  local $RS = undef;

  open my $fh, '<', $packages_index
    or die "ERROR: could not open $packages_index reading\n$OS_ERROR";

  my $compressed_db = <$fh>;

  close $fh;

  my $db = q{};
  gunzip( \$compressed_db, \$db );

  my ( $out_fh, $database ) = tempfile( UNLINK => 0, DIR => '/tmp' );

  print {$out_fh} $db;

  close $out_fh;

  return $database;
}

my $database;

########################################################################
subtest 'create_index' => sub {
########################################################################
  my $root = File::Temp->newdir;

  make_path "$root/authors/id";

  my $share = File::Spec->catdir( $Bin, '..', 'share' );
  my @dist_files = glob sprintf '%s/*.tar.gz', $share;

  foreach my $dist (@dist_files) {
    my $dist_file = basename($dist);
    copy $dist, "$root/authors/id/$dist_file";
  }

  if (@dist_files) {
    my $indexer = DarkPAN::Indexer->new(
      config => {
        storage                => { type => 'Filesystem', root => "$root" },
        format                 => { type => 'SQLite' },
        packages_version_index => 'modules/packages.db.gz',
      }
    );

    my $stats = $indexer->create_index;

    ok( -e "$root/modules/packages.db.gz", 'packages.db.gz created' );

    ok( $stats->{distributions_indexed} == 2, 'indexed 2 distributions' )
      or do {
      diag( Dumper( [ stats => $stats ] ) );
      };

    $database = eval { create_database("$root/modules/packages.db.gz"); };
    ok( $database, 'unzipped database' )
      or do {
      diag( Dumper( [ error => $EVAL_ERROR ] ) );
      BAIL_OUT("could not create database");
      };

    ok( -e $database, 'database exists ' . $database )
      or BAIL_OUT("$database does not exist");

    my $dbh = eval {
      return DBI->connect(
        "dbi:SQLite:dbname=$database",
        q{}, q{},
        { AutoCommit => 1,
          RaiseError => 1,
          PrintError => 1,
        }
      );
    };

    isa_ok( $dbh, 'DBI::db', 'opened a database handle' )
      or do {
      diag( Dumper( [ dbh => $dbh, error => $EVAL_ERROR ] ) );
      BAIL_OUT("coud not open database");
      };

    my $ref = $dbh->selectall_arrayref('select * from modules');
    isa_ok( $ref, 'ARRAY', 'got an array ref' );
    ok( @{$ref} == 2, 'Indexed 2 distributions' );

    $dbh->disconnect;
  }
};

# fetch the db back, open it, assert (package,version,path) rows —
# including MULTIPLE versions of one module (the money-shot assertion)

done_testing;

END {
  if ( $database && -e $database ) {
    unlink $database;
  }
}

1;
