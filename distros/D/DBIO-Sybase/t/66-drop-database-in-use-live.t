use strict;
use warnings;

use Test::More;
use DBI;
use Time::HiRes ();
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Deploy;

# LIVE (karr k74). A database something is in cannot be dropped:
#
#   Msg 3702: Cannot drop or replace the database '..' because it is currently
#   in use.
#
# One refusal of that kind ended t/63-uniqueidentifier-live.t after 54 tests in
# a full live run, at the DROP DATABASE that follows the disconnect of a
# section. What was in the database at that moment is not known. It was not
# reproduced: 45 drops right after a disconnect, and 600 looks into
# master..sysprocesses right after one, found the session gone every time. Seen
# instead, once in eight minutes of watching: the server's own checkpoint
# process (spid 6, CHECKPOINT SLEEP) inside a database no client was connected
# to. Either way it is something that leaves by itself, and no order of
# statements in a test keeps it out.
#
# So the moment is made here: a second session sits in the database when the
# drop begins, and leaves a second later -- or does not leave.
#
# CLAIMED, of t/lib/AseDatabase.pm, which the live files drop their databases
# with:
#
#   1. With a session in the database that leaves after a second, the drop is
#      taken: it was repeated until then.
#   2. With one that stays, the drop gives up after its tries and returns what
#      the server said. It does not die, and the database is still there.
#   3. Another refusal -- a database that does not exist, Msg 2520 -- comes
#      back at once.
#
# CLAIMED, of DBIO::Sybase::Deploy, whose diff drops its temporary database
# the moment core has closed the session into it:
#
#   4. With a session in the temporary database when its drop begins, leaving
#      a second later, diff returns and no temporary database is left. Before
#      karr k74 the one refusal was final, core caught it, and
#      _dbio_tmp_<pid>_<time> stayed on the server without a word.
#   5. With one that stays, _drop_temp_db gives up with the server's error and
#      the live handle is back in its own database.
#
# NOT claimed: how long anything of the server's own stays in a database, or
# that ten seconds -- the bound of both -- outlast it on a loaded server.
#
# Runs in throwaway databases it creates and drops itself; needs a login
# allowed to CREATE DATABASE (sa on the docker/k8s ASE image).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};
plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test.'
  unless $dsn && $user;

{
  package T::K74::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k74_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T::K74::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Item => 'T::K74::Result::Item');
}

my %attr = ( RaiseError => 1, PrintError => 0, AutoCommit => 1 );

my $admin;
sub admin {
  return $admin ||= do {
    my $dbh = DBI->connect($dsn, $user, $pass, \%attr);
    $dbh->do('use master');
    $dbh;
  };
}

sub server_column { @{ admin()->selectcol_arrayref(@_) } }

my $prefix = "dbio_k74_${$}_";

# This process' databases: the ones made here, and the temporary ones of
# DBIO::Sybase::Deploy.
sub databases_there {
  return server_column(sprintf
    q{select name from master..sysdatabases }
  . q{where name like 'dbio[_]k74[_]%d[_]%%' or name like '[_]dbio[_]tmp[_]%d[_]%%' }
  . q{order by name},
    $$, $$
  );
}

sub sessions_in {
  return scalar server_column(
    "select spid from master..sysprocesses where dbid = db_id('$_[0]')"
  );
}

sub dsn_for {
  my $db = shift;
  my $db_dsn = $dsn;
  $db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
    or $db_dsn .= ( $dsn =~ /:$/ ? '' : ';' ) . "database=$db";
  return $db_dsn;
}

# Somebody else in the database: a session of its own, doing nothing.
my @sessions;
sub session_in {
  my $dbh = DBI->connect(dsn_for($_[0]), $user, $pass, \%attr);
  push @sessions, $dbh;
  return $dbh;
}

# ... who leaves after $seconds, whatever this process is doing then: the
# signal is handled between two statements of the drop that is waiting.
my @leaving;
$SIG{ALRM} = sub { $_->disconnect for splice @leaving };
sub leaves_after {
  my ($dbh, $seconds) = @_;
  push @leaving, $dbh;
  Time::HiRes::alarm($seconds);
}

