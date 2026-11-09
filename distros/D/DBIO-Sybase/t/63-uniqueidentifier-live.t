use strict;
use warnings;

use Test::More;
use DBI;
use FindBin;
use lib "$FindBin::Bin/lib";
use AseDatabase;
use AseNoFkActions;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;
use DBIO::Test::Schema;
use DBIO::Sybase::DDL;
use DBIO::Sybase::Deploy;
use DBIO::Sybase::Diff;
use DBIO::Sybase::Introspect;

# LIVE (karr k52). The counterpart of what t/45-ddl-util.t and t/40-diff.t pin
# offline: DBIO::Sybase::DDL renders `uniqueidentifier` as VARCHAR(36), passes
# a type name it does not know through, and refuses is_auto_increment on a
# type known not to be numeric, pointing at auto_nextval. Offline that is a
# string. This file is where the server is asked.
#
# CLAIMED, as plain tests:
#
#   1. A table with uniqueidentifier columns -- the key, without
#      is_auto_increment, and a nullable one -- installs through
#      DBIO::Sybase::Deploy->install; the catalog reads both back as
#      varchar(36); install -> diff against the same schema is empty.
#   2. A 36-character UUID with hyphens goes in through the storage and comes
#      back as written, also in upper case; the server's own newid() (32
#      characters) and newid(1) (36) fit the column.
#   3. Why the mapping is needed: the server's answer to the type itself.
#        CREATE TABLE .. (x uniqueidentifier NOT NULL)
#          -> Msg 2715: Can't find type 'uniqueidentifier'.
#   4. Why the refusal is right: the server's answer to what the driver would
#      have had to send,
#        CREATE TABLE .. (x VARCHAR(36) IDENTITY, y INT NULL)
#          -> Msg 2764: Identity field 'x' must be a numeric with a scale of
#             0. It may not be nullable or encrypted.
#      and install on a schema with such a column croaks before any statement
#      reaches the server: the table that comes before it in the DDL is not
#      there either.
#   5. SERVER BEHAVIOUR, not a wish of this driver: which types ASE takes
#      with IDENTITY. As sent, `CREATE TABLE t (x <type> IDENTITY, y INT NULL)`:
#
#        INT  SMALLINT  TINYINT  BIGINT                         accepted
#        UNSIGNED INT  UNSIGNED SMALLINT  UNSIGNED BIGINT       accepted
#        NUMERIC(10,0)  NUMERIC(38,0)  NUMERIC (is 18,0)        accepted
#        NUMERIC(10,2)  NUMERIC(18,6)                           Msg 2764
#        DECIMAL(10,0)  DECIMAL(10,2)                           Msg 2764
#        FLOAT  REAL  DOUBLE PRECISION                          Msg 2764
#        BIT  MONEY  SMALLMONEY                                 Msg 2764
#        VARCHAR  CHAR  UNICHAR  UNIVARCHAR  TEXT  UNITEXT      Msg 2764
#        DATETIME  SMALLDATETIME  TIME  BIGDATETIME  BIGTIME    Msg 2764
#        BINARY  VARBINARY  IMAGE                               Msg 2764
#
#      The last three lines are every type DBIO::Sybase::DDL refuses
#      is_auto_increment for: it refuses nothing the server would take.
#   6. The shared DBIO::Test::Schema without ArtistGUID -- 44 of its 45
#      sources, 40 tables and views (the note of the run counts them), 30
#      foreign keys -- installs, and a second deployment of it reads back
#      identically: the DBIO::Sybase::Diff of the two catalogs is empty.
#      t/31-introspect-roundtrip-live.t does this for 17 classes.
#   8. `mediumtext`, a name the map does not know (BindType.a_memo), is not an
#      ASE type either:  Msg 2715: Can't find type 'MEDIUMTEXT'.
#
# TODO test, red today (karr k52: the card's goal is the whole
# DBIO::Test::Schema installing on ASE). One per class left out in 6, each
# alone, in a database of its own. Today that is one class:
#
#   ArtistGUID           artistid is uniqueidentifier + is_auto_increment:
#                        the croak of 4. Nothing reaches the server.
#
#   Three more were left out once and install now: BindType (a_memo is
#   mediumtext, Msg 2715 before karr k70), TimestampPrimaryKey (a default of
#   \'current_timestamp', Msg 128 before karr k70/k52) and Dummy (its table is
#   `dummy`, an ASE keyword written bare, Msg 156 before karr k92; written
#   [dummy] now). core has no sqlt_deploy_hook that drops `dummy`, so it
#   belongs to the goal. What is to become of ArtistGUID is the maintainer's to
#   decide: the test says only that the class does not install.
#
# MEASURED, in the output as notes and asserted nowhere (karr k52, open):
#
#   7. auto_nextval, the attribute the croak of 4 points at. A class with a
#      uniqueidentifier column marked auto_nextval installs -- the attribute
#      renders no DDL -- and a create() that gives the column a value stores
#      it (asserted, both for the key and for a nullable column). A create()
#      that leaves it out -- or gives it as a literal, \'newid(1)' -- dies
#      before any statement is sent, for the key as for the nullable column:
#        Can't locate object method "_dbh_get_autoinc_seq" via package
#        "DBIO::Sybase::Storage::ASE::FreeTDS"
#      Nothing is fetched, no row with a NULL is written. The storage has
#      neither _dbh_get_autoinc_seq nor _sequence_fetch nor new_guid.
#
# MEASURED BESIDE THIS FILE on the same day, not run here:
#
#   * Where the driver renders IDENTITY and the server refuses it (Msg 2764
#     at CREATE TABLE): an is_auto_increment column of data_type numeric or
#     decimal without a size (rendered NUMERIC(18,6)) or with a scale above 0,
#     float, real (both FLOAT), double precision, boolean and bit (BIT), money
#     and smallmoney. Whether the driver should refuse these itself is the
#     card's fourth question; nothing here answers it.
#   * DBIO::Sybase::Deploy->diff cannot be run on the 41 sources of 6 on this
#     server. Its temporary database is made by a plain CREATE DATABASE and
#     has the server's `default database size`, here 24 MB of which 686 pages
#     of 16K are free; a table with a key takes 16 of them, an index 8. The
#     33rd table found the log segment full, and the session did not fail: it
#     was suspended by the server, for good. A probe went 300 seconds that
#     way. With `abort tran on log full` set on the temporary database the
#     same run dies with Msg 7412 and Msg 1105 instead. So 6 deploys twice
#     into databases this file makes large enough, and compares the two
#     catalogs with DBIO::Sybase::Diff itself -- what Deploy->diff does with
#     its two -- and every database made here has that option set.
#     (Since karr k69 DBIO::Sybase::Deploy sets the option on its temporary
#     database itself: diff on these sources no longer hangs, it dies of
#     Msg 1105. It still cannot be run on them here -- the temporary database
#     is as small as it was. t/71-temp-db-log-full-live.t.)
#   * fourkeys.sensors is declared character(10) and deploys as char(1):
#     `character` is no name the map knows, so it goes through bare and
#     without its size. Both deployments agree, so the diff of 6 is empty.
#
# Measured 2026-10-05 against SAP ASE 16.0 SP02 PL02 (16K pages), with
# DBD::Sybase 1.27 built against FreeTDS 1.3.17, TDS 5.0. What this file does
# NOT claim:
#
#   * that VARCHAR(36) checks anything. It is a string column: any string up
#     to 36 characters goes in, a GUID or not, and what the server does with a
#     longer one was not looked at.
#   * that rows of DBIO::Test::Schema can be written. 6 installs and reads the
#     catalog; no row goes into those tables here.
#   * anything about the Sybase Open Client libraries, or about another
#     server: the page size and the default database size decide what fits.
#   * how any of the four open questions of karr k52 is to be answered.
#
# Runs in throwaway databases it creates and drops itself, 48 MB the largest;
# needs a login allowed to CREATE DATABASE and to set a database option (sa on
# the docker/k8s ASE image). Every schema loads the Sybase component, as a
# schema has to since core ADR 0067 (karr k90), and its storage becomes the
# ASE class at the first use (karr k64, t/62-component-rebless-live.t). Until
# k90 they named no storage_type and the storage was detected from the DSN:
# the runs this file describes were made that way, and none with the
# component yet.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

