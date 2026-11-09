use strict;
use warnings;
use Test::More;

use DBI;
use DBIO::SQL::Util ();
use DBIO::Test::Conformance ();
use DBIO::Oracle::Test::Conformance ();
use DBIO::Oracle::Deploy ();
use DBIO::Oracle::Diff ();
use DBIO::Oracle::Introspect ();

# LIVE (karr k58). A source named 'schema.table' is a table in another schema
# (on Oracle a user): install writes it there, Introspect reads it as
# 'schema.table', Diff writes it qualified. What this file runs:
#
#   1. a schema (user) that does not exist is refused, loudly and before the
#      first statement -- needs no second user;
#   2. the whole cross-schema round for the connected user's own schema, which
#      needs no privilege beyond the ordinary ones: install into
#      "ME"."table", DML through the storage, introspect it as ME.table, a
#      diff of the model against itself is empty, DROP and CREATE written by
#      the diff and applied (A to B gives B, a second diff is empty), and
#      Deploy->diff, which builds the desired state with a temporary user for
#      each foreign schema: with the table dropped it finds that one table to
#      create, with it back nothing, and no DBIO_TMP_ user is left behind;
#   3. the same round into the schema of a second user, for which the connected
#      user needs the ANY privileges. It runs with DBIO_TEST_ORA_EXTRAUSER_DSN,
#      _USER and _PASS (as t/10 reads them; the maintainer's database has the
#      user dbio_x and the rights, maint/k8s/oracle.yaml) and skips, saying
#      why, without them or while the connected user lacks a privilege.
#   4. a foreign key between two schemas (a child in the second user's schema
#      referencing a table of the connected user): its owner grants REFERENCES
#      (the driver writes no GRANT); Deploy->diff, whose temp users grant each
#      other, finds nothing to do. Runs under the same conditions as 3.
#
# One run per database: the objects are named cs84_*, cleaned up before and after.

