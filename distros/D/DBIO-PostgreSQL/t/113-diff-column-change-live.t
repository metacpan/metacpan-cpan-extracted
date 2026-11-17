use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Deploy;
use DBIO::PostgreSQL::Diff::Column;
use DBIO::PostgreSQL::Introspect;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# Folded from several live files by subject (karr k158): every old file is a
# subtest named after it, with its own private database(s) as before, and
# its helpers in a package block of its own, since named subs and the
# lexicals they close over are file-global otherwise.

# LIVE test for karr k121, point U3: the type of a column changes between two
# enum or composite types, or between one of them and text.
#
# WHY it exists: t/113-diff-column-change.t pins the statements the diff
# writes; only a server says that it takes them, that the rows come through
# and that the database is the target's afterwards. Before the fix the diff
# wrote ALTER COLUMN ... TYPE without USING (and with the default still on the
# column), so enum to enum, composite to composite and text to either died
# with 'column "v" cannot be cast automatically to type ...'.
#
# For every case, in a private database (karr k81): the old column is made by
# hand with rows in it, the target is diffed against it, and then
#
#  1. the upgrade runs (or the diff is refused, and nothing changes);
#  2. the rows hold what they held;
#  3. a second diff finds nothing to do.

{
  package Fold113::TypeChange;
  use Test::More;

  # PostgreSQL reports in the language of lc_messages; this test matches the
  # server's English words, so its sessions are set to 'C' after the connect
  my @CONNECT = ({ PrintError => 0, PrintWarn => 0, on_connect_do => [q{SET lc_messages = 'C'}] });
  my $n = 0;

  {
    package T113L::Pub;
    use base 'DBIO::PostgreSQL::PgSchema';
    __PACKAGE__->pg_enum(e_new => [qw( a b )]);
    __PACKAGE__->pg_type(c_new   => { x => 'integer', y => 'text' });
    __PACKAGE__->pg_type(c_other => { x => 'integer' });
  }

  # The schema class whose table t has the column v as $column.
  sub target {
    my ($column, $default) = @_;
    my $result = 'T113L::Result::R' . ++$n;
    eval qq{
      package $result;
      use base 'DBIO::Core';
      __PACKAGE__->load_components('PostgreSQL::Result');
      1;
    } or die $@;
    $result->table('t');
    my %col = ref $column ? %$column : (data_type => $column);
    $col{is_nullable} = 1;
    $col{default_value} = \$default if defined $default;
    $result->add_columns(id => { data_type => 'bigint', is_nullable => 0 }, v => \%col);
    $result->set_primary_key('id');

    my $class = 'T113L::Schema::S' . ++$n;
    no strict 'refs';
    @{"${class}::ISA"} = ('DBIO::Schema');
    $class->load_components('PostgreSQL');
    $class->pg_schemas('public');
    $class->pg_schema_class(public => 'T113L::Pub');
    $class->register_class(T => $result);
    return $class;
  }

  sub enum   { +{ data_type => 'enum', pg_enum_type => 'e_new' } }
  sub comp   { +{ data_type => 'composite', pg_type_name => $_[0] } }

  sub values_of {
    my ($dbh) = @_;
    return $dbh->selectcol_arrayref('SELECT v::text FROM t ORDER BY id');
  }

  sub type_of {
    my ($dbh) = @_;
    return $dbh->selectrow_array(q{SELECT format_type(atttypid, atttypmod)
      FROM pg_attribute WHERE attrelid = 't'::regclass AND attname = 'v'});
  }

  # $old: the old column definition; @rows: the literals of v. Returns the
  # schema (connected) and the diff, or undef and the error.
  sub prepared {
    my ($tag, $old, $to, @rows) = @_;
    my @db  = PrivatePgDatabase->create($tag);
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
    $dbh->do($_) for
      q{CREATE TYPE e_old AS ENUM ('a', 'b')},
      q{CREATE TYPE c_old AS (x integer, y text)},
      "CREATE TABLE t (id bigint PRIMARY KEY, v $old)";
    my $i = 0;
    $dbh->do('INSERT INTO t VALUES (' . ++$i . ", $_)") for @rows;
    $dbh->disconnect;

    my $schema = $to->connect(@db, @CONNECT);
    my $diff = eval { $schema->pg_deploy->diff };
    return ($schema, $diff, $@);
  }

  sub settled {
    my ($label, $schema) = @_;
    my $again = eval { $schema->pg_deploy->diff };
    ok($again && !$again->has_changes, "$label: a second diff finds nothing to do")
      or diag $again ? $again->as_sql : $@;
  }

  # A case that must run: the type becomes $type, the rows read $want.
  sub runs {
    my (%c) = @_;
    my $label = $c{label};
    my ($schema, $diff, $error) = prepared($c{tag}, $c{old}, $c{to}, @{ $c{rows} });
    ok($diff, "$label: the diff is built") or diag $error;
    SKIP: {
      skip "$label: no diff", 5 unless $diff;
      like($diff->as_sql, $c{sql}, "$label: and says what it should") if $c{sql};
      # a change to or from an enum or composite type is lossy, and the old type is dropped
      ok(eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, "$label: the upgrade runs") or diag $@;
      my $dbh = $schema->storage->dbh;
      is(scalar type_of($dbh), $c{type}, "$label: the column has the target's type");
      is_deeply(values_of($dbh), $c{want}, "$label: and the rows hold what they held");
      $c{after}->($dbh) if $c{after};
      settled($label, $schema);
    }
    $schema->storage->disconnect;
  }

  subtest 'diff-column-type-change' => sub {
  # ---------------------------------------------------------------------------
  # enum -> another enum
  # ---------------------------------------------------------------------------
  runs(label => 'enum to enum', tag => 't113ee', old => 'e_old', to => target(enum()),
    rows => [ q{'a'}, q{'b'}, 'NULL' ], want => [ 'a', 'b', undef ], type => 'e_new',
    sql => qr/TYPE public\.e_new USING v::text::public\.e_new/);

  runs(label => 'enum to enum with a default', tag => 't113eed', old => q{e_old DEFAULT 'b'},
    to => target(enum(), q{'b'::e_new}),
    rows => [ q{'a'} ], want => ['a'], type => 'e_new',
    after => sub {
      my ($dbh) = @_;
      $dbh->do('INSERT INTO t (id) VALUES (2)');
      is_deeply(values_of($dbh), [ 'a', 'b' ], 'enum to enum with a default: the default works on the new type');
    });

  # ---------------------------------------------------------------------------
  # enum <-> text
  # ---------------------------------------------------------------------------
  runs(label => 'enum to text', tag => 't113et', old => 'e_old', to => target('text'),
    rows => [ q{'a'}, q{'b'} ], want => [ 'a', 'b' ], type => 'text');

  runs(label => 'enum to text with a default', tag => 't113etd', old => q{e_old DEFAULT 'b'},
    to => target('text', q{'b'::text}),
    rows => [ q{'a'} ], want => ['a'], type => 'text');

  runs(label => 'text to enum with a default', tag => 't113ted', old => q{text DEFAULT 'b'},
    to => target(enum(), q{'b'::e_new}),
    rows => [ q{'a'} ], want => ['a'], type => 'e_new',
    after => sub {
      my ($dbh) = @_;
      $dbh->do('INSERT INTO t (id) VALUES (2)');
      is_deeply(values_of($dbh), [ 'a', 'b' ], 'text to enum with a default: the default works on the new type');
    });

  runs(label => 'text to enum', tag => 't113te', old => 'text', to => target(enum()),
    rows => [ q{'a'}, q{'b'} ], want => [ 'a', 'b' ], type => 'e_new',
    sql => qr/TYPE public\.e_new USING v::text::public\.e_new/);

  # ---------------------------------------------------------------------------
  # composite -> composite of the same attributes, and composite <-> text
  # ---------------------------------------------------------------------------
  runs(label => 'composite to composite', tag => 't113cc', old => 'c_old', to => target(comp('c_new')),
    rows => [ q{'(1,z)'}, q{'(2,"a b")'}, 'NULL' ], want => [ '(1,z)', '(2,"a b")', undef ], type => 'c_new',
    sql => qr/TYPE public\.c_new USING v::text::public\.c_new/);

  runs(label => 'composite to text', tag => 't113ct', old => 'c_old', to => target('text'),
    rows => [ q{'(1,z)'} ], want => ['(1,z)'], type => 'text');

  runs(label => 'text to composite', tag => 't113tc', old => 'text', to => target(comp('c_new')),
    rows => [ q{'(1,z)'} ], want => ['(1,z)'], type => 'c_new',
    sql => qr/TYPE public\.c_new USING v::text::public\.c_new/);

  # ---------------------------------------------------------------------------
  # composite -> composite of other attributes: refused, nothing is changed
  # ---------------------------------------------------------------------------
  {
    my $label = 'composite to a composite of other attributes';
    my ($schema, $diff, $error) = prepared('t113cx', 'c_old', target(comp('c_other')), q{'(1,z)'});
    ok(!$diff, "$label: the diff dies");
    like($error, qr/\Arefusing to diff: column public\.t\.v changes from composite type public\.c_old to public\.c_other,/,
      "$label: with a refusal that names both types");
    my $dbh = $schema->storage->dbh;
    is(scalar type_of($dbh), 'c_old', "$label: the column is as it was");
    is_deeply(values_of($dbh), ['(1,z)'], "$label: and so are the rows");
    $schema->storage->disconnect;
  }

  # ---------------------------------------------------------------------------
  # text that is no value of the enum: the server refuses, the rows stay
  # ---------------------------------------------------------------------------
  {
    my $label = 'text that is no label of the enum';
    my ($schema, $diff, $error) = prepared('t113bad', 'text', target(enum()), q{'a'}, q{'zzz'});
    ok($diff, "$label: the diff is built") or diag $error;
    SKIP: {
      skip "$label: no diff", 3 unless $diff;
      # released, so that it is the server that refuses
      ok(!eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, "$label: the upgrade fails");
      like($@, qr/invalid input value for enum e_new: "\*\*\*"/, "$label: with the server's reason"); # the row value is masked, the enum stays
      my $dbh = $schema->storage->dbh;
      is_deeply([ scalar type_of($dbh), @{ values_of($dbh) } ], [ 'text', 'a', 'zzz' ],
        "$label: the column and its rows are as they were");
    }
    $schema->storage->disconnect;
  }
  };
}

