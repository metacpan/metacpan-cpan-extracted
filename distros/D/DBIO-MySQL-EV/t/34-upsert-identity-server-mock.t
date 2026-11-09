use strict;
use warnings;
use Test::More;

BEGIN { eval { require Future; 1 } or plan skip_all => 'Future not installed' }

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::MySQL::EV::Storage;

# An upsert that takes the UPDATE branch of ON DUPLICATE KEY UPDATE resolves the
# row the server touched -- on every server the driver tells apart (karr k47).
#
# Why it can go wrong: this transport reads a written row's id with
# SELECT LAST_INSERT_ID() on the INSERT's session (ADR 0004). On the UPDATE
# branch that function names the touched row only when the statement set it,
# `pk` = LAST_INSERT_ID(`pk`); otherwise it holds what the session held before
# -- 0 on a session that has generated no id. Whether the statement carries
# that assignment is decided by the owning sync storage's _mysql_upsert_plan,
# from the server the owner sees, and a row with id 0 is a row that does not
# exist.
#
# The server reaches the plan the way it does on a connection: _server_info ->
# _is_mariadb / _determine_supports_insert_returning -> _use_insert_returning
# -> _mysql_upsert_plan. Only _server_info is replaced, because
# DBIO::Test::Storage has no server to ask; nothing below says which channel
# the plan or the transport is to pick. t/18-upsert-identity-mock.t holds the
# statements of the one server DBIO::Test::Storage reports by default;
# t/17-upsert-live.t is the same claim against a real server.

my %server;
{
  no warnings 'redefine';
  *DBIO::Test::Storage::_server_info = sub { +{ %server } };
}

# One pooled connection is one server session, with its own LAST_INSERT_ID().
# Every acquire answers a new one, so the second upsert runs on a session that
# has generated no id -- what a pool of two gives t/17.
{
  package K47::Session;
  sub new { bless { last_insert_id => 0 }, $_[0] }
}
{
  package K47::Pool;
  sub new      { bless { sessions => [] }, $_[0] }
  sub release  { }
  sub _lease   { 1 }   # the lease of a borrow (core k275, karr k91)
  sub shutdown { }
  sub _mysql_report_if_gone { }
  sub acquire {
    my $self = shift;
    push @{ $self->{sessions} }, K47::Session->new;
    return Future->done($self->{sessions}[-1]);
  }
}

# What a MySQL or MariaDB server does with the statements of an insert on
# `artist`, a table with an AUTO_INCREMENT primary key `artistid` and a unique
# `name`: a generated id is the session's LAST_INSERT_ID(); the UPDATE branch
# leaves that value alone unless the statement assigns LAST_INSERT_ID(expr).
# It hands back no rows for an INSERT: a statement asking for them is refused,
# so a transport that starts reading RETURNING fails here instead of passing
# on a model that does not know it.
{
  package K47::Server;
  sub new { bless { ids => {}, next_id => 1, branches => [], inserts => [] }, $_[0] }
  sub execute {
    my ($self, $session, $sql, $bind) = @_;

    return Future->done([ $session->{last_insert_id} ])
      if $sql eq 'SELECT LAST_INSERT_ID()';

    my ($columns) = $sql =~ /^INSERT \s+ INTO \s+ `artist` \s* \( ([^)]*) \) \s* VALUES/x
      or die "the mock server does not know this statement: $sql";
    die "the mock server returns no rows for an INSERT: $sql"
      if $sql =~ /\bRETURNING\b/;
    push @{ $self->{inserts} }, $sql;

    my %row;
    @row{ $columns =~ /`(\w+)`/g } = @$bind;

    if (my $id = $self->{ids}{ $row{name} }) {
      die "Duplicate entry '$row{name}' for key 'name'"
        unless $sql =~ /ON \s+ DUPLICATE \s+ KEY \s+ UPDATE/x;
      push @{ $self->{branches} }, 'update';
      $session->{last_insert_id} = $id
        if $sql =~ /`artistid` \s* = \s* LAST_INSERT_ID \( `artistid` \)/x;
      return Future->done(2);
    }

    push @{ $self->{branches} }, 'insert';
    $session->{last_insert_id} = $self->{ids}{ $row{name} } = $self->{next_id}++;
    return Future->done(1);
  }
}

my @servers = (
  # label              VERSION()                    normalized    RETURNING
  [ 'MySQL 8.0',       '8.0.46',                    '8.000046',   0 ],
  [ 'MariaDB 10.4',    '10.4.34-MariaDB',           '10.004034',  0 ],
  [ 'MariaDB 10.5',    '10.5.0-MariaDB',            '10.005000',  1 ],
  [ 'MariaDB 10.11',   '10.11.19-MariaDB-ubu2204',  '10.011019',  1 ],
);

for my $case (@servers) {
  my ($label, $version, $normalized, $has_returning) = @$case;

  subtest $label => sub {
    %server = ( dbms_version => $version, normalized_dbms_version => $normalized );

    my $schema = DBIO::Test->init_schema(
      no_deploy    => 1,
      storage_type => 'DBIO::MySQL::Storage',
    );
    my $storage = $schema->storage;

    is $storage->_use_insert_returning, $has_returning,
      "the owning storage reads $version as a server "
      . ($has_returning ? 'with' : 'without') . ' INSERT ... RETURNING';

    $storage->_async_mode('ev');
    my $backend = $storage->_async_storage;
    my $pool    = $backend->{pool}     = K47::Pool->new;
    my $mock    = $backend->{executor} = K47::Server->new;

    my $rs = $schema->resultset('Artist');
    my $upsert = sub {
      my ($rank) = @_;
      my $f = $rs->upsert_async(
        { name => 'Tom', rank => $rank },
        { conflict_target => 'any' },
      );
      my $row = eval { $f->get };
      diag "upsert_async failed: $@" if $@;
      return $row;
    };

    my $first  = $upsert->(1);
    my $second = $upsert->(2);

    is_deeply $mock->{branches}, [qw( insert update )],
      'the first upsert inserted, the second collided on the unique name';
    is scalar @{ $pool->{sessions} }, 2,
      'each upsert ran on a session of its own';

    is $first && $first->artistid, 1,
      'the insert branch resolved the generated id';
    is $second && $second->artistid, 1,
      'the UPDATE branch resolved the id of the row the server touched';

    # Without RETURNING the assignment is the only channel there is.
    like $mock->{inserts}[1],
      qr/`artistid` \s* = \s* LAST_INSERT_ID \( `artistid` \)/x,
      'the statement names the touched row through LAST_INSERT_ID(`artistid`)';
  };
}

done_testing;
