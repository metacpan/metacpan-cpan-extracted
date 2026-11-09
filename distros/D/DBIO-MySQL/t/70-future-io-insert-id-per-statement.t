use strict;
use warnings;
use Test::More;
use Socket qw( AF_UNIX SOCK_STREAM PF_UNSPEC );

# karr k69 -- on the future_io transport an insert_async resolves with the id
# of ITS OWN statement, or with none.
#
# WHY IT MATTERS. MySQL has no RETURNING, so the key of a freshly inserted row
# is the insertid its statement reported, folded into the returned-columns
# hashref (_insert_returned_columns). That hashref is what create_async stores
# on the Row, and the Row's key is the WHERE clause of every update_async and
# delete_async that follows. An insert that is handed another statement's id
# does not fail: it yields a Row that names somebody else's row, and the next
# write goes there.
#
# Until k69 the id travelled from the statement to the hashref through one slot
# per storage, written only when a statement reported a non-zero insertid. A
# statement that generated no id therefore left the previous insert's id in
# place, and its own hashref took it: into the key the caller had not supplied
# (the "first primary key column not supplied" fallback), or -- for a column
# flagged is_auto_increment -- over the key the caller HAD supplied.
#
# What this file claims:
#   1. an insert whose statement generated no id resolves with the data it was
#      given and nothing else, whatever was inserted before it on that storage:
#      no id for a key it did not supply, and a key it did supply is kept;
#   2. the same through the Row API, with the consequence spelled out: the Row
#      does not carry another row's key, and a following update_async puts no
#      UPDATE on the wire that names one;
#   3. the same on the pinned connection of a txn_do_async;
#   4. inserts that overlap on a pool of two connections each resolve with
#      their own statement's id, whichever result arrives first -- and an
#      overlapping insert that generated none takes none over, in either order;
#      on a pool of one, where the second insert is sent from inside the first
#      one's completion, the first still resolves with its own id;
#   5. last_insert_id, the legacy accessor, keeps what it had: the id of the
#      last statement that generated one.
#
# FULLY OFFLINE. The one substitution is the DBD: DBI->connect hands out a fake
# handle of the DBD the DSN names. Its server assigns an AUTO_INCREMENT value
# when a statement is SENT, from a counter per table, and the statement handle
# carries it once the result is collected -- per statement, as both DBDs do; a
# statement on a table without a counter reports 0. The socket is one end of a
# real socketpair, readable exactly while a result waits on it. By default the
# server answers at once; section 4 holds the answers back and lets the test
# decide which statement's result arrives first. Schema component, Row and
# ResultSet helpers, storage, async resolution, the pool, core's insert runner
# (_run_crud), dbio-async's _query_async / _query_async_pinned and this dist's
# _submit_query / _collect_result / _insert_returned_columns run for real.
#
# NOT PROVEN HERE (live only): which insertid a real server and a real DBD
# report for which statement -- in particular that a statement on a table with
# no AUTO_INCREMENT column reports 0, which is what the C API documents. t/78
# measures that, and runs claims 1, 3 and 4 against servers with inserts that
# overlap for real.