# LIVE test for karr dbio-postgresql-postgis k28: a USING hook turns a type
# change the server cannot cast on its own (text to integer) into one it runs.
{
  package Fold113::UsingHook;
  use Test::More;

  {
    package T132L::Result::R;
    use base 'DBIO::Core';
    __PACKAGE__->load_components('PostgreSQL::Result');
    __PACKAGE__->table('t');
    __PACKAGE__->add_columns(
      id => { data_type => 'bigint', is_nullable => 0 },
      v  => { data_type => 'bigint', is_nullable => 1 },
    );
    __PACKAGE__->set_primary_key('id');

    package T132L::Schema;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('PostgreSQL');
    __PACKAGE__->pg_schemas('public');
    __PACKAGE__->register_class(T => 'T132L::Result::R');
  }

  subtest 'diff-column-using-hook' => sub {
  my $C = 'DBIO::PostgreSQL::Diff::Column';

  my @db  = PrivatePgDatabase->create('t132');
  my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
  $dbh->do($_) for
    'CREATE TABLE t (id bigint PRIMARY KEY, v text)',
    q{INSERT INTO t VALUES (1, '42'), (2, '7'), (3, NULL)};
  $dbh->disconnect;

  # PostgreSQL reports in the language of lc_messages; this test matches the
  # server's English words, so its session is set to 'C' after the connect
  my $schema = T132L::Schema->connect(@db,
    { PrintError => 0, PrintWarn => 0, on_connect_do => [q{SET lc_messages = 'C'}] });

  # Without a hook the server refuses the cast: the upgrade fails.
  {
    my $diff = $schema->pg_deploy->diff;
    unlike($diff->as_sql, qr/USING/, 'no hook: no USING');
    # text to bigint is lossy, so it is released: the refusal is the server's
    ok(!eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, 'no hook: the server refuses');
    like($@, qr/cannot be cast automatically/, '... with its own words, not the guard\'s');
  }

  $C->register_using_hook(t132 => sub { "$_[0]{column}::bigint" });
  eval {
    my $diff = $schema->pg_deploy->diff;
    like($diff->as_sql, qr/TYPE bigint USING v::bigint;/, 'hook: USING in the ALTER');
    ok(eval { $schema->pg_deploy->apply($diff, allow_destructive => 1); 1 }, 'hook: the upgrade runs (a USING makes the change lossy)') or diag $@;
    my $d = $schema->storage->dbh;
    is_deeply($d->selectcol_arrayref('SELECT v FROM t ORDER BY id'), [ 42, 7, undef ],
      'the values were converted');
    is(scalar $d->selectrow_array(q{SELECT format_type(atttypid, atttypmod) FROM pg_attribute
      WHERE attrelid = 't'::regclass AND attname = 'v'}), 'bigint', 'the column is bigint');
    1;
  } or diag $@;
  $C->unregister_using_hook('t132');
  $schema->storage->disconnect;

  };
}

