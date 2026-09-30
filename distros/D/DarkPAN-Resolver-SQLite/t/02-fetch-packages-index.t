#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use IO::Compress::Gzip qw(gzip);
use Test::More;

use_ok(qw(DarkPAN::Resolver::SQLite));

my ( $seed_fh, $seed_database ) = tempfile(
  UNLINK => 0,
  SUFFIX => '.db',
  DIR    => '/tmp',
);

close $seed_fh;

my $dbh = DBI->connect(
  "dbi:SQLite:dbname=$seed_database",
  q{}, q{},
  { AutoCommit => 1,
    RaiseError => 1,
    PrintError => 1,
  },
);

$dbh->do(
  q{
    CREATE TABLE modules (
      distribution TEXT NOT NULL,
      module       TEXT NOT NULL,
      version      TEXT NOT NULL
    )
  }
);

$dbh->do(
  q{
    INSERT INTO modules (
      distribution,
      module,
      version
    )
    VALUES (
      'authors/id/F/FO/FOO/Foo-Bar-1.0.0.tar.gz',
      'Foo::Bar',
      'v1.0.0'
    )
  }
);

$dbh->disconnect;

local $RS = undef;

open my $db_fh, '<', $seed_database
  or die "ERROR: could not open $seed_database: $OS_ERROR";

binmode $db_fh;

my $database_content = <$db_fh>;

close $db_fh;

my $compressed_database = q{};

gzip( \$database_content, \$compressed_database, ) or die "ERROR: could not gzip seed database\n";

my $mirror = 'https://cpan.example.test/orepan2';

########################################################################
subtest 'fetches and decompresses packages database' => sub {
########################################################################
  my $requested_url;

  no warnings qw(redefine);

  local *HTTP::Tiny::get = sub {
    my ( $self, $url ) = @_;

    $requested_url = $url;

    return {
      success => 1,
      status  => 200,
      content => $compressed_database,
    };
  };

  my $resolver = bless { mirror => $mirror, }, 'DarkPAN::Resolver::SQLite';

  my $database = $resolver->_fetch_packages_version_index($mirror);

  is( $requested_url, "$mirror/modules/packages.db.gz", 'requested packages.db.gz from mirror', );

  ok( defined $database && -e $database, 'decompressed database file was created', );

  my $test_dbh = DBI->connect(
    "dbi:SQLite:dbname=$database",
    q{}, q{},
    { AutoCommit => 1,
      RaiseError => 1,
      PrintError => 1,
    },
  );

  my ($version) = $test_dbh->selectrow_array(
    q{
      SELECT version
        FROM modules
       WHERE module = ?
    },
    undef,
    'Foo::Bar',
  );

  is( $version, 'v1.0.0', 'decompressed file is a usable SQLite packages database', );

  $test_dbh->disconnect;

  unlink $database if defined $database && -e $database;
};

########################################################################
subtest 'http failure returns no database' => sub {
########################################################################
  no warnings qw(redefine);

  local *HTTP::Tiny::get = sub {
    return {
      success => q{},
      status  => 404,
      content => q{},
    };
  };

  my $resolver = bless { mirror => $mirror, }, 'DarkPAN::Resolver::SQLite';

  my $database = $resolver->_fetch_packages_version_index($mirror);

  ok( !defined $database, 'no database returned for failed HTTP request', );
};

########################################################################
subtest 'invalid gzip content is fatal' => sub {
########################################################################
  no warnings qw(redefine);

  local *HTTP::Tiny::get = sub {
    return {
      success => 1,
      status  => 200,
      content => 'not a gzip file',
    };
  };

  my $resolver = bless { mirror => $mirror, }, 'DarkPAN::Resolver::SQLite';

  local $EVAL_ERROR;

  my $database = eval { return $resolver->_fetch_packages_version_index($mirror); };

  my $error = $EVAL_ERROR;

  ok( !defined $database, 'no database returned for invalid gzip content', );

  like(
    $error,
    qr/^ERROR: could not decompress \Q$mirror\/modules\/packages.db.gz\E/m,
    'invalid gzip reports decompression failure',
  );
};

done_testing;

END {
  if ( $seed_database && -e $seed_database ) {
    unlink $seed_database;
  }
}

1;
