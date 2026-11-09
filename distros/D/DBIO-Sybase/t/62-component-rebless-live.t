use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use DBIO::Optional::Dependencies ();
use DBIO ();
use DBIO::Schema;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::Sybase::SQLMaker;
use DBIO::Sybase::Deploy;

# LIVE (karr k64; core k301, ADR 0059). The counterpart of
# t/59-component-rebless.t, which pins offline, against a handle that only
# plays a server, that a schema which declares this driver --
# load_components('Sybase'), or the -syb shortcut the POD of DBIO::Sybase
# recommends -- gets a DBIO::Sybase::Storage::ASE at its first use, through
# DBIO::Sybase::Storage::_adapt_to_access_path. This file says what that is
# worth against a real ASE: the calls of an application, one small case per
# kind, on every way to a storage.
#
# The same DSN, four ways, and the control that a schema without a declared
# driver is refused at connect (ADR 0067, karr k90):
#
#   component    load_components('Sybase'). The pin is this distribution's:
#                DBIO::Sybase::connection sets storage_type at every connect.
#   shortcut     use DBIO 'Schema', -syb. The pin is core's: the shortcut
#                loads no component, DBIO::Shortcut::syb hands the schema to
#                DBIO->apply_driver, which sets storage_type on the class.
#                These two are the declared ways, and the ones karr k64 is
#                about.
#   component,   the component again, connected with { quote_names => 0 }: the
#   quote_names  ASE class has to work with names unquoted too. (The way was a
#   off          second measurement while the storage stayed the base class,
#                see below; it is kept as a way of its own right.)
#   ASE pinned   storage_type('+DBIO::Sybase::Storage::ASE'): the class is the
#                user's word. The hook leaves the class alone, except for the
#                placeholder decision (karr k78; checked near the end).
#
# Every claim is a plain test on every way; among them, that the server is NOT
# asked what it is (no sp_server_info): a declared class stands (core k301).
#
# WHAT THESE TESTS WERE RED FOR, on the component and on the shortcut way
# (identical in every measurement), SAP ASE 16.0 SP02 PL02, 2026-10-05, while
# a declared storage stayed DBIO::Sybase::Storage for good -- 72 of this file's 145 tests
# were TODO tests then:
#
#   * The connect succeeded. The sql_maker was a DBIO::SQLMaker quoting names
#     with core's default, the double quote, and no statement it wrote got
#     past the server -- ASE reads "..." as a string literal unless the
#     session has set quoted_identifier on: SELECT, INSERT Msg 102, UPDATE,
#     DELETE Msg 156. So: connecting worked, reading or writing a row did not.
#   * With { quote_names => 0 } SELECT, UPDATE, DELETE, txn_do and populate in
#     void context worked, and what was left was worse than an error: create()
#     inserted the row and returned an object whose id was 0, without an error
#     or a warning (nothing read the IDENTITY value back), $row->update on it
#     died "row not found", populate in list context returned three objects
#     with id 0. An explicit IDENTITY value: Msg 584. rows -> LIMIT ?, Msg
#     102. No savepoints, no results_exist, rand -> RANDOM(), explain ->
#     EXPLAIN SELECT, and a DateTime written did not inflate when read.
#   * DBIO::Sybase::Deploy was never affected: dbio_deploy_class sits on the
#     base class, and the DDL is written by DBIO::Sybase::DDL.
#
# Driver resolution is lazy: it runs at the first use that needs the driver.
# Every storage is connected before anything is asked of it.
#
# Measured 2026-10-07 against SAP ASE 16.0 SP02 PL02, with DBD::Sybase 1.27
# built against FreeTDS 1.3.17, TDS 5.0. What this file does NOT claim:
#
#   * anything about the Sybase Open Client libraries. No connection here was
#     made with them. There the ASE class has a bulk storage and a working
#     TEXT/IMAGE writer, and populate in void context goes to the bulk-copy
#     API; none of that was run on any way.
#   * anything about a server that is not ASE. That a declared storage
#     reports Microsoft SQL Server and stays the ASE class is held offline
#     only, in t/59, against a handle that plays one.
#   * that the list is complete. One small case per kind of call; TEXT/IMAGE
#     columns, joins and prefetch, ordered and grouped pagination were not
#     run on the declared ways.
#   * anything about a transaction in which the server refuses a statement.
#     Every transaction here either runs through or dies of its block's own
#     error. A refused statement under a txn_scope_guard does not come out
#     right on any way (karr k65, t/64-txn-scope-guard-live.t).
#   * that a storage may be used before it is connected. Every storage here
#     is; populate as the first call on an ASE storage is known to die before
#     it connects (karr k67).

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