# The server's words, without the rest of the exception.
sub said {
  my $text = shift // '';
  return "Msg $1: $2"
    if $text =~ /Server message number=(\d+) [^\n]*?\btext=(.*?)\s*(?=\[for Statement| at \S+ line \d+|\z)/s;
  $text =~ s/\s+/ /g;
  return $text;
}

my $live = 1;   # past the skip_all: from here on there is something to drop

note 'client library: ' . ( admin()->{syb_oc_version} || '(unknown)' );

# ========================== 1. the helper: somebody is in it, and leaves

{
  my $db = "${prefix}a";
  admin()->do("create database $db");

  my $other = session_in($db);
  is sessions_in($db), 1, 'a session of somebody else is in the database';

  leaves_after($other, 1);
  is AseDatabase::drop(admin(), $db), '',
    '... it leaves a second later: the drop was repeated until then, and is '
    . 'taken';
  ok !grep({ $_ eq $db } databases_there()), '... the database is gone';
}

# ============================== 2. the helper: somebody is in it, and stays

{
  my $db = "${prefix}b";
  admin()->do("create database $db");

  my $other = session_in($db);

  is AseDatabase::drop(admin(), $db, tries => 3, wait => 0.1),
    "Msg 3702: Cannot drop or replace the database '$db' because it is "
    . 'currently in use.',
    'with a session that stays, the drop gives up after its tries and '
    . 'returns what the server said: it does not die';
  ok scalar( grep { $_ eq $db } databases_there() ),
    '... and the database is still there';

  $other->disconnect;
  is AseDatabase::drop(admin(), $db), '', '... until the session left';
}

# ================================ 3. the helper: a refusal of another kind

{
  my $started = Time::HiRes::time;

  is AseDatabase::drop(admin(), "${prefix}none"),
    "Msg 2520: Database named ${prefix}none not found; check sysdatabases",
    'the refusal of a database that does not exist is returned as it is';
  cmp_ok Time::HiRes::time - $started, '<', 5,
    '... at once: it is not waited for';
}

# ======================== 4, 5. DBIO::Sybase::Deploy and its temporary database

{
  my $db = "${prefix}live";
  admin()->do("create database $db");

  my $schema = T::K74::Schema->connect(dsn_for($db), $user, $pass);
  my $deploy = DBIO::Sybase::Deploy->new(schema => $schema);
  $deploy->install;

  my $in_database = sub { ( $schema->storage->dbh->selectrow_array('select db_name()') )[0] };

  # ------------------------------------------------- 4. it leaves: diff
  #
  # Core closes the session of the temporary deploy and calls _drop_temp_db.
  # There, before the first DROP DATABASE, somebody else walks in.
  my $drop_temp_db = DBIO::Sybase::Deploy->can('_drop_temp_db');
  my ($diff, @walked_in);
  {
    no warnings 'redefine';
    local *DBIO::Sybase::Deploy::_drop_temp_db = sub {
      my ($self, $dbh, $name) = @_;
      my $other = session_in($name);
      push @walked_in, sessions_in($name);
      leaves_after($other, 1);
      return $self->$drop_temp_db($dbh, $name);
    };

    $diff = eval { $deploy->diff };
  }
  my $error = $@;

  ok $diff && !$diff->has_changes,
    'Deploy->diff returns, empty, the diff of a schema just installed'
    or diag '  ' . ( $diff ? $diff->as_sql : said($error) );
  ok @walked_in == 1 && $walked_in[0] >= 1,
    '... with a session in its temporary database when the drop began';
  is_deeply [ grep { /^_dbio_tmp_/ } databases_there() ], [],
    '... and the temporary database is dropped all the same: the drop was '
    . 'repeated until the session had left';
  is $in_database->(), $db,
    '... the live session is in its own database afterwards';

  # --------------------------------------- 5. it stays: _drop_temp_db
  #
  # On a database made here: the name _create_temp_db gives has the second
  # in it, and is taken for the rest of that second by a temporary database
  # that 4 left behind.
  {
    my $dbh  = $schema->storage->dbh;
    my $temp = "${prefix}t";
    admin()->do("create database $temp");
    my $other = session_in($temp);

    no warnings 'redefine';
    local *DBIO::Sybase::Deploy::_drop_in_use_tries = sub { 3 };
    local *DBIO::Sybase::Deploy::_drop_in_use_wait  = sub { 0.1 };

    my $lived = eval { $deploy->_drop_temp_db($dbh, $temp); 1 };
    $error = $@;

    ok !$lived, '_drop_temp_db gives up on a temporary database a session stays in';
    is said($error),
      "Msg 3702: Cannot drop or replace the database '$temp' because it is "
      . 'currently in use.',
      '... with the server\'s error';
    is $in_database->(), $db,
      '... and the live session is back in its own database';

    $other->disconnect;
    ok eval { $deploy->_drop_temp_db($dbh, $temp) },
      '... the same call drops it once the session left'
      or diag '  ' . said($@);
  }

  $schema->storage->disconnect;
  is AseDatabase::drop(admin(), $db), '', 'the database of 4 and 5 is dropped';
}

# ================================================================ the end

is_deeply [ databases_there() ], [], 'nothing of this test is left on the server';

done_testing;

# The databases again, on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    eval { $_->disconnect } for splice(@leaving), splice(@sessions);
    undef $admin;
    my @kept = eval {
      map { my $said = AseDatabase::drop(admin(), $_); $said ? "$_: $said" : () }
        databases_there();
    };
    diag "Could not clean up after this test: $_" for ( $@ ? said($@) : () ), @kept;
  }
}