plan skip_all => 'DBIO_TEST_ORA_DSN not set (no Oracle to run against)'
  unless length($ENV{DBIO_TEST_ORA_DSN} // '');

my @connect = @ENV{qw(DBIO_TEST_ORA_DSN DBIO_TEST_ORA_USER DBIO_TEST_ORA_PASS)};
my $conf = 'DBIO::Oracle::Test::Conformance';
my $id = sub { +{ data_type => 'integer', is_nullable => 0 } };

my $admin = DBI->connect(@connect, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
my ($me) = $admin->selectrow_array('SELECT USER FROM DUAL');

sub schema_for {
  my ($name, @sources) = @_;
  my $class = DBIO::Test::Conformance->_build_schema_class(
    { name => $name, input => { sources => \@sources } });
  return $conf->conformance_connect($class);
}

# --- 1. a schema that does not exist -------------------------------------

{
  my $ghost = 'DBIO_NOSUCH_84_' . $$;
  my $schema = schema_for('ghost', {
    name => 'Ghost', table => "$ghost.cs84_t", columns => [ id => $id->() ], primary_key => ['id'] });
  my $err = eval { DBIO::Oracle::Deploy->new(schema => $schema)->install; 1 } ? undef : $@;
  ok $err, "install into the missing schema $ghost is refused";
  isa_ok $err, 'DBIO::Exception';
  isnt ref $err, 'DBIO::Exception::Server', '... by the driver, before the server was asked to create anything';
  like "$err", qr/refus/i,                  '... the text says refus';
  like "$err", qr/\Q$ghost\E/,              '... it names the user';
  like "$err", qr/does not exist/,          '... and says it does not exist';
  like "$err", qr/\Q$ghost.cs84_t\E/,       '... and the table';
  my ($n) = $admin->selectrow_array(
    q{SELECT COUNT(*) FROM all_users WHERE username = ?}, undef, $ghost);
  is $n, 0, '... and no user was made';
  $schema->storage->disconnect;
}

SKIP: {
  skip "the connected user $me is spelled in lower case already: no case hint to read", 3
    if $me eq lc $me;
  my $wrong = lc $me;
  my $schema = schema_for('wrongcase', {
    name => 'Wrong', table => "$wrong.cs84_t", columns => [ id => $id->() ], primary_key => ['id'] });
  my $err = eval { DBIO::Oracle::Deploy->new(schema => $schema)->install; 1 } ? undef : $@;
  ok $err, "the schema is taken as spelled: $wrong is not the user $me";
  like "$err", qr/does not exist/, '... refused';
  like "$err", qr/\Q'$me'\E exists/, '... and the message points to the upper-case user';
  $schema->storage->disconnect;
}

# --- 2. and 3. the round into a schema -----------------------------------

sub sources_in {
  my ($s) = @_;
  return (
    { name => 'Parent', table => "$s.cs84_parent",
      columns => [ id => $id->(), name => { data_type => 'varchar', size => 20, is_nullable => 1 } ],
      primary_key => ['id'] },
    { name => 'Item', table => "$s.cs84_item",
      columns => [
        id        => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
        parent_id => $id->(),
        code      => { data_type => 'varchar', size => 10 },
      ],
      primary_key => ['id'],
      unique      => [ [ cs84_item_code => ['code'] ] ],
      indexes     => [ { name => 'cs84_item_parent_idx', columns => ['parent_id'] } ],
      relationships => [ { type => 'belongs_to', name => 'parent', source => 'Parent', cond => 'parent_id' } ] },
  );
}

# the objects of the round, whichever way they are left
sub cleanup {
  my ($dbh, $s) = @_;
  for my $sql (
    qq{DROP TABLE "$s"."cs84_item" CASCADE CONSTRAINTS PURGE},
    qq{DROP TABLE "$s"."cs84_parent" CASCADE CONSTRAINTS PURGE},
    qq{DROP SEQUENCE "$s"."cs84_item_id_seq"},
  ) { eval { $dbh->do($sql) } }
}

# a model reduced to the tables of the round
sub restrict {
  my ($model, $s) = @_;
  my %keep = map { $_ => 1 } grep { /\A\Q$s\E\.cs84_/ } keys %{ $model->{tables} };
  return { map { my $sec = $_;
    ($sec => { map { $_ => $model->{$sec}{$_} } grep { $keep{$_} } keys %{ $model->{$sec} } }) }
    qw(tables columns indexes foreign_keys primary_keys unique_constraints) };
}

sub without {
  my ($model, $drop) = @_;
  return { map { my $sec = $_;
    ($sec => { map { $_ => $model->{$sec}{$_} } grep { $_ ne $drop } keys %{ $model->{$sec} } }) }
    keys %$model };
}

sub round {
  my ($s, $verify) = @_;

  # the connected user reads $s as a schema of its own; for its own schema the
  # main schema is a name nobody has, so that every table comes as schema.table
  my @intro = (dbh => $admin, $s eq $me
    ? (schema => 'DBIO_NO_SUCH_SCHEMA', schemas => [$s]) : (schemas => [$s]));
  my $model = sub { restrict(DBIO::Oracle::Introspect->new(@intro)->model, $s) };

  cleanup($admin, $s);
  my $schema = schema_for("round$$" . ($s eq $me ? 'me' : 'x'), sources_in($s));
  my $ok = eval {
    DBIO::Oracle::Deploy->new(schema => $schema)->install;
    pass "install into $s";

    my $tables = $verify->selectcol_arrayref(
      q{SELECT table_name FROM user_tables WHERE table_name LIKE 'cs84\_%' ESCAPE '\'});
    is_deeply [ sort @$tables ], [qw(cs84_item cs84_parent)], "... both tables are in $s, as spelled";
    my ($seq) = $verify->selectrow_array(
      q{SELECT sequence_name FROM user_sequences WHERE sequence_name = 'cs84_item_id_seq'});
    is $seq, 'cs84_item_id_seq', '... the sequence is in the schema of the table';
    my ($trg, $trg_table) = $verify->selectrow_array(
      q{SELECT trigger_name, table_name FROM user_triggers WHERE trigger_name = 'cs84_item_id_trg'});
    is "$trg/$trg_table", 'cs84_item_id_trg/cs84_item', '... and the trigger on the table';
    my ($idx) = $verify->selectrow_array(
      q{SELECT index_name FROM user_indexes WHERE index_name = 'cs84_item_parent_idx'});
    is $idx, 'cs84_item_parent_idx', '... and the index';

    # the storage reads and writes the table in the other schema
    $schema->resultset('Parent')->create({ id => 1, name => 'p' });
    my $item = $schema->resultset('Item')->create({ parent_id => 1, code => 'c1' });
    ok defined $item->id, 'create without a key reads the key of the sequence back';
    is $schema->resultset('Item')->search({ code => 'c1' })->count, 1, 'a row of the table is found';
    is eval { $schema->resultset('Item')->search({}, { prefetch => 'parent' })->first->parent->name }, 'p',
      'a join to the parent table in the schema works';

    # introspect
    my $m = $model->();
    is_deeply [ sort keys %{ $m->{tables} } ], [ "$s.cs84_item", "$s.cs84_parent" ],
      "Introspect names the tables $s.table";
    is $m->{tables}{"$s.cs84_item"}{schema}, $s, '... each knows its schema';
    is_deeply [ map { $_->{column_name} } @{ $m->{columns}{"$s.cs84_item"} } ], [qw(id parent_id code)],
      '... and its columns';
    is $m->{columns}{"$s.cs84_item"}[0]{sequence}, "$s.cs84_item_id_seq", '... the sequence of the key';
    is_deeply $m->{primary_keys}{"$s.cs84_item"}, ['id'], '... the primary key';
    is_deeply [ keys %{ $m->{indexes}{"$s.cs84_item"} } ], ['cs84_item_parent_idx'], '... the index';
    my ($fk) = @{ $m->{foreign_keys}{"$s.cs84_item"} };
    is $fk->{to_table}, "$s.cs84_parent", '... the foreign key points to the table of the same schema';

    # the diff of a model against the one just read is empty
    my $same = DBIO::Oracle::Diff->new(source => $m, target => $model->());
    ok !$same->has_changes, 'Diff: the model against a second reading of it is empty'
      or diag $same->as_sql;

    # A to B: write the drop of the item table, apply it, read, write the
    # create, apply it, read -- B again, and a diff of it is empty
    my $deploy = DBIO::Oracle::Deploy->new(schema => $schema);
    my $a = without($m, "$s.cs84_item");
    my $drop = DBIO::Oracle::Diff->new(source => $m, target => $a);
    like $drop->as_sql, qr/DROP TABLE "\Q$s\E"\."cs84_item" CASCADE CONSTRAINTS;/, 'Diff: DROP TABLE is qualified';
    $deploy->apply($drop, allow_destructive => 1);   # the drop of the table is the point
    my $after_drop = $model->();
    ok !DBIO::Oracle::Diff->new(source => $after_drop, target => $a)->has_changes,
      '... applied, the schema is A and the diff against A is empty'
      or diag DBIO::Oracle::Diff->new(source => $after_drop, target => $a)->as_sql;
    my ($seq_left) = $verify->selectrow_array(
      q{SELECT COUNT(*) FROM user_sequences WHERE sequence_name = 'cs84_item_id_seq'});
    is $seq_left, 0, '... the sequence of the dropped table went with it';

    # Deploy->diff builds the desired state with a temp user for each foreign
    # schema: with the item table gone it finds exactly that table to create
    my $mine = sub { grep { $_->table_name =~ /(?:\A|\.)cs84_/ } @{ $_[0]->operations } };
    my $found = $deploy->diff;
    my @ops = $mine->($found);
    my $titem = $s eq $me ? 'cs84_item' : "$s.cs84_item";
    my @sum = map { $_->summary } @ops;
    ok @sum == 3 && $sum[0] eq "+ table: $titem"
        && $sum[1] eq "  +index: cs84_item_parent_idx on $titem"
        && $sum[2] =~ /\A  \+foreign key: \S+ on \Q$titem\E\z/,
      'Deploy->diff (temp users): the dropped table, its index and its key are the operations of the round'
      or diag join "\n", @sum;
    like $found->as_sql, qr/CREATE TABLE "(?:\Q$s\E"\.")?cs84_item" \(/, '... written as a CREATE TABLE of the table';

    my $create = DBIO::Oracle::Diff->new(source => $after_drop, target => $m);
    like $create->as_sql, qr/CREATE TABLE "\Q$s\E"\."cs84_item" \(/, 'Diff: CREATE TABLE is qualified';
    $deploy->apply($create);
    my $again = $model->();
    my $rest = DBIO::Oracle::Diff->new(source => $again, target => $m);
    ok !$rest->has_changes, '... applied, the schema is B again and the diff against B is empty'
      or diag $rest->as_sql;

    # ... and with the table back, Deploy->diff finds nothing of the round
    my @left = $mine->($deploy->diff);
    is scalar(@left), 0, 'Deploy->diff of the installed schema holds no operation of the round'
      or diag join "\n", map { $_->summary } @left;
    my ($tmp) = $admin->selectrow_array(
      q{SELECT COUNT(*) FROM all_users WHERE username LIKE 'DBIO\_TMP\_%' ESCAPE '\'});
    is $tmp, 0, '... and no temp user is left on the server';
    1;
  };
  my $error = $@;
  eval { $schema->storage->disconnect };
  cleanup($admin, $s);
  die $error unless $ok;
}

subtest "round into the connected user's own schema ($me), written qualified" => sub {
  round($me, $admin);
};

# --- 3. a second user ------------------------------------------------------

my @extra = @ENV{qw(DBIO_TEST_ORA_EXTRAUSER_DSN DBIO_TEST_ORA_EXTRAUSER_USER DBIO_TEST_ORA_EXTRAUSER_PASS)};
my @privs = ('CREATE ANY TABLE', 'ALTER ANY TABLE', 'DROP ANY TABLE', 'CREATE ANY INDEX',
  'DROP ANY INDEX', 'CREATE ANY SEQUENCE', 'DROP ANY SEQUENCE', 'CREATE ANY TRIGGER');

SKIP: {
  my @unset = grep { !length($extra[$_] // '') } 0 .. 2;
  skip 'SKIPPED, the round into a second user: DBIO_TEST_ORA_EXTRAUSER_DSN/_USER/_PASS are not '
    . 'set (a user to write into, and the ANY privileges for the connected user: '
    . join(', ', @privs) . ')', 1 if @unset;

  my $have = { map { $_->[0] => 1 } @{ $admin->selectall_arrayref('SELECT privilege FROM session_privs') } };
  my @missing = grep { !$have->{$_} } @privs;
  skip "SKIPPED, the round into a second user: $me lacks " . join(', ', @missing)
    . ' (the server answers ORA-01031 without them)', 1 if @missing;

  my $verify = DBI->connect(@extra, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  my ($s) = $verify->selectrow_array('SELECT USER FROM DUAL');
  cleanup($admin, $s);
  subtest "round into the schema of the second user ($s)" => sub {
    round($s, $verify);
  };

  # --- 4. a foreign key between two schemas ---------------------------------
  subtest "foreign key from $s to $me" => sub {
    my @tables = ([ $s, 'cs84p_child' ], [ $me, 'cs84p_parent' ]);
    my $clean = sub { eval { $admin->do(qq{DROP TABLE "$_->[0]"."$_->[1]" CASCADE CONSTRAINTS PURGE}) } for @tables };
    $clean->();
    my $schema = schema_for("fk$$", (
      { name => 'FkParent', table => "$me.cs84p_parent", columns => [ id => $id->() ], primary_key => ['id'] },
      { name => 'FkChild', table => "$s.cs84p_child",
        columns => [ id => $id->(), parent_id => $id->() ], primary_key => ['id'],
        relationships => [ { type => 'belongs_to', name => 'parent', source => 'FkParent', cond => 'parent_id' } ] },
    ));
    my $ok = eval {
      # without REFERENCES the server's error reaches the caller: the driver writes no GRANT
      my $deploy = DBIO::Oracle::Deploy->new(schema => $schema);
      my $err = eval { $deploy->install; 1 } ? undef : $@;
      ok $err, 'install of a foreign key into the table of another user, without REFERENCES, fails ...';
      like "$err", qr/ORA-01031|ORA-00942/, '... with the error of the server';

      # the owner of the parent gives the right; the key is then made
      $admin->do(qq{GRANT REFERENCES ON "$me"."cs84p_parent" TO "$s"});
      my ($alter) = DBIO::Oracle::DDL->install_ddl($schema) =~ /(ALTER TABLE .*?);/s;
      ok $alter, '... the key is the ALTER TABLE of the install DDL';
      ok eval { $admin->do($alter); 1 }, '... and works once the owner of the parent has granted REFERENCES'
        or diag $@;

      # the temp users of the diff grant each other, so the diff can be built at all
      my @ops = grep { $_->table_name =~ /(?:\A|\.)cs84p_/ } @{ $deploy->diff->operations };
      is scalar(@ops), 0, 'Deploy->diff (temp users, REFERENCES between them) finds nothing to do'
        or diag join "\n", map { $_->summary } @ops;
      1;
    };
    my $error = $@;
    eval { $schema->storage->disconnect };
    $clean->();
    die $error unless $ok;
  };
  $verify->disconnect;
}

$admin->disconnect;
done_testing;