my $K52 = 'karr k52: the whole DBIO::Test::Schema is to install on ASE';

my $NO_IDENTITY = q{Msg 2764: Identity field 'x' must be a numeric with a }
                . q{scale of 0. It may not be nullable or encrypted.};

my $UUID = '123e4567-e89b-12d3-a456-426614174000';

# ------------------------------------------------------------ the schemas

{
  package T::K52::Result::Guid;
  use base 'DBIO::Core';
  __PACKAGE__->table('k52_guid');
  __PACKAGE__->add_columns(
    id         => { data_type => 'uniqueidentifier' },
    other_guid => { data_type => 'uniqueidentifier', is_nullable => 1 },
    name       => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

# What the croak of DBIO::Sybase::DDL tells the author of a GUID key to write.
{
  package T::K52::Result::NextvalKey;
  use base 'DBIO::Core';
  __PACKAGE__->table('k52_nextval_key');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uniqueidentifier', auto_nextval => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

# The shape of DBIO::Test::Schema::ArtistGUID.a_guid.
{
  package T::K52::Result::NextvalNullable;
  use base 'DBIO::Core';
  __PACKAGE__->table('k52_nextval_nullable');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer', is_auto_increment => 1 },
    a_guid => { data_type => 'uniqueidentifier', is_nullable => 1, auto_nextval => 1 },
    name   => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K52::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class($_ => "T::K52::Result::$_")
    for qw(Guid NextvalKey NextvalNullable);
}

# The shape of DBIO::Test::Schema::ArtistGUID.artistid, and a table that
# comes before it in the DDL: install_ddl goes through the sources by name.
{
  package T::K52::Result::Before;
  use base 'DBIO::Core';
  __PACKAGE__->table('k52_before');
  __PACKAGE__->add_columns( id => { data_type => 'integer' } );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K52::Result::GuidAutoInc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k52_guid_autoinc');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uniqueidentifier', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K52::Refused;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class($_ => "T::K52::Result::$_") for qw(Before GuidAutoInc);
}

# The classes of DBIO::Test::Schema that do not install today, and why (the
# head of this file has the server's words). Everything else is section 6.
my %NOT_YET = (
  ArtistGUID          => 'artistid is uniqueidentifier + is_auto_increment, '
                       . 'which DBIO::Sybase::DDL refuses',
);

# A schema of result classes of DBIO::Test::Schema (not redefined here).
my $shared_schemas = 0;
sub shared_schema {
  my @classes = @_;
  my $schema_class = 'T::K52::Shared' . ++$shared_schemas;
  {
    no strict 'refs';
    @{"${schema_class}::ISA"} = ('DBIO::Schema');
  }
  $schema_class->load_components('Sybase');
  $schema_class->load_classes({ 'DBIO::Test::Schema' => [ @classes ] });
  # The shared classes declare referential actions, which ASE cannot do and
  # the DDL refuses (karr k91); this test is about the column types.
  AseNoFkActions::strip($schema_class);
  return $schema_class;
}

# ------------------------------------------------------------ the helpers

# The server's address and the login are the environment's and stay out of the
# output: of an error, what the server said -- "Msg <number>: <text>" -- or,
# where it was not the server, one line of it.
sub said {
  my $text = shift // '';

  # An exception of the storage carries the server's message twice.
  my (@messages, %seen);
  while ($text =~ /
    Server\ message\ number=(\d+) [^\n]*? \btext=(.*?) \s*
    (?= Server\ message\ number= | \[for\ Statement | \ at\ \S+\ line\ \d+ | \z )
  /gsx) {
    push @messages, "Msg $1: $2" unless $seen{"$1: $2"}++;
  }
  return join ' | ', @messages if @messages;

  $text =~ s/ at \S+ line \d+.*//s;
  $text =~ s/\b(host|port)=[^;\s]*/$1=../g;
  $text =~ s/\Q$pass\E/../g if length $pass;
  $text =~ s/\s+/ /g;
  return length $text > 400 ? substr($text, 0, 400) . ' ...' : $text;
}

# The value of $code. If it died, undef -- and why() says what of.
my $why;
sub tried (&) {
  my $code = shift;
  undef $why;
  my $value;
  eval { $value = $code->(); 1 } or $why = said($@);
  return $value;
}
sub why { diag '  ' . ( $why // '(it did not die)' ) }

# What the server says to one statement: nothing, or said() of its refusal.
sub refusal {
  my ($dbh, $sql) = @_;
  local $dbh->{RaiseError} = 0;
  return defined $dbh->do($sql) ? '' : said($dbh->errstr);
}

# Plain DBI, with the DSN as it was given, kept in master: to make and drop
# the databases, and to look into them from outside any storage under test.
#
# ASE waits for a lock without limit; with a lock wait set a look at a table
# somebody left locked fails after ten seconds (Msg 12205) instead.
my $admin;
sub admin {
  return $admin ||= do {
    my $dbh = DBI->connect($dsn, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('set lock wait 10');
    $dbh->do('use master');
    $dbh;
  };
}

sub server_value  { ( admin()->selectrow_array(@_) )[0] }
sub server_column { @{ admin()->selectcol_arrayref(@_) } }

sub user_tables {
  my $db = shift;
  return server_column("select name from $db..sysobjects where type = 'U' order by name");
}

# This process' databases: the ones made here, and the temporary ones of
# DBIO::Sybase::Deploy->diff.
sub databases_there {
  return server_column(sprintf
    q{select name from master..sysdatabases }
  . q{where name like 'dbio[_]k52[_]%d[_]%%' or name like '[_]dbio[_]tmp[_]%d[_]%%'},
    $$, $$
  );
}

# Drops them, and returns what the server kept, each with its reason. The
# server may refuse a drop for a moment (Msg 3702, karr k74): repeated in
# t/lib/AseDatabase.pm.
sub drop_databases {
  return map { my $said = AseDatabase::drop(admin(), $_); $said ? "$_: $said" : () }
    databases_there();
}

sub dsn_for {
  my $db = shift;
  my $db_dsn = $dsn;
  $db_dsn =~ s/\bdatabase=[^;]*/database=$db/i
    or $db_dsn .= ( $dsn =~ /:$/ ? '' : ';' ) . "database=$db";
  return $db_dsn;
}

# Everything connected into the database of the section that is running.
my @open;

sub connected {
  my ($schema_class, $db) = @_;
  my $schema = $schema_class->connect(dsn_for($db), $user, $pass, {
    on_connect_do => [ 'set lock wait 10' ],
  });
  push @open, sub { $schema->storage->disconnect };
  $schema->storage->ensure_connected;
  return $schema;
}

sub handle_into {
  my $db  = shift;
  my $dbh = DBI->connect(dsn_for($db), $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
  });
  push @open, sub { $dbh->disconnect };
  $dbh->do('set lock wait 10');
  return $dbh;
}

# Runs $code, handed its name, in a database made for it, and drops it again
# -- also when $code dies, which fails a test of its own. So does a database
# the server keeps (karr k74): the sections after it run all the same. Returns
# what $code returned.
#
# Every database gets `abort tran on log full`. Without it a session that
# fills the database is not refused but suspended until somebody frees log
# space, and nobody does: the statement never returns (see the head of this
# file). With it the statement dies of Msg 1105. $size is for the section
# that needs more than the server's default.
sub in_database {
  my ($tag, $size, $code) = @_;

  my $db = "dbio_k52_${$}_$tag";

  admin()->do("create database $db" . ( $size ? " on default = '$size'" : '' ));
  {
    # sp_dboption reports what it did in two messages of severity 10.
    my $dbh = admin();
    local $dbh->{syb_err_handler} = sub { $_[1] > 10 ? 1 : 0 };
    my $sth = admin()->prepare("exec sp_dboption '$db', 'abort tran on log full', true");
    $sth->execute;
    do { 1 while $sth->fetchrow_arrayref } while $sth->{syb_more_results};
  }
  die "could not set 'abort tran on log full' on $db\n"
    unless server_value("select status2 & 1 from master..sysdatabases where name = '$db'");

  my @returned;
  my $lived = eval { @returned = $code->($db); 1 };
  my $error = $@;

  eval { $_->() } for splice @open;
  my $kept = AseDatabase::drop(admin(), $db);

  fail("the section in database $tag ran through"), diag '  ' . said($error)
    unless $lived;
  fail("the database of section $tag is dropped"), diag "  $kept"
    if $kept;

  return wantarray ? @returned : $returned[0];
}

sub model_of { DBIO::Sybase::Introspect->new(dbh => $_[0]->storage->dbh)->model }

sub column_of {
  my ($model, $table, $column) = @_;
  my ($found) = grep { $_->{column_name} eq $column } @{ $model->{columns}{$table} // [] };
  return $found ? [ @$found{qw(data_type size not_null)} ] : undef;
}

my $live = 1;   # past every skip_all: from here on there is something to drop

# what a run of this process id that died left behind
if (my @kept = drop_databases()) { die "in the way of this test: @kept\n" }

note 'client library: ' . ( admin()->{syb_oc_version} || '(unknown)' );
note 'server: ' . said( ( split /\n/, server_value('select @@version') )[0] );

# ================= 1, 2, 3, 5, 7, 8: one database, the server's default size

in_database a => undef, sub {
  my $db = shift;

  my $schema = connected('T::K52::Schema', $db);
  my $deploy = DBIO::Sybase::Deploy->new(schema => $schema);

  note 'the storage is a ' . ref $schema->storage;

  # ------------------------------------------------------- 1. round trip
  ok tried { $deploy->install; 1 },
    'a schema with uniqueidentifier columns installs' or why();

  my $model = ( tried { model_of($schema) } ) // {};

  is_deeply [ sort keys %{ $model->{tables} // {} } ],
    [qw(k52_guid k52_nextval_key k52_nextval_nullable)],
    'its three tables are read back from the catalog';

  is_deeply column_of($model, k52_guid => 'id'), [ 'varchar', 36, 1 ],
    'the uniqueidentifier key reads back as varchar(36) NOT NULL';
  is_deeply column_of($model, k52_guid => 'other_guid'), [ 'varchar', 36, 0 ],
    'the nullable uniqueidentifier column reads back as varchar(36) NULL';
  is_deeply column_of($model, k52_nextval_key => 'id'), [ 'varchar', 36, 1 ],
    'auto_nextval renders no DDL: that key is a varchar(36) NOT NULL like '
    . 'the other';

  # Nothing but the schema's tables is in the database yet: the diff below
  # compares all of it with a fresh deployment.
  my $diff = tried { $deploy->diff };
  ok $diff && !$diff->has_changes,
    'install -> diff against the same schema is empty'
    or ( $diff ? diag( $diff->as_sql ) : why() );

  # ----------------------------------------------------------- 2. values
  my $guids = $schema->resultset('Guid');
  my $raw   = handle_into($db);   # beside the storage: what the server holds

  ok tried { $guids->create({ id => $UUID, name => 'hyphenated' }); 1 },
    'a 36-character UUID with hyphens is inserted through the storage' or why();

  is tried { $guids->find($UUID)->id }, $UUID,
    '... and comes back through the storage as written' or why();

  is_deeply tried { [ $raw->selectrow_array(
      q{select id, char_length(id), other_guid from k52_guid where name = 'hyphenated'}
    ) ] },
    [ $UUID, 36, undef ],
    '... the server holds all 36 characters of it, and NULL in the nullable '
    . 'column left out' or why();

  is tried {
      $guids->create({ id => uc $UUID, other_guid => $UUID, name => 'upper case' });
      join ' ', map { $_->id, $_->other_guid } $guids->search({ name => 'upper case' })->all;
    },
    uc($UUID) . " $UUID",
    'it is a string, not a GUID: the same value in upper case is another '
    . 'key, and comes back in upper case' or why();

  is_deeply tried {
      $raw->do(q{insert into k52_guid (id, other_guid, name) select newid(), newid(1), 'newid'});
      [ $raw->selectrow_array(
        q{select char_length(id), char_length(other_guid) from k52_guid where name = 'newid'}
      ) ];
    },
    [ 32, 36 ],
    q{the server's newid() -- 32 characters -- and newid(1) -- 36, hyphenated }
    . q{-- fit the column} or why();

  # --------------------------------------------------- 7. auto_nextval
  #
  # A value given is stored: asserted. A value left out is the open question
  # (karr k52): measured, and written to the output as a note.
  is tried {
      $schema->resultset('NextvalKey')->create({ id => $UUID, name => 'given' });
      $raw->selectrow_array(q{select id from k52_nextval_key where name = 'given'});
    },
    $UUID,
    'auto_nextval on a uniqueidentifier key: a value given is stored' or why();

  is tried {
      $schema->resultset('NextvalNullable')->create({ a_guid => $UUID, name => 'given' });
      $raw->selectrow_array(q{select a_guid from k52_nextval_nullable where name = 'given'});
    },
    $UUID,
    'auto_nextval on a nullable uniqueidentifier column beside an IDENTITY '
    . 'key: a value given is stored' or why();

  for my $measure (
    [ NextvalKey      => 'k52_nextval_key',      'id',     {} ],
    [ NextvalNullable => 'k52_nextval_nullable', 'a_guid', {} ],
    [ NextvalKey      => 'k52_nextval_key',      'id',     { id => \'newid(1)' } ],
  ) {
    my ($source, $table, $column, $values) = @$measure;
    my $name = %$values ? 'literal' : 'left out';

    my $row  = tried { $schema->resultset($source)->create({ %$values, name => $name }) };
    my $died = $why;
    my $held = tried {
      join ', ', map { $_ // 'NULL' } @{ $raw->selectcol_arrayref(
        "select $column from $table where name = '$name'"
      ) };
    };

    note "MEASURED, not asserted (karr k52): $source->create with $column "
       . ( %$values ? 'given as the literal newid(1)' : 'left out' ) . ': '
       . ( $row ? 'lived, the object has ' . ( $row->get_column($column) // 'undef' )
                : "died: $died" )
       . '; rows of it on the server: ' . ( length( $held // '' ) ? $held : 'none' );
  }

  # --------------------- 3, 8: what the server says to the types themselves
  is refusal($raw, 'CREATE TABLE k52_raw_guid (x uniqueidentifier NOT NULL)'),
    q{Msg 2715: Can't find type 'uniqueidentifier'.},
    'SERVER: uniqueidentifier is no ASE type -- what a passed-through name '
    . 'gets';

  is refusal($raw, 'CREATE TABLE k52_raw_memo (id INT NOT NULL, a_memo MEDIUMTEXT NULL)'),
    q{Msg 2715: Can't find type 'MEDIUMTEXT'.},
    'SERVER: neither is mediumtext, which DBIO::Sybase::DDL does pass '
    . 'through (BindType.a_memo)';

  # ------------------------------------- 4, 5: IDENTITY, type by type
  is refusal($raw, 'CREATE TABLE k52_raw_identity (x VARCHAR(36) IDENTITY, y INT NULL)'),
    $NO_IDENTITY,
    'SERVER: IDENTITY on a VARCHAR(36) is refused -- the statement '
    . 'DBIO::Sybase::DDL croaks instead of sending';

  my $n = 0;
  for my $case (
    # the integers
    [ 'INT'               => 1 ],
    [ 'SMALLINT'          => 1 ],
    [ 'TINYINT'           => 1 ],
    [ 'BIGINT'            => 1 ],
    [ 'UNSIGNED INT'      => 1 ],
    [ 'UNSIGNED SMALLINT' => 1 ],
    [ 'UNSIGNED BIGINT'   => 1 ],
    # NUMERIC with a scale of 0 -- which a bare NUMERIC has
    [ 'NUMERIC(10,0)'     => 1 ],
    [ 'NUMERIC(38,0)'     => 1 ],
    [ 'NUMERIC'           => 1 ],
    # NUMERIC with a scale, and DECIMAL whatever its scale
    [ 'NUMERIC(10,2)'     => 0 ],
    [ 'NUMERIC(18,6)'     => 0 ],
    [ 'DECIMAL(10,0)'     => 0 ],
    [ 'DECIMAL(10,2)'     => 0 ],
    # the rest of what DBIO::Sybase::DDL counts as numeric
    [ 'FLOAT'             => 0 ],
    [ 'REAL'              => 0 ],
    [ 'DOUBLE PRECISION'  => 0 ],
    [ 'BIT'               => 0 ],
    [ 'MONEY'             => 0 ],
    [ 'SMALLMONEY'        => 0 ],
    # what DBIO::Sybase::DDL refuses is_auto_increment for (VARCHAR is above)
    [ 'CHAR(10)'          => 0 ],
    [ 'UNICHAR(10)'       => 0 ],
    [ 'UNIVARCHAR(10)'    => 0 ],
    [ 'TEXT'              => 0 ],
    [ 'UNITEXT'           => 0 ],
    [ 'DATETIME'          => 0 ],
    [ 'SMALLDATETIME'     => 0 ],
    [ 'TIME'              => 0 ],
    [ 'BIGDATETIME'       => 0 ],
    [ 'BIGTIME'           => 0 ],
    [ 'BINARY(16)'        => 0 ],
    [ 'VARBINARY(16)'     => 0 ],
    [ 'IMAGE'             => 0 ],
  ) {
    my ($type, $taken) = @$case;
    my $table = 'k52_identity_' . ++$n;

    my $refused = refusal($raw, "CREATE TABLE $table (x $type IDENTITY, y INT NULL)");

    if ($taken) {
      # Taken, and an identity column: the server numbers the row.
      is_deeply [
          $refused || 'accepted',
          tried {
            $raw->do("INSERT INTO $table (y) VALUES (7)");
            $raw->selectrow_array("SELECT x FROM $table") + 0;
          },
        ],
        [ 'accepted', 1 ],
        "SERVER: $type IDENTITY is accepted, and the first row gets 1" or why();
    }
    else {
      is $refused || 'accepted', $NO_IDENTITY,
        "SERVER: $type IDENTITY is refused";
    }

    refusal($raw, "DROP TABLE $table") unless $refused;
  }
};

# ====================================== 4. the croak, in an empty database

in_database b => undef, sub {
  my $db = shift;

  my $schema = connected('T::K52::Refused', $db);

  my $installed = tried { DBIO::Sybase::Deploy->new(schema => $schema)->install; 1 };

  ok !$installed, 'install on a schema with a uniqueidentifier + '
                . 'is_auto_increment column dies';

  like $why // '(it did not die)',
    qr/\ADBIO::Sybase: column id of table k52_guid_autoinc is is_auto_increment, .*\bVARCHAR\(36\) on ASE\b.*\bauto_nextval\b/s,
    '... of the driver\'s refusal, which names table, column and type and '
    . 'points at auto_nextval -- not of a server message';

  is_deeply [ user_tables($db) ], [],
    '... before any statement reached the server: the database is empty, '
    . 'k52_before -- ahead of the refused table in the DDL -- is not there';
};

# ================================= 6. DBIO::Test::Schema, all that installs

my %class_of = map {
  $_ => ( DBIO::Test::Schema->source($_)->result_class =~ s/.*:://r )
} DBIO::Test::Schema->sources;

my $installable = shared_schema(grep { !$NOT_YET{$_} } sort values %class_of);

# The tables and views the schema's sources stand for: several sources share
# the table artist, CustomSql is a query in place of a table, and a virtual
# view (Year1999CDs) exists in no database.
my %expected;
for my $name ($installable->sources) {
  my $source = $installable->source($name);
  my $view   = $source->isa('DBIO::ResultSource::View');
  my $table  = ref $source->name ? ${ $source->name } : $source->name;
  next if $table =~ /\s/ || ( $view && $source->is_virtual );
  $expected{$table} = $view ? 'view' : 'table';
}

my @foreign_keys = DBIO::Sybase::DDL->install_ddl($installable)
  =~ /^ALTER TABLE \S+ ADD CONSTRAINT (\S+) FOREIGN KEY/mg;

note scalar( $installable->sources ) . ' of the ' . scalar( keys %class_of )
   . ' sources of DBIO::Test::Schema: ' . scalar( keys %expected )
   . ' tables and views, ' . scalar(@foreign_keys) . ' foreign keys';

# Two deployments, one after the other, each into a database large enough:
# the catalog of each is all that is kept of it.
my @models = map {
  my $tag = $_;

  in_database $tag => '48M', sub {
    my $schema = connected($installable, shift);

    ok tried { DBIO::Sybase::Deploy->new(schema => $schema)->install; 1 },
      "DBIO::Test::Schema without @{[ sort keys %NOT_YET ]} installs ($tag)"
      or why();

    ( tried { model_of($schema) } ) // {};
  };
} qw(c1 c2);

is_deeply +{ map { $_ => $models[0]{tables}{$_}{kind} } keys %{ $models[0]{tables} // {} } },
  \%expected,
  'every table of it is read back from the catalog, and year2000cds as the '
  . 'view it is';

is_deeply [ sort map { $_->{constraint_name} } map { @$_ } values %{ $models[0]{foreign_keys} // {} } ],
  [ sort @foreign_keys ],
  'every foreign key the DDL adds is read back';

ok scalar( grep { ( $_->{origin} // '' ) ne 'pk' } map { values %$_ } values %{ $models[0]{indexes} // {} } ),
  'unique indexes are read back: the comparison below is not one of empty '
  . 'models';

# What DBIO::Sybase::Deploy->diff does with the live database and its
# temporary one, which is too small for this schema here (head of this file).
my $diff = tried { DBIO::Sybase::Diff->new(source => $models[0], target => $models[1]) };
ok $diff && !$diff->has_changes,
  'a second deployment reads back identically: the diff of the two '
  . 'catalogs is empty'
  or ( $diff ? diag( $diff->as_sql ) : why() );

# ===================== the classes left out of 6: what the card is to change

in_database d => undef, sub {
  my $db = shift;

  for my $class (sort keys %NOT_YET) {
    my $schema = connected(shared_schema($class), $db);

    local $TODO = "$K52 -- $NOT_YET{$class}";

    ok tried { DBIO::Sybase::Deploy->new(schema => $schema)->install; 1 },
      "DBIO::Test::Schema::$class installs" or why();
  }
};

# ================================================================ the end

is_deeply [ databases_there() ], [], 'nothing of this test is left on the server';

done_testing;

# The databases again, on a new connection: for a run that died on the way.
END {
  if ($live) {
    local $?;
    eval { $_->() } for splice @open;
    undef $admin;
    my @kept = eval { drop_databases() };
    diag "Could not clean up after this test: $_" for ( $@ ? said($@) : () ), @kept;
  }
}
