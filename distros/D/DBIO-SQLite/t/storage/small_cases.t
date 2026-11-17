use strict;
use warnings;

use Test::More;
use Test::Warn;
use Test::Exception;
use DBI ();
use DBIO::Util qw(peepeeness);
use DBIO::SQLite::Test;

# cursor: a custom cursor_class must be autoloaded and re-loaded after being unloaded.
subtest 'cursor' => sub {
  my $schema = DBIO::SQLite::Test->init_schema(cursor_class => 'DBIO::Test::Cursor');

  lives_ok {
    is($schema->resultset("Artist")->search(), 3, "Three artists returned");
  } 'Custom cursor autoloaded';

  SKIP: {
    eval { require Class::Unload }
      or skip 'component_class reentrancy test requires Class::Unload', 1;

    Class::Unload->unload('DBIO::Test::Cursor');

    lives_ok {
      is($schema->resultset("Artist")->search(), 3, "Three artists still returned");
    } 'Custom cursor auto re-loaded';
  }
};

# dbh_do: dbh_do must (re)connect, pass its arguments through and alias them.
subtest 'dbh_do' => sub {
  my $schema = DBIO::SQLite::Test->init_schema();
  my $storage = $schema->storage;

  # test (re)connection
  for my $disconnect (0, 1) {
    $schema->storage->_dbh->disconnect if $disconnect;
    is_deeply (
      $schema->storage->dbh_do(sub { $_[1]->selectall_arrayref('SELECT 1') }),
      [ [ 1 ] ],
      'dbh_do on fresh handle worked',
    );
  }

  my @args;
  my $test_func = sub { @args = @_ };

  $storage->dbh_do($test_func, "foo", "bar");
  is_deeply (
    \@args,
    [ $storage, $storage->dbh, "foo", "bar" ],
  );


  my $storage_class = ref $storage;
  {
    no strict 'refs';
    local *{$storage_class .'::__test_method'} = $test_func;
    $storage->dbh_do("__test_method", "baz", "buz");
  }

  is_deeply (
    \@args,
    [ $storage, $storage->dbh, "baz", "buz" ],
  );

  # test nested aliasing
  my $res = 'original';
  $storage->dbh_do (sub {
    shift->dbh_do(sub { $_[3] = 'changed' }, @_)
  }, $res);

  is ($res, 'changed', "Arguments properly aliased for dbh_do");
};

# dbi_coderef: connecting with a coderef that returns a DBI handle must work like a dsn.
subtest 'dbi_coderef' => sub {
  plan tests => 1;

  # Set up the "usual" sqlite and disconnect
  my $normal_schema = DBIO::SQLite::Test->init_schema( sqlite_use_file => 1 );
  $normal_schema->storage->disconnect;

  # Steal the dsn from the test schema
  my @dsn = ($normal_schema->storage->_dbi_connect_info->[0], undef, undef, {
    RaiseError => 1
  });

  # Make a new clone with a new connection, using a code reference
  my $code_ref_schema = $normal_schema->connect(sub { DBI->connect(@dsn); });

  # Stolen from 60core.t - this just verifies things seem to work at all
  my @art = $code_ref_schema->resultset("Artist")->search({ }, { order_by => 'name DESC'})->all;
  cmp_ok(@art, '==', 3, "Three artists returned");
};

# disable_sth_caching: disable_sth_caching must really turn off statement handle caching.
##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## This test uses undocumented internal methods
## DO NOT USE THEM IN THE SAME MANNER
## They are subject to ongoing change
##!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subtest 'disable_sth_caching' => sub {
  # Set up the "usual" sqlite
  my $schema = DBIO::SQLite::Test->init_schema();
  my $dbh = $schema->storage->_get_dbh;

  my $sth_one = $schema->storage->_prepare_sth($dbh, 'SELECT 42');
  my $sth_two = $schema->storage->_prepare_sth($dbh, 'SELECT 42');
  $schema->storage->disable_sth_caching(1);
  my $sth_three = $schema->storage->_prepare_sth($dbh, 'SELECT 42');

  ok($sth_one == $sth_two, "statement caching works");
  ok($sth_two != $sth_three, "disabling statement caching works");
};

