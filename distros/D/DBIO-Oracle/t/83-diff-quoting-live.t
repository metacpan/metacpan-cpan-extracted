use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::Oracle::Deploy;
use DBIO::Oracle::Introspect;
use DBIO::Oracle::Diff;

# LIVE (karr k61). What the install makes in lower case, the diff finds again.
#
# Diff::Column wrote the names of an ALTER TABLE bare, which Oracle folds to
# upper case; install quotes them as the result class spells them. A table
# made by install in lower case therefore failed every ALTER of a diff with
# ORA-00942. And DROP TABLE left the sequence the install made for the table
# standing. Held here against a server:
#
#   1. install of a lower-case table with an auto-increment column; a second
#      version adds a column and widens another; Deploy->upgrade applies the
#      ALTERs, and the next diff -- either way -- is empty.
#   2. the model spells the sequence the way the server has it (the install
#      quotes it in lower case).
#   3. upgrading to a schema without the table drops the table and its
#      sequence: user_sequences holds nothing of the test afterwards.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_ORA_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_ORA_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_oracle')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_oracle');

alarm 300;

local $SIG{__WARN__} = sub {
  return if $_[0] =~ /\Anon-transactional DDL on DBIO::Oracle::Deploy\b/;
  warn $_[0];
};

my $admin = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

my $OWN = q{LIKE 'K61\_LIVE%' ESCAPE '\'};

sub rows { $admin->selectall_arrayref(@_) }

# Deploy->upgrade works on the whole schema of the user: beside somebody
# else's tables it would drop them.
{
  my @foreign = map { $_->[0] } @{ rows(qq{
    SELECT table_name FROM user_tables
    WHERE table_name NOT LIKE 'BIN\$%' AND UPPER(table_name) NOT $OWN
    UNION ALL SELECT view_name FROM user_views
  }) };
  plan skip_all => "The schema of $user must hold no tables or views but this "
    . "test's own (k61_live*); found: @foreign" if @foreign;
}

sub wipe {
  $admin->do(qq{DROP TABLE "$_->[0]" CASCADE CONSTRAINTS PURGE})
    for @{ rows(qq{SELECT table_name FROM user_tables WHERE UPPER(table_name) $OWN}) };
  $admin->do(qq{DROP SEQUENCE "$_->[0]"})
    for @{ rows(qq{SELECT sequence_name FROM user_sequences WHERE UPPER(sequence_name) $OWN}) };
}

END { wipe() if $admin }

{
  package T::K61::V1::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('k61_live_thing');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 20, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K61::V2::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('k61_live_thing');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 50, is_nullable => 1 },
    note => { data_type => 'varchar', size => 10, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K61::V1;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Thing => 'T::K61::V1::Thing');

  package T::K61::V2;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
  __PACKAGE__->register_class(Thing => 'T::K61::V2::Thing');

  package T::K61::V0;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Oracle');
}

sub deploy_of { DBIO::Oracle::Deploy->new(schema => $_[0]->connect($dsn, $user, $pass)) }

sub sequences { [ map { $_->[0] } @{ rows(qq{SELECT sequence_name FROM user_sequences WHERE UPPER(sequence_name) $OWN ORDER BY 1}) } ] }
sub columns   { [ map { join ' ', @$_ } @{ rows(qq{SELECT column_name, data_type, char_length FROM user_tab_columns WHERE UPPER(table_name) $OWN ORDER BY column_id}) } ] }

wipe();

# ------------------------------------------------------------------ 1
deploy_of('T::K61::V1')->install;

is_deeply columns(), [ 'id NUMBER 0', 'name VARCHAR2 20' ],
  '(install made the table in lower case)';
is_deeply sequences(), ['k61_live_thing_id_seq'], '(... and its sequence)';

# ------------------------------------------------------------------ 2
{
  my $model = DBIO::Oracle::Introspect->new(dbh => $admin)->model;
  my $col   = $model->{columns}{k61_live_thing}[0];
  my ($schema) = $admin->selectrow_array('SELECT USER FROM DUAL');

  is $col->{sequence}, "$schema.k61_live_thing_id_seq",
    'the model spells the sequence as the server has it: the schema in upper '
  . 'case, the name in the lower case the install quoted it in';
}

# ------------------------------------------------------------------ 1
{
  my $deploy = deploy_of('T::K61::V2');
  my $diff   = eval { $deploy->diff };
  is "$@", '', 'diff of V1 against V2 runs';
  ok $diff && $diff->has_changes, '... and finds the new column and the wider one';
  like $diff->as_sql, qr/ALTER TABLE "k61_live_thing" ADD \("note" VARCHAR2\(10\)\)/,
    '... written with the names quoted';

  my $upgraded = eval { $deploy->upgrade };
  is "$@", '', 'upgrade applies the ALTERs to the lower-case table (no ORA-00942)';
  ok $upgraded, '... and had something to do';

  is_deeply columns(), [ 'id NUMBER 0', 'name VARCHAR2 50', 'note VARCHAR2 10' ],
    '... the table is V2';

  my $again = deploy_of('T::K61::V2')->diff;
  ok !$again->has_changes, 'the second diff after the apply is empty'
    or diag $again->as_sql;
}

# ------------------------------------------------------------------ 3
{
  my $deploy = deploy_of('T::K61::V0');
  my $diff   = $deploy->diff;
  like $diff->as_sql,
    qr/DROP TABLE "k61_live_thing" CASCADE CONSTRAINTS;\s*DROP SEQUENCE "k61_live_thing_id_seq";/,
    'the diff to a schema without the table drops table and sequence';

  my $upgraded = eval { $deploy->upgrade(allow_destructive => 1) };   # the drop is the point
  is "$@", '', 'upgrade runs';

  is_deeply columns(), [], 'the table is gone';
  is_deeply sequences(), [], 'DROP TABLE left no sequence in user_sequences';
  ok !deploy_of('T::K61::V0')->diff->has_changes, 'and the next diff is empty';
}

done_testing;
