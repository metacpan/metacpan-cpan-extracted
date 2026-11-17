use strict;
use warnings;

use Test::More;
use File::Temp ();

use DBIO::SQLite::Test;
use DBIO::Util qw(file_path);
use DBIO::SQLite::Util qw(libsqlite_version);

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
SKIP: {
  my ($real_version, $real_number) = libsqlite_version($storage->_get_dbh);
  skip "VACUUM INTO needs libsqlite 3.27+, this is $real_version", 8
    if $real_number < 3_027_000;

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

  # The trace shows a bind value quoted and cut to 32 characters plus '...'
  # (see DBIO::Storage::DBI::_format_for_trace); a long temp path (macOS,
  # Windows, Android) is therefore only visible as its 32-character prefix.
  # That the full name was bound is what the -f check below proves.
  my @bind = @{ $vacuums[0] }[1 .. $#{ $vacuums[0] }];
  my $traced = length($target) > 32 ? substr($target, 0, 32) . '...' : $target;
  is_deeply(\@bind, [ qq{'$traced'} ],
    'filename is carried in the bind list (as the trace shows it)');

  ok(-f $target, 'VACUUM INTO actually wrote the target database file');
}

# --- VACUUM INTO on a libsqlite that lacks it -------------------------------
# VACUUM INTO is libsqlite 3.27+. Older, it used to end in SQLite's bare
# 'near "INTO": syntax error'; now the call says which version it needs and
# which is present, before it sends anything. No old libsqlite is needed: only
# the answer of `SELECT sqlite_version()` is replaced, so the driver's own
# reading and comparison of the string stay in play.
{
  my $dbh = $storage->_get_dbh;
  my $real = \&DBD::SQLite::db::selectrow_array;

  my $under = sub {
    my ($version, $code) = @_;
    no warnings 'redefine';
    local *DBD::SQLite::db::selectrow_array = sub {
      return $version if defined $_[1] && $_[1] eq 'SELECT sqlite_version()';
      goto &$real;
    };
    return $code->();
  };

  my $dir = File::Temp->newdir;

  # 3.9.2 is the one a comparison as text gets wrong: "3.9" sorts behind "3.27"
  for my $version (qw( 3.26.0 3.9.2 )) {
    my $target = file_path("$dir", "old-$version.db");
    local $storage->{debugobj} = my $stats = DBIO::Test::VacuumTracerObj->new;
    local $storage->{debug} = 2;

    my $ok = eval { $under->($version, sub { $storage->vacuum($target) }); 1 };
    my $error = "$@";

    ok(!$ok, "libsqlite $version: vacuum(\$file) throws");
    like($error, qr/VACUUM INTO/, "libsqlite $version: the message names VACUUM INTO");
    like($error, qr/3\.27/, "libsqlite $version: the message names the version needed");
    like($error, qr/\Q$version\E/, "libsqlite $version: the message names the version present");
    unlike($error, qr/syntax error/, "libsqlite $version: not SQLite's syntax error");
    is(scalar(grep { $_->[0] =~ /VACUUM/ } @{ $stats->captured }), 0,
      "libsqlite $version: no VACUUM statement was sent");
    ok(! -e $target, "libsqlite $version: no file was written");
  }

  # plain VACUUM does not need 3.27
  {
    local $storage->{debugobj} = my $stats = DBIO::Test::VacuumTracerObj->new;
    local $storage->{debug} = 1;
    my $rv = eval { $under->('3.9.2', sub { $storage->vacuum }) };
    is($@, '', 'plain vacuum() runs under a simulated libsqlite 3.9.2');
    is($rv, $storage, 'plain vacuum() returns the storage under 3.9.2');
    is_deeply([ map { $_->[0] } grep { $_->[0] =~ /^VACUUM/ } @{ $stats->captured } ],
      [ 'VACUUM' ], 'plain vacuum() emitted exactly "VACUUM" under 3.9.2');
  }

  # new enough: goes through to the real statement (the real libsqlite here
  # may be older, so only the check is under test: the VACUUM INTO is sent)
  for my $version (qw( 3.27.0 3.39.4 )) {
    my $target = file_path("$dir", "new-$version.db");
    local $storage->{debugobj} = my $stats = DBIO::Test::VacuumTracerObj->new;
    local $storage->{debug} = 2;

    eval { $under->($version, sub { $storage->vacuum($target) }); 1 };
    unlike("$@", qr/needs libsqlite 3\.27/, "libsqlite $version: the version check lets it through");
    is(scalar(grep { $_->[0] eq 'VACUUM INTO ?' } @{ $stats->captured }), 1,
      "libsqlite $version: VACUUM INTO ? was sent");
  }
}

done_testing;