# error: broken on_connect/on_disconnect actions and DBI errors must surface as the proper exceptions and warnings.
subtest 'error' => sub {
  for my $conn_args (
    [ on_connect_do   => "_NOPE_" ],
    [ on_connect_call => sub { shift->_dbh->do("_NOPE_") } ],
    [ on_connect_call => "_NOPE_" ],
  ) {
    for my $method (qw( ensure_connected _server_info _get_server_version _get_dbh )) {

      my $s = DBIO::SQLite::Test->init_schema(no_deploy => 1,
        on_disconnect_call => sub { fail 'Disconnector should not be invoked' },
        @$conn_args
      );

      my $storage = $s->storage;
      $storage = $storage->master
        if $storage->isa('DBIO::Storage::DBI::Replicated');

      ok( ! $storage->connected, 'Starting unconnected' );

      my $desc = "calling $method with broken on_connect action @{[ explain $conn_args ]}";

      throws_ok { $storage->$method }
        qr/ _NOPE_ \b/x,
        "Throwing correctly when $desc";

      ok( ! $storage->connected, "Still not connected after $desc" );

      # this checks that the on_disconect_call FAIL won't trigger
      $storage->disconnect;
    }
  }

  for my $conn_args (
    [ on_disconnect_do   => "_NOPE_" ],
    [ on_disconnect_call => sub { shift->_dbh->do("_NOPE_") } ],
    [ on_disconnect_call => "_NOPE_" ],
  ) {
    my $s = DBIO::SQLite::Test->init_schema(no_deploy => 1, @$conn_args );

    my $storage = $s->storage;
    $storage = $storage->master
      if $storage->isa('DBIO::Storage::DBI::Replicated');

    my $desc = "broken on_disconnect action @{[ explain $conn_args ]}";

    # connect + ping
    my $dbh = $storage->dbh;

    ok ($dbh->FETCH('Active'), 'Freshly connected DBI handle is healthy');

    warnings_exist { eval { $storage->disconnect } } [
      qr/\QDisconnect action failed\E .+ _NOPE_ \b/x
    ], "Found warning of failed $desc";

    ok (! $dbh->FETCH('Active'), "Actual DBI disconnect was not prevented by $desc" );
  }

  my $schema = DBIO::SQLite::Test->init_schema();

  warnings_are ( sub {
    throws_ok (
      sub {
        $schema->resultset('CD')->create({ title => 'vacation in antarctica' })
      },
      qr/DBI Exception.+(?x:
        \QNOT NULL constraint failed: cd.artist\E
          |
        \Qcd.artist may not be NULL\E
      )/s
    );  # as opposed to some other error
  }, [], 'No warnings besides exception' );

  my $dbh = $schema->storage->dbh;

  throws_ok (
    sub {
      $dbh->do ('INSERT INTO nonexistent_table VALUES (1)')
    },
    qr/DBI Exception.+no such table.+nonexistent_table/s,
    'DBI exceptions properly handled by dbic-installed callback'
  );

  # This usage is a bit unusual but it was actually seen in the wild
  # destruction of everything except the $dbh should use the proper
  # exception fallback:

  SKIP: {
    if ( !!peepeeness ) {
      skip "Your perl version $] appears to leak like a sieve - skipping garbage collected \$schema test", 1;
    }

    undef ($schema);
    throws_ok (
      sub {
        $dbh->do ('INSERT INTO nonexistent_table VALUES (1)')
      },
      qr/DBI Exception.+unhandled by DBIO.+no such table.+nonexistent_table/s,
      'callback works after $schema is gone'
    );
  }
};

done_testing;
