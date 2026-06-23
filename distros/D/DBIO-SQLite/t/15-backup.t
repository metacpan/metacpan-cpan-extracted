use strict;
use warnings;

use Test::More;
use File::Temp ();

use DBIO::SQLite::Test;
use DBIO::Util qw(parent_dir);

# Exercises DBIO::SQLite::Storage::backup against a real on-disk SQLite file.
# This locks the refactored path handling (DBIO::Util::file_path +
# File::Basename::basename, formerly File::Spec).

my $schema = DBIO::SQLite::Test->init_schema(
  sqlite_use_file => 1,
  no_populate     => 1,
);

my $storage = $schema->storage;
my $dsn     = $storage->_dbi_connect_info->[0];
my ($dbname) = $dsn =~ /^dbi:SQLite:(.+)$/;

ok -f $dbname, 'on-disk SQLite database exists';

my $backupdir  = File::Temp->newdir;
my $backupfile = $storage->backup("$backupdir");

ok defined $backupfile,        'backup() returned a path';
ok -f $backupfile,             'backup file exists on disk';
like $backupfile, qr/DBIOTest-\d+\.db$/,
  'backup filename keeps the source basename (timestamp-prefixed)';
is parent_dir($backupfile), "$backupdir",
  'backup file landed in the requested directory';
is -s $backupfile, -s $dbname,
  'backup is a byte-for-byte copy of the source';

# Default directory: backup() with no argument writes to './'
{
  my $cwd = File::Temp->newdir;
  chdir "$cwd" or die "chdir failed: $!";

  my $here = $storage->backup;
  ok -f $here, 'backup() with no argument writes to the current directory';

  chdir '/' or die;  # leave the soon-to-be-removed tempdir
}

done_testing;