BEGIN {
  eval {
    require DBIO::MySQL::Storage::Async;
    require DBIO::MySQL::Storage::MariaDB::Async;
    1;
  } or plan skip_all =>
    'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBI;
use DBIO::Test;

# A statement nobody answers would leave its Future pending for good.
local $SIG{ALRM} = sub { die "t/70 timed out: a Future never settled\n" };
alarm 120;

# Each DBD's own names, spelled out here: the expectation must not be derived
# from the table under test.
my %API = (
  mysql => {
    fd       => 'mysql_fd',
    ready    => 'mysql_async_ready',
    result   => 'mysql_async_result',
    insertid => 'mysql_insertid',
  },
  MariaDB => {
    fd       => 'mariadb_sockfd',
    ready    => 'mariadb_async_ready',
    result   => 'mariadb_async_result',
    insertid => 'mariadb_insertid',
  },
);

# --- the fake server and DBDs ------------------------------------------------

our @CONNECTS;   # every handle DBI->connect handed out
our @WIRE;       # every statement sent: { dbh, sql, bind }
our %NEXT_ID;    # table => the next AUTO_INCREMENT value; no entry, no id
our $HOLD = 0;   # true: the server answers only when the test says so

# The result of the statement in flight on $dbh arrives.
sub answer {
  my ($dbh) = @_;
  delete $dbh->{unanswered} or die 'no unanswered statement on this connection';
  syswrite $dbh->{server}, 'R';
  return;
}

for my $dbd (sort keys %API) {
  my $api = $API{$dbd};
  no strict 'refs';

  *{"K69::${dbd}::DBH::new"} = sub {
    socketpair(my $client, my $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
      or die "socketpair: $!";
    return bless {
      Driver => { Name => $dbd },
      Active => 1,
      client => $client,   # the connection's socket
      server => $server,   # the server's end of it
    }, "K69::${dbd}::DBH";
  };
  *{"K69::${dbd}::DBH::prepare"} = sub {
    my ($self, $sql) = @_;
    return bless { dbh => $self, sql => $sql, NUM_OF_FIELDS => 0 }, "K69::${dbd}::STH";
  };
  *{"K69::${dbd}::DBH::$api->{fd}"}  = sub { fileno $_[0]{client} };
  *{"K69::${dbd}::DBH::do"} = sub { 1 };   # the session statement of every connection (karr k121)
  *{"K69::${dbd}::DBH::disconnect"} = sub { $_[0]{Active} = 0; 1 };
  *{"K69::${dbd}::DBH::err"}        = sub { undef };

  # Sent: the server runs the statement, and an INSERT into a table with an
  # AUTO_INCREMENT column takes that table's next value. The value belongs to
  # the statement from here on, whenever its result is collected.
  *{"K69::${dbd}::STH::execute"} = sub {
    my ($self, @bind) = @_;
    my $dbh = $self->{dbh};
    my ($table) = $self->{sql} =~ /\AINSERT INTO `?(\w+)`?/;
    $self->{generated} = defined $table && exists $NEXT_ID{$table}
      ? $NEXT_ID{$table}++
      : 0;
    push @WIRE, { dbh => $dbh, sql => $self->{sql}, bind => [@bind] };
    $dbh->{unanswered} = 1;
    main::answer($dbh) unless $HOLD;
    return 1;
  };
  *{"K69::${dbd}::STH::more_results"} = sub { 0 };   # one result set (karr k73)
  *{"K69::${dbd}::STH::$api->{ready}"} = sub {
    my $rin = '';
    vec($rin, fileno $_[0]{dbh}{client}, 1) = 1;
    return select($rin, undef, undef, 0) ? 1 : 0;
  };
  # Collected: the socket is quiet again, and the statement handle now carries
  # its insertid -- its DBD's attribute, and only that one.
  *{"K69::${dbd}::STH::$api->{result}"} = sub {
    my ($self) = @_;
    sysread $self->{dbh}{client}, my $result, 1;
    $self->{ $api->{insertid} } = $self->{generated};
    return 1;   # one row affected
  };
}

{
  no warnings 'redefine';
  *DBI::connect = sub {
    my ($class, $dsn) = @_;
    my ($dbd) = ($dsn // '') =~ /^dbi:(\w*)/i;
    die "fake DBI: no fake for DBD::$dbd\n" unless $API{$dbd};
    my $dbh = "K69::${dbd}::DBH"->new;
    push @CONNECTS, $dbh;
    return $dbh;
  };
}

# The shared test schema under each driver component. Its sources used here:
#   Artist      -- artistid flagged is_auto_increment; AUTO_INCREMENT on the
#                  fake server, so its inserts generate ids;
#   LinerNotes  -- an integer primary key that is NOT flagged, and no
#                  AUTO_INCREMENT on the server: a key the database fills some
#                  other way (a trigger, a default). Inserted without its key,
#                  the transport's fallback names liner_id as the column an id
#                  would go into -- and the statement reports none;
#   ArtistGUID  -- artistid flagged is_auto_increment for the engines that
#                  generate a GUID; on MySQL the application supplies it, and
#                  the statement reports no id.
# The transport has no session reset (core ADR 0079): the pool retires its
# connection at the end of every borrow. The "one connection" assertions of
# this file are not about the pool: an id that the fake keeps on the CONNECTION
# (as the DBD's last insert id is) can only be taken over by a statement that
# runs on the same connection as the insert before it. So the pool gets the
# reset a server with a session reset would give, done at once, and a statement
# after another meets the same connection, where a carried-over id would show.
{
  no warnings 'redefine';
  *DBIO::MySQL::Storage::Async::_reset_pool_connection = sub { Future->done };
}

{
  package K69::MySQLSchema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->load_components('MySQL');

  package K69::MariaDBSchema;
  use base 'DBIO::Test::Schema';
  __PACKAGE__->load_components('MySQL::MariaDB');
}

# --- helpers -----------------------------------------------------------------

# A schema on the future_io transport with a pool of two (or $pool_size), and
# a server whose artist table hands out ids from $first_id. The schema is kept:
# the backend holds its owning sync storage weakly.
my @schemas;
sub connected {
  my ($schema_class, $dbd, $first_id, $pool_size) = @_;
  my $schema = $schema_class->connect(
    "dbi:$dbd:database=t", 'u', 'p',
    { async => 'future_io', pool_size => $pool_size // 2 },
  );
  push @schemas, $schema;
  @CONNECTS = ();
  @WIRE     = ();
  %NEXT_ID  = ( artist => $first_id );
  return ($schema, $schema->storage->async);
}

# What a Future resolved with, waited for; a failure is thrown.
sub resolved {
  my ($f) = @_;
  $f->await;
  return $f->get;
}

# The statements on the wire as "SQL [binds]".
sub wire {
  return [ map { "$_->{sql} [" . join(', ', @{ $_->{bind} }) . ']' } @WIRE ];
}

my $GUID = 'c9bf9e57-1685-4c89-bafb-ff5af830be8a';

for my $combo (
  [ 'K69::MySQLSchema',   'mysql'   ],
  [ 'K69::MariaDBSchema', 'MariaDB' ],
) {
  my ($schema_class, $dbd) = @$combo;
  my $label = "$schema_class + dbi:$dbd:";

  # -------------------------------------------------------------------------
  # 1. One insert after the other, on one storage.
  # -------------------------------------------------------------------------
  {
    my ($schema, $async) = connected($schema_class, $dbd, 7);

    is_deeply resolved($async->insert_async($schema->source('Artist'), { name => 'Miles' })),
      { name => 'Miles', artistid => 7 },
      "$label: an insert that generated an id resolves with it, on the flagged column";

    # The key was not supplied and the statement generated none. Before k69
    # this hashref carried liner_id => 7 -- the artist's id.
    is_deeply resolved($async->insert_async($schema->source('LinerNotes'), { notes => 'first' })),
      { notes => 'first' },
      "$label: an insert that generated NO id resolves with its own data only -- "
    . 'not with the id of the insert before it';

    # 5. the legacy accessor is not the per-statement value: it still names the
    #    last id a statement generated.
    is $async->last_insert_id, 7,
      "$label: last_insert_id keeps the last GENERATED id through a statement that generated none";

    is_deeply resolved($async->insert_async($schema->source('Artist'), { name => 'Bill' })),
      { name => 'Bill', artistid => 8 },
      "$label: the next insert that generates an id resolves with its own";

    # The key WAS supplied, on a column flagged is_auto_increment. Before k69
    # the previous insert's 8 was written over it.
    #
    # ArtistGUID also has a_guid, flagged auto_nextval. The synchronous insert
    # fetches that value; the asynchronous one does not, and since core k331 it
    # refuses an insert that leaves the column out instead of sending NULL.
    # The refusal comes first and sends nothing; the insert then supplies the
    # value, as the refusal says, and the property above is checked on it.
    @WIRE = ();
    my $refused = '';
    {
      local $@;
      eval {
        resolved($async->insert_async(
          $schema->source('ArtistGUID'), { artistid => $GUID, name => 'Gil' },
        ));
        1;
      } or $refused = $@;
    }
    like "$refused", qr/cannot fill the auto_nextval column 'a_guid' of ArtistGUID/,
      "$label: an insert leaving the auto_nextval column a_guid out is refused, naming it";
    is scalar(@WIRE), 0, "$label: ... and sends no statement";

    my $A_GUID = '0f3c5e2a-6d52-4a54-9a61-5d0b1a7d8f11';
    is_deeply resolved($async->insert_async(
        $schema->source('ArtistGUID'),
        { artistid => $GUID, name => 'Gil', a_guid => $A_GUID },
      )),
      { artistid => $GUID, name => 'Gil', a_guid => $A_GUID },
      "$label: a supplied key is kept when the statement generated no id -- "
    . 'not overwritten with the id of the insert before it';

    is scalar(@CONNECTS), 1, "$label: ... all of it on one connection, one statement after the other";
  }

  # -------------------------------------------------------------------------
  # 2. Why it matters: the hashref becomes the Row, and the Row's key is where
  #    the next write goes.
  # -------------------------------------------------------------------------
  {
    my ($schema, $async) = connected($schema_class, $dbd, 7);

    my $artist = resolved($schema->resultset('Artist')->create_async({ name => 'Miles' }));
    is $artist->artistid, 7, "$label: create_async stores the generated id on the Row";

    my $liner = resolved($schema->resultset('LinerNotes')->create_async({ notes => 'first' }));
    is $liner->liner_id, undef,
      "$label: a Row whose insert generated no id does not carry the artist's 7 as its key";

    # Before k69 this sent UPDATE `liner_notes` SET `notes` = ? WHERE
    # `liner_id` = ? with [changed, 7]: whatever liner_notes row has the key 7
    # was rewritten, and the caller was told its own row had been updated.
    @WIRE = ();
    my $error = '';
    {
      local $@;
      eval { resolved($liner->update_async({ notes => 'changed' })); 1 } or $error = $@;
    }
    is_deeply [ grep { /\AUPDATE/ } @{ wire() } ], [],
      "$label: ... so its update_async sends no UPDATE at all, where it used to "
    . 'send one that names another row';
    like "$error", qr/missing PK columns: liner_id/,
      "$label: ... and core refuses it, naming the key the Row does not have";
  }

  # -------------------------------------------------------------------------
  # 3. The pinned connection of a transaction runs the same insert runner.
  # -------------------------------------------------------------------------
  {
    my ($schema, $async) = connected($schema_class, $dbd, 7);

    my @returned = resolved($async->txn_do_async(sub {
      my ($txn) = @_;
      return $txn->insert_async($schema->source('Artist'), { name => 'Miles' })->then(sub {
        my ($first) = @_;
        return $txn->insert_async($schema->source('LinerNotes'), { notes => 'first' })->then(sub {
          return Future->done($first, $_[0]);
        });
      });
    }));
    is_deeply \@returned, [ { name => 'Miles', artistid => 7 }, { notes => 'first' } ],
      "$label: inside txn_do_async too, an insert that generated no id takes none over";
  }

  # -------------------------------------------------------------------------
  # 4. Overlapping inserts on a pool of two. The server answers when the test
  #    says so, so the result of the statement sent LAST arrives FIRST.
  # -------------------------------------------------------------------------
  {
    my ($schema, $async) = connected($schema_class, $dbd, 7);
    local $HOLD = 1;

    my $first  = $async->insert_async($schema->source('Artist'), { name => 'sent first' });
    my $second = $async->insert_async($schema->source('Artist'), { name => 'sent second' });

    is scalar(@CONNECTS), 2, "$label: two inserts started together run on two connections";
    ok !$first->is_ready && !$second->is_ready, '... both in flight at once';

    answer($CONNECTS[1]);
    is_deeply resolved($second), { name => 'sent second', artistid => 8 },
      "$label: the insert whose result arrives first resolves with its own id";
    ok !$first->is_ready, '... while the one sent before it is still in flight';

    answer($CONNECTS[0]);
    is_deeply resolved($first), { name => 'sent first', artistid => 7 },
      "$label: the insert whose result arrives last resolves with ITS id -- not "
    . 'with the one that finished in between';
  }

  # An insert that generates no id, overlapping one that does: whichever
  # finishes first, the one without takes nothing over.
  for my $order ( [ 0, 1 ], [ 1, 0 ] ) {
    my ($schema, $async) = connected($schema_class, $dbd, 7);
    local $HOLD = 1;

    my @f = (
      $async->insert_async($schema->source('Artist'),     { name  => 'Miles' }),
      $async->insert_async($schema->source('LinerNotes'), { notes => 'first' }),
    );
    my @got;
    for my $i (@$order) {
      answer($CONNECTS[$i]);
      $got[$i] = resolved($f[$i]);
    }
    my $which = $order->[0] == 0 ? 'the insert with an id finishes first'
                                 : 'the insert without an id finishes first';
    is_deeply \@got, [ { name => 'Miles', artistid => 7 }, { notes => 'first' } ],
      "$label: overlapping, $which -- each resolves with what its own statement generated";
  }

  # A pool of ONE. The second insert waits for the connection and is SENT from
  # inside the first one's completion: after the first statement's id was
  # taken off its handle, before its hashref is assembled. A statement going
  # out in between must not change what the one just collected resolves with.
  {
    my ($schema, $async) = connected($schema_class, $dbd, 7, 1);

    my $first  = $async->insert_async($schema->source('Artist'),     { name  => 'Miles' });
    my $second = $async->insert_async($schema->source('LinerNotes'), { notes => 'first' });
    is scalar(@WIRE), 1, "$label: on a pool of one the second insert waits for the connection";

    # A caller queued for a connection holds a plain Future of the pool's
    # making, which cannot wait by itself under Future::IO's built-in poll; its
    # outcome is carried on a Future of the kind the first insert got.
    my $second_awaitable = $first->new;
    $second->on_ready($second_awaitable);

    is_deeply [ resolved($first), resolved($second_awaitable) ],
      [ { name => 'Miles', artistid => 7 }, { notes => 'first' } ],
      "$label: ... and both resolve with what their own statement generated";
    is scalar(@CONNECTS), 1, '... on that one connection';
  }
}

alarm 0;
done_testing;