# LIVE test for karr k121, U6 (points 5 and 8): a column changes its type
# while a policy, a trigger (WHEN, UPDATE OF), a generated column or a view
# outside the declared schemas reads it.
#
# WHY it exists: t/113-diff-column-change.t pins the
# refusal on a model written by hand; only a server says that the catalog
# gives the model these dependencies and that the way out the message names
# works. Before the fix the diff wrote ALTER COLUMN ... TYPE and the server
# refused it in mid-apply ("cannot alter type of a column used in a policy
# definition" and its siblings).
#
# For every case, in a private database (karr k81): the old objects are made
# by hand, then
#
#  1. the introspected model names the column the object reads;
#  2. the diff is refused, naming the column and the object, and the
#     database is untouched;
#  3. the statements the message gives run, and the upgrade then does;
#  4. the column has the target's type and a second diff finds nothing to do.
{
  package Fold113::OtherReaders;
  use Test::More;

  my @CONNECT = ({ PrintError => 0, PrintWarn => 0 });
  my $n = 0;

  sub target {
    my $result = 'T137L::Result::R' . ++$n;
    eval qq{
      package $result;
      use base 'DBIO::Core';
      __PACKAGE__->load_components('PostgreSQL::Result');
      1;
    } or die $@;
    $result->table('t');
    $result->add_columns(
      id => { data_type => 'bigint', is_nullable => 0 },
      v  => { data_type => 'bigint', is_nullable => 1 },
      w  => { data_type => 'integer', is_nullable => 1 },
    );
    $result->set_primary_key('id');

    my $class = 'T137L::Schema::S' . ++$n;
    no strict 'refs';
    @{"${class}::ISA"} = ('DBIO::Schema');
    $class->load_components('PostgreSQL');
    $class->pg_schemas('public');
    $class->register_class(T => $result);
    return $class;
  }

  my $TRIGGER_FUNCTION = q{CREATE FUNCTION f() RETURNS trigger LANGUAGE plpgsql
    AS $$ BEGIN RETURN NEW; END $$};

  my @CASES = (
    { tag => 'pol', label => 'policy',
      setup => [ 'ALTER TABLE t ENABLE ROW LEVEL SECURITY', 'CREATE POLICY p ON t USING (v > 0)' ],
      section => 'policies', object => 'p',
      named => qr/while policy p on public\.t depends on it/,
      way_out => qr/^  DROP POLICY p ON public\.t;$/m },
    { tag => 'twh', label => 'trigger WHEN',
      setup => [ $TRIGGER_FUNCTION,
        'CREATE TRIGGER tw BEFORE UPDATE ON t FOR EACH ROW WHEN (OLD.v IS DISTINCT FROM NEW.v) EXECUTE FUNCTION f()' ],
      section => 'triggers', object => 'tw',
      named => qr/while trigger tw on public\.t depends on it/,
      way_out => qr/^  DROP TRIGGER tw ON public\.t;$/m },
    { tag => 'tof', label => 'trigger UPDATE OF',
      setup => [ $TRIGGER_FUNCTION,
        'CREATE TRIGGER tu BEFORE UPDATE OF v ON t FOR EACH ROW EXECUTE FUNCTION f()' ],
      section => 'triggers', object => 'tu',
      named => qr/while trigger tu on public\.t depends on it/,
      way_out => qr/^  DROP TRIGGER tu ON public\.t;$/m },
    { tag => 'gen', label => 'generated column',
      setup => [ 'ALTER TABLE t ADD COLUMN g integer GENERATED ALWAYS AS (v * 2) STORED' ],
      named => qr/while generated column public\.t\.g depends on it/,
      way_out => qr/^  ALTER TABLE public\.t DROP COLUMN g;$/m },
    { tag => 'out', label => 'view outside the declared schemas',
      setup => [ 'CREATE SCHEMA other', 'CREATE VIEW other.vw AS SELECT v FROM public.t' ],
      named => qr/while view other\.vw \(outside the declared schemas\) depends on it/,
      way_out => qr/^  DROP VIEW other\.vw;$/m },
  );

  subtest 'diff-column-type-change-other-readers' => sub {
  for my $case (@CASES) {
    my $label = $case->{label};
    my @db = PrivatePgDatabase->create("t137$case->{tag}");
    my $dbh = LiveServer->control_dbh(login => \@db, attrs => { PrintWarn => 0 });
    $dbh->do($_) for 'CREATE TABLE t (id bigint PRIMARY KEY, v integer, w integer)',
      @{ $case->{setup} };
    $dbh->do('INSERT INTO t (id, v, w) VALUES (1, 5, 6), (2, 7, 8)');

    # 1. the model
    my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh, schema_filter => ['public'])->model;
    if ($case->{section}) {
      is_deeply $model->{ $case->{section} }{'public.t'}{ $case->{object} }{depends_on_columns},
        { 'public.t' => ['v'] }, "$label: the model names the column the object reads";
    } elsif ($case->{tag} eq 'gen') {
      my ($g) = grep { $_->{column_name} eq 'g' } @{ $model->{columns}{'public.t'} };
      is_deeply $g->{depends_on_columns}, ['v'], "$label: the model names the column it reads";
      my ($v) = grep { $_->{column_name} eq 'v' } @{ $model->{columns}{'public.t'} };
      is_deeply $v->{depends_on_columns}, [], "$label: and an ordinary column reads none";
    } else {
      is_deeply $model->{outside_readers}{'other.vw'}{depends_on_columns},
        { 'public.t' => ['v'] }, "$label: the model names the column the view reads";
      ok !exists $model->{tables}{'other.vw'}, "$label: and the view itself is not in the model";
    }
    $dbh->disconnect;

    # 2. the refusal
    my $schema = target()->connect(@db, @CONNECT);
    my $diff = eval { $schema->pg_deploy->diff };
    my $error = $@;
    is $diff, undef, "$label: the diff is refused";
    like $error, qr/\Arefusing to diff: column public\.t\.v changes its type from integer to bigint/,
      "$label: and names the column and both types";
    like $error, $case->{named}, "$label: and the object";
    like $error, $case->{way_out}, "$label: and the statement that takes it out of the way";
    unlike $error, qr/DBD::Pg|ERROR:/, "$label: and it is not the server's message";

    # 3. the way out runs, and the upgrade after it
    my @drop = $error =~ /^  ((?:DROP|ALTER) [^\n]+;)$/mg;
    ok @drop, "$label: the message has the statements";
    my $storage_dbh = $schema->storage->dbh;
    is scalar $storage_dbh->selectrow_array(q{SELECT format_type(atttypid, atttypmod)
        FROM pg_attribute WHERE attrelid = 't'::regclass AND attname = 'v'}),
      'integer', "$label: the column is as it was";
    ok eval { $storage_dbh->do($_) for @drop; 1 }, "$label: the statements run" or diag $@;

    my $again = eval { $schema->pg_deploy->diff };
    ok $again, "$label: the diff is built after it" or diag $@;
    SKIP: {
      skip "$label: no diff", 3 unless $again;
      ok eval { $schema->pg_deploy->apply($again, allow_destructive => 1); 1 }, "$label: the upgrade runs" or diag $@;
      is scalar $storage_dbh->selectrow_array(q{SELECT format_type(atttypid, atttypmod)
          FROM pg_attribute WHERE attrelid = 't'::regclass AND attname = 'v'}),
        'bigint', "$label: the column has the target's type";
      is_deeply $storage_dbh->selectcol_arrayref('SELECT v FROM t ORDER BY id'), [ 5, 7 ],
        "$label: and the rows hold what they held";
    }
    my $settled = eval { $schema->pg_deploy->diff };
    ok $settled && !$settled->has_changes, "$label: a second diff finds nothing to do"
      or diag $settled ? $settled->as_sql : $@;
    $schema->storage->disconnect;
  }
  };
}

done_testing;
