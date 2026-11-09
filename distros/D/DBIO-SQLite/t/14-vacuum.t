use strict;
use warnings;

use Test::More;
use File::Temp ();

use DBIO::SQLite::Test;
use DBIO::Util qw(file_path);

# Exercises DBIO::SQLite::Storage::vacuum. Two forms:
#   $storage->vacuum          -> emits  VACUUM
#   $storage->vacuum($file)   -> emits  VACUUM INTO ?   (SQLite 3.27+)
#
# The target filename MUST travel as a bind parameter, never interpolated
# into the SQL text -- so the emitted SQL for the INTO form is exactly
# "VACUUM INTO ?" with $file in the bind list.
#
# SQL is captured off the storage debugobj (query_start), the established
# in-driver pattern for asserting emitted SQL (see t/storage/savepoints.t).

{
  package # hide from indexer
    DBIO::Test::VacuumTracerObj;

  use base 'DBIO::Storage::Statistics';

  sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{captured} = [];
    return $self;
  }

  sub query_start {
    my ($self, $sql, @bind) = @_;
    push @{ $self->{captured} }, [ $sql, @bind ];
    return;
  }

  sub captured { $_[0]{captured} }
}

my $schema = DBIO::SQLite::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;

can_ok($storage, 'vacuum');

# --- plain VACUUM -----------------------------------------------------------
{
  local $storage->{debugobj} = my $stats = DBIO::Test::VacuumTracerObj->new;
  local $storage->{debug} = 1;

  my $rv = $storage->vacuum;

  is($rv, $storage, 'vacuum() returns the storage (via _do_query)');

  my @vacuums = grep { $_->[0] =~ /^VACUUM/ } @{ $stats->captured };
  is(scalar @vacuums, 1, 'plain vacuum() emitted exactly one VACUUM statement');
  is($vacuums[0][0], 'VACUUM', 'plain vacuum() emits bare "VACUUM"');
}

# --- VACUUM INTO ? ----------------------------------------------------------
{
  my $dir = File::Temp->newdir;
  # VACUUM INTO requires the target file NOT to exist yet.
  my $target = file_path("$dir", 'vacuum-out.db');
  ok(! -e $target, 'target file does not exist before VACUUM INTO');

  local $storage->{debugobj} = my $stats = DBIO::Test::VacuumTracerObj->new;
  local $storage->{debug} = 2;

  my $rv = $storage->vacuum($target);

  is($rv, $storage, 'vacuum($file) returns the storage');

  my @vacuums = grep { $_->[0] =~ /^VACUUM/ } @{ $stats->captured };
  is(scalar @vacuums, 1, 'vacuum($file) emitted exactly one VACUUM statement');

  is($vacuums[0][0], 'VACUUM INTO ?',
    'vacuum($file) emits "VACUUM INTO ?" -- filename is a bind placeholder, not interpolated');

  unlike($vacuums[0][0], qr/\Q$target\E/,
    'filename does not appear in the SQL text');

  my @bind = @{ $vacuums[0] }[1 .. $#{ $vacuums[0] }];
  ok((grep { index($_, $target) >= 0 } @bind),
    'filename is carried in the bind list');

  ok(-f $target, 'VACUUM INTO actually wrote the target database file');
}

done_testing;