# InflateColumn::DateTime needs DateTime and DateTime::Format::Strptime, which
# this distribution does not require: section 6 skips without them.
my $HAVE_DT = DBIO::Optional::Dependencies->req_ok_for('test_dt');

my $ASE = 'DBIO::Sybase::Storage::ASE';

{
  package T::K64::Result::Item;
  use base 'DBIO::Core';
  __PACKAGE__->table('k64_live_item');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
    n    => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K64::Result::Event;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('InflateColumn::DateTime');
  __PACKAGE__->table('k64_live_event');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    seen_at => { data_type => 'datetime', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K64::Autodetect;
  use base 'DBIO::Schema';
}

{
  package T::K64::Component;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
}

{
  package T::K64::Shortcut;
  use DBIO 'Schema', -syb;
}

{
  package T::K64::ASE;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE');
}

for my $schema_class (map { "T::K64::$_" } qw(Autodetect Component Shortcut ASE)) {
  $schema_class->register_class($_ => "T::K64::Result::$_") for qw(Item Event);
}

my @WAYS = (
  { name => 'component',  schema => 'T::K64::Component' },
  { name => 'shortcut',   schema => 'T::K64::Shortcut' },
  { name => 'component, quote_names off', schema => 'T::K64::Component',
    attrs => { quote_names => 0 } },
  { name => 'ASE pinned', schema => 'T::K64::ASE' },
);

# Plain DBI, with the DSN as it was given: for setup, and for looking at what
# the server holds from another session and through no storage under test.
#
# ASE waits for a lock without limit. A storage under test that leaves a
# transaction open would hang this file at the next look at its rows; with a
# lock wait set, that look fails after ten seconds (Msg 12205) and takes its
# claim with it.
my $admin;
sub admin {
  return $admin ||= do {
    my $dbh = DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('set lock wait 10');
    $dbh;
  };
}

sub server_value  { ( admin()->selectrow_array(@_) )[0] }
sub server_column { @{ admin()->selectcol_arrayref(@_) } }

# The server's address and the login are the environment's and stay out of the
# output. One line, and no more of a stack trace than says what it is.
sub squashed {
  my $text = shift // '(undef)';
  $text =~ s/\b(host|port)=[^;\s]*/$1=../g;
  $text =~ s/\Q$pass\E/../g if length $pass;
  $text =~ s/\s+/ /g;
  return length $text > 480 ? substr($text, 0, 480) . ' ...' : $text;
}

my @TABLES = qw(k64_live_item k64_live_event);

sub tables_there {
  return server_column(
    q{select name from sysobjects where name like 'k64[_]live%' and type = 'U' }
  . q{order by name}
  );
}

sub drop_tables { admin()->do("drop table $_") for tables_there() }

# The temporary databases DBIO::Sybase::Deploy makes carry this process' id.
sub temp_databases {
  return server_column(sprintf
    q{select name from master..sysdatabases where name like '[_]dbio[_]tmp[_]%d[_]%%'},
    $$
  );
}

# Nine rows, n = 1 .. 9, with the ids a new IDENTITY column gives them. Every
# claim below has rows of its own, so that none depends on what another one
# managed to do.
sub fresh_tables {
  drop_tables();
  admin()->do(
    'create table k64_live_item ('
  . ' id int identity primary key, name varchar(100) null, n int null)'
  );
  admin()->do(
    'create table k64_live_event ('
  . ' id int identity primary key, seen_at datetime null)'
  );
  admin()->do("insert into k64_live_item (name, n) values ('seed $_', $_)")
    for 1 .. 9;
}

# What core says when a declared driver does not fit what it meets
# (DBIO::Storage::DBI::_driver_mismatch). The hook of this driver reports a
# server DBD::Sybase found to be Microsoft SQL Server; on an ASE nothing may
# be said, on any way. Every other warning goes where warnings go.
my @mismatches;
$SIG{__WARN__} = sub {
  return push @mismatches, $_[0] if $_[0] =~ /Driver mismatch/;
  warn @_;
};

# A new connection on $way, connected. Returns what a claim needs: the schema,
# the storage, what the connect asked the server through selectrow_arrayref,
# and -- emptied before every claim -- the statements sent since.
sub session {
  my ($way, %attrs) = @_;

  %attrs = ( %{ $way->{attrs} || {} }, %attrs );

  my $schema  = $way->{schema}->connect($dsn, $user, $pass, ( %attrs ? \%attrs : () ));
  my $storage = $schema->storage;

  my $at_connect = ref $storage;

  my @asked;
  {
    my $selectrow = DBI::db->can('selectrow_arrayref');
    no warnings 'redefine';
    local *DBI::db::selectrow_arrayref = sub { push @asked, $_[1]; goto &$selectrow };
    $storage->ensure_connected;
  }

  my @sent;
  my $trace = sub { push @sent, $_[1] };
  $storage->debugcb($trace);
  $storage->debug(1);

  # The ASE class sends the inserts that read an IDENTITY value back over a
  # second storage; debug reaches it, the callback has to be given.
  my $writer = $storage->can('_writer_storage') && $storage->_writer_storage;
  $writer->debugcb($trace) if $writer;

  return {
    way => $way, schema => $schema, storage => $storage,
    asked => \@asked, sent => \@sent, at_connect => $at_connect,
  };
}

sub hang_up { eval { $_[0]{storage}->disconnect } }

# One claim on one way. $code is handed the schema and returns what happened;
# that is compared with $expected, which may be a sub: it is called after
# $code, for what only the server knows by then. A $code that dies -- a
# statement the server refused -- fails the claim, and so does an $expected
# that dies.
#
# The statements sent go to the output either way: as a note where the claim
# holds, as a diag, with the error, where it does not.
sub holds {
  my ($s, $name, $code, $expected) = @_;

  @{ $s->{sent} } = ();
  my $got   = eval { [ $code->($s->{schema}) ] };
  my $error = $@;
  my @sent  = map { squashed($_) } @{ $s->{sent} };

  if (ref $expected eq 'CODE') {
    $expected = eval { [ $expected->() ] };
    $error  ||= $@;
  }

  $name = "$s->{way}{name}: $name";

  my $ran    = $got && $expected;
  my $ok     = $ran ? is_deeply($got, $expected, $name) : fail($name);
  my $report = $ok ? \&note : \&diag;

  $report->("  sent: $_") for @sent;
  $report->('  died: ' . squashed($error)) unless $ran;

  return $ok;
}

my $live = 1;   # past every skip_all: from here on there is something to drop

my $FREETDS = ( admin()->{syb_oc_version} || '' ) =~ /freetds/i;
my $dbname  = server_value('select db_name()');

note 'client library: ' . ( admin()->{syb_oc_version} || '(unknown)' );
note 'server: ' . squashed( ( split /\n/, server_value('select @@version') )[0] );

# A schema always has a driver (ADR 0067): the control is refused before a
# storage is built.
{
  my $refused = !eval { T::K64::Autodetect->connect($dsn, $user, $pass); 1 };
  my $error   = $@;

  ok $refused && $error =~
      /\QSchema class T::K64::Autodetect declares no driver\E.*\(ADR 0067\)/s,
    'a schema that names no storage_type is refused at connect -- a schema '
  . 'always has a driver (ADR 0067)'
    or diag 'it ' . ( $refused ? 'died: ' . squashed($error) : 'connected' );
}

for my $way (@WAYS) {

  note "==================== $way->{name}";

  fresh_tables();   # also what a run that died before its END block left

  my @seed_ids = server_column('select id from k64_live_item order by id');

  # ================================== 1. what the connect leaves behind
  {
    my $s       = session($way);
    my $storage = $s->{storage};

    note "$way->{name}: at connect the storage was a $s->{at_connect}, "
       . 'connected it is a ' . ref $storage;

    holds $s, 'the storage, once connected, is a ' . $ASE,
      sub { $storage->isa($ASE) ? $ASE : ref $storage },
      [ $ASE ];

    # A declared class, and one pinned by hand, is taken at its word (ADR 0059).
    holds $s, 'the server was NOT asked what it is (no sp_server_info)',
      sub { ( grep { /\Asp_server_info\b/ } @{ $s->{asked} } ) ? 'asked' : 'not asked' },
      [ 'not asked' ];

    note "$way->{name}: the connect asked, through selectrow_arrayref, "
       . ( join(', ', @{ $s->{asked} }) || 'nothing' );

    holds $s, 'its sql_maker is a DBIO::Sybase::SQLMaker',
      sub { ref $storage->sql_maker },
      [ 'DBIO::Sybase::SQLMaker' ];

    holds $s, 'names are quoted with [ ], the quote character ASE '
            . 'takes whatever the session\'s quoted_identifier is',
      sub { my $char = $storage->sql_quote_char; ref $char ? "@$char" : $char },
      [ '[ ]' ];

    # ASE's _init: _set_max_connect, and the writer storage behind section 2.
    holds $s, 'the ASE class\' _init ran: the stored DSN carries '
            . 'maxConnect=256',
      sub { grep { /\AmaxConnect=/ } split /;/, $storage->_dbi_connect_info->[0] },
      [ 'maxConnect=256' ];

    if ($FREETDS) {
      holds $s, 'DBD::Sybase being built against FreeTDS, the storage '
              . 'has the FreeTDS fixups mixed in',
        sub { $storage->isa('DBIO::Sybase::Storage::FreeTDS') ? 1 : 0 },
        [ 1 ];
    }
    else {
      note 'DBD::Sybase is not built against FreeTDS: no trait class to look for';
    }

    hang_up($s);
  }

  # ================================================ 2. rows: read and write
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    holds $s, 'a SELECT with a WHERE returns its rows',
      sub { map { $_->name } $rs->search({ n => { '>' => 7 } }, { order_by => 'id' })->all },
      [ 'seed 8', 'seed 9' ];

    holds $s, 'an UPDATE changes the row on the server',
      sub {
        $rs->search({ n => 1 })->update({ name => 'updated' });
        server_value('select name from k64_live_item where n = 1');
      },
      [ 'updated' ];

    holds $s, 'a DELETE removes the row on the server',
      sub {
        $rs->search({ n => 9 })->delete;
        server_value('select count(*) from k64_live_item where n = 9');
      },
      [ 0 ];

    holds $s, 'create() returns the IDENTITY value the server gave '
            . 'the row',
      sub { $rs->create({ name => 'created', n => 10 })->id },
      sub { server_value('select id from k64_live_item where n = 10') };

    holds $s, 'create() inside txn_do returns the IDENTITY value too',
      sub {
        my $schema = shift;
        $schema->txn_do(sub { $rs->create({ name => 'created in txn', n => 11 })->id });
      },
      sub { server_value('select id from k64_live_item where n = 11') };

    holds $s, 'the object create() returns can be updated: it knows '
            . 'its primary key',
      sub {
        my $row = $rs->create({ name => 'new', n => 12 });
        $row->update({ name => 'new, then changed' });
        server_value('select name from k64_live_item where n = 12');
      },
      [ 'new, then changed' ];

    holds $s, 'a row is created with an explicit value for the '
            . 'IDENTITY column',
      sub {
        my $row = $rs->create({ id => 500, name => 'explicit id', n => 13 });
        ( $row->id, server_value('select id from k64_live_item where n = 13') );
      },
      [ 500, 500 ];

    hang_up($s);
  }

  # ============================================================= 3. limits
  #
  # The ASE class takes a rows-only limit out of the statement and wraps it in
  # SET ROWCOUNT; its SQL maker slices rows + offset with GenericSubQ.
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    holds $s, 'rows => 2 returns the first two rows',
      sub { map { $_->id } $rs->search({}, { order_by => 'id', rows => 2 })->all },
      [ @seed_ids[0, 1] ];

    holds $s, 'rows => 2, offset => 1 returns the second and the third',
      sub {
        map { $_->id }
          $rs->search({}, { order_by => 'id', rows => 2, offset => 1 })->all
      },
      [ @seed_ids[1, 2] ];

    hang_up($s);
  }

  # ======================================================= 4. transactions
  #
  # A connection each: a transaction that went wrong is not the next claim's
  # starting point.
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    holds $s, 'txn_do commits what its block changed',
      sub {
        my $schema = shift;
        $schema->txn_do(sub { $rs->search({ n => 3 })->update({ name => 'committed' }) });
        server_value('select name from k64_live_item where n = 3');
      },
      [ 'committed' ];

    hang_up($s);
  }
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    holds $s, 'txn_do rolls back what its block changed when the '
            . 'block dies, and dies with the block\'s error',
      sub {
        my $schema = shift;
        my $lived  = eval {
          $schema->txn_do(sub {
            $rs->search({ n => 4 })->update({ name => 'never committed' });
            die "the block's own error\n";
          });
          1;
        };
        my $error = $lived                       ? 'lived'
                  : $@ =~ /the block's own error/ ? 'the block\'s own error'
                  :                                 squashed($@);
        ( $error, server_value('select name from k64_live_item where n = 4') );
      },
      [ 'the block\'s own error', 'seed 4' ];

    hang_up($s);
  }
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    holds $s, 'a savepoint is set and rolled back to inside a '
            . 'transaction: what came before it is committed, what '
            . 'came after it is not',
      sub {
        my $schema = shift;
        $schema->txn_do(sub {
          $rs->search({ n => 5 })->update({ name => 'before the savepoint' });
          $schema->storage->svp_begin('k64_live_sp');
          $rs->search({ n => 6 })->update({ name => 'after the savepoint' });
          $schema->storage->svp_rollback('k64_live_sp');
        });
        map { server_value("select name from k64_live_item where n = $_") } 5, 6;
      },
      [ 'before the savepoint', 'seed 6' ];

    hang_up($s);
  }

  # =========================================================== 5. populate
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    holds $s, 'populate in void context inserts every row',
      sub {
        $rs->populate([ map { { name => "populated $_", n => 100 + $_ } } 1 .. 3 ]);
        server_value('select count(*) from k64_live_item where n between 101 and 103');
      },
      [ 3 ];

    hang_up($s);
  }
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    holds $s, 'populate in list context returns objects that carry '
            . 'the IDENTITY values of their rows',
      sub {
        my @rows = $rs->populate(
          [ map { { name => "populated $_", n => 200 + $_ } } 1 .. 3 ]
        );
        map { $_->id } @rows;
      },
      sub {
        server_column(
          'select id from k64_live_item where n between 201 and 203 order by n'
        )
      };

    hang_up($s);
  }

  # =========================================================== 6. DateTime
  #
  # The ASE class brings a parser for what the handle returns once
  # connect_call_datetime_setup has set it to ISO_strict, and a formatter for
  # what the server reads.
  {
    my $s = session($way, on_connect_call => 'datetime_setup');

    holds $s, 'the datetime parser is the ASE class\' own',
      sub { $s->{storage}->datetime_parser_type },
      [ 'DBIO::Sybase::Storage::ASE::DateTime::Format' ];

    holds $s, 'on_connect_call => \'datetime_setup\' makes the handle '
            . 'return a datetime as ISO_strict',
      sub {
        $s->{storage}->dbh->selectrow_array(
          q{select convert(datetime, '2004-08-21 14:36:48.500')}
        );
      },
      [ '2004-08-21T14:36:48.500Z' ];

    SKIP: {
      skip 'the round trip needs '
         . DBIO::Optional::Dependencies->req_missing_for('test_dt'), 1
        unless $HAVE_DT;

      require DateTime;   # an optional dependency, probed above

      my $seen = DateTime->new(
        year => 2004, month  => 8,  day    => 21,
        hour => 14,   minute => 36, second => 48, nanosecond => 500_000_000,
      );

      holds $s, 'a DateTime written to a datetime column comes back '
              . 'the same, to the millisecond',
        sub {
          my $events = shift->resultset('Event');
          $events->create({ seen_at => $seen });
          my $id    = server_value('select max(id) from k64_live_event');
          my ($row) = $events->search({ id => $id })->all;
          ( $row->seen_at . '', $row->seen_at->nanosecond );
        },
        [ '2004-08-21T14:36:48', 500_000_000 ];
    }

    hang_up($s);
  }

  # ========================================= 7. what only the ASE class has
  {
    my $s  = session($way);
    my $rs = $s->{schema}->resultset('Item');

    # Refused or allowed before any SQL: the capability is declared on ASE.
    holds $s, 'results_exist answers (supports_exists_query)',
      sub { $rs->search({ n => 2 })->results_exist },
      [ 1 ];

    holds $s, 'rand(2) returns two rows (NEWID(), not core\'s RANDOM())',
      sub { scalar( () = $rs->rand(2)->all ) },
      [ 2 ];

    holds $s, 'explain returns the query plan, and the session runs '
            . 'queries again afterwards',
      sub {
        my $plan = $rs->search({ n => 2 })->explain;
        ( ( ( grep { ( $_->[0] // '' ) =~ /QUERY PLAN/ } @$plan ) ? 'a plan' : 'no plan' ),
          $rs->search({ n => 2 })->count );
      },
      [ 'a plan', 1 ];

    hang_up($s);
  }

  # ============================================================= 8. Deploy
  #
  # Never depended on the storage's class: dbio_deploy_class sits on the base
  # class and the DDL is DBIO::Sybase::DDL's. The tables come from the
  # schema here, so the ones made above go first.
  {
    my $s = session($way);

    drop_tables();

    holds $s, 'DBIO::Sybase::Deploy->install creates the schema\'s '
            . 'tables',
      sub {
        DBIO::Sybase::Deploy->new(schema => shift)->install;
        tables_there();
      },
      [ sort @TABLES ];

    admin()->do('drop table k64_live_event')
      if grep { $_ eq 'k64_live_event' } tables_there();

    # The database may hold other tables than this file's; only what the diff
    # says about these two is looked at.
    holds $s, 'DBIO::Sybase::Deploy->diff, one of the two tables '
            . 'dropped again, is to create that one and nothing else',
      sub {
        ( my $sql = DBIO::Sybase::Deploy->new(schema => shift)->diff->as_sql )
          =~ tr/"[]//d;
        grep { /k64_live/ } $sql =~ /\b((?:CREATE|ALTER|DROP) TABLE \w+)/g;
      },
      [ 'CREATE TABLE k64_live_event' ];

    holds $s, '... and it leaves the session in its database and no '
            . 'temporary database behind',
      sub {
        ( $s->{storage}->dbh->selectrow_array('select db_name()'),
          scalar( () = temp_databases() ) );
      },
      [ $dbname, 0 ];

    hang_up($s);
  }
}

# ================================ pinned ASE class: the placeholder decision
# (karr k78). A storage pinned to the ASE class takes, at its first use, the
# decision the declared base takes on the same connection: the same class and
# the same auto_cast. Under FreeTDS that is NOT auto_cast across the board --
# CAST(? AS ..) dies there with Msg 12828 (k72) -- but whatever the declared
# base ends in on this very connection. Prepared for the live confirmation; the
# offline counterpart is t/92-pinned-ase-placeholders.t.
{
  my %seen;

  for my $way (
    (grep { $_->{name} eq 'component' } @WAYS),
    (grep { $_->{name} eq 'ASE pinned' } @WAYS),
  ) {
    my $s = session($way);
    my $storage = $s->{storage};

    $seen{ $way->{name} } = {
      class     => ref $storage,
      auto_cast => ( $storage->can('auto_cast') && $storage->auto_cast ) ? 1 : 0,
      writer    => ref( $storage->_writer_storage ),
    };

    my $got = $seen{ $way->{name} };
    note "$way->{name}: class $got->{class}, auto_cast $got->{auto_cast}, "
       . "writer storage $got->{writer}";

    # a placeholder in a WHERE clause (ASE refuses an untyped one in the select
    # list, Msg 7332), through a bind value
    my $value = eval {
      $storage->dbh->selectrow_array('select 7 where 1 = ?', {}, 1)
    };
    is $value, 7, "$way->{name}: a statement with a placeholder runs"
      or diag squashed($@);

    hang_up($s);
  }

  is_deeply $seen{'ASE pinned'}, $seen{component},
    'a storage pinned to the ASE class is, after its first use, of the class '
  . 'and has the auto_cast of the declared base on the same connection, and '
  . 'so is its writer storage';
}

# ================================================================ the end

# What the hook of the declared way reads the product from, without asking:
# DBD::Sybase sends "select @@version" at login and keeps the answer.
like admin()->{syb_server_version_string}, qr/\AAdaptive Server Enterprise\b/,
  'DBD::Sybase kept the server\'s version string at login, and it names ASE';

is_deeply \@mismatches, [],
  'no way to this ASE was reported as a driver mismatch';

drop_tables();

is_deeply [ tables_there(), temp_databases() ], [],
  'nothing of this test is left on the server';

done_testing;

# The tables again, and a temporary database of a diff that died, on a new
# connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    undef $admin;
    eval {
      drop_tables();
      for my $database (temp_databases()) {
        admin()->do('use master');
        my $said = AseDatabase::drop(admin(), $database) or next;
        diag "Could not drop $database: $said";
      }
      1;
    } or diag "Could not clean up after this test: $@";
  }
}
