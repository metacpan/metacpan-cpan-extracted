use strict;
use warnings;
use Test::More;

# Offline foreign key diff -- SQL text only. The syntax is the documented
# Informix one (constraint name after the definition) and is live unmeasured
# (karr k14).

use_ok 'DBIO::Informix::Diff::ForeignKey';
use_ok 'DBIO::Informix::Diff::Table';
use_ok 'DBIO::Informix::Diff';

my $tables = { book => {}, author => {} };
my $fk = sub {
  +{ constraint_name => 'book_author_fk', from_columns => ['author_id'],
     to_table => 'author', to_columns => ['id'], @_ };
};

# add
{
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [] }, { book => [ $fk->() ] }, $tables, $tables);
  is(scalar @ops, 1, 'one op');
  is($ops[0]->action, 'add', 'add');
  is($ops[0]->as_sql,
    'ALTER TABLE book ADD CONSTRAINT FOREIGN KEY (author_id) REFERENCES author(id) CONSTRAINT book_author_fk;',
    'ADD CONSTRAINT with the name after the definition');
  is($ops[0]->summary, '+ fk: book_author_fk on book', 'summary');
}

# drop
{
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $fk->() ] }, { book => [] }, $tables, $tables);
  is(scalar @ops, 1, 'one op');
  is($ops[0]->as_sql, 'ALTER TABLE book DROP CONSTRAINT book_author_fk;', 'DROP CONSTRAINT');
}

# unchanged, incl. the raw introspector keys (fk_name / del_rule)
{
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $fk->() ] },
    { book => [ { fk_name => 'book_author_fk', from_columns => ['author_id'],
                  to_table => 'author', to_columns => ['id'], upd_rule => 'R' } ] },
    $tables, $tables);
  is(scalar @ops, 0, 'same key, raw keys: no op');
}

# changed: drop + add, cascade written
{
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $fk->() ] }, { book => [ $fk->(on_delete => 'CASCADE') ] },
    $tables, $tables);
  is(join(',', map { $_->action } @ops), 'drop,add', 'change is drop then add');
  like($ops[1]->as_sql, qr/\) ON DELETE CASCADE CONSTRAINT book_author_fk;$/, 'cascade before the name');
}
{
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $fk->() ] }, { book => [ $fk->(del_rule => 'C') ] }, $tables, $tables);
  is(scalar @ops, 2, 'raw del_rule C counts as cascade');
}

# unnamed keys match each other; an add without a name writes none
{
  my $u = sub { +{ from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] } };
  is(scalar(() = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $u->() ] }, { book => [ $u->() ] }, $tables, $tables)), 0, 'unnamed, same: no op');
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [] }, { book => [ $u->() ] }, $tables, $tables);
  is($ops[0]->as_sql,
    'ALTER TABLE book ADD CONSTRAINT FOREIGN KEY (author_id) REFERENCES author(id);',
    'no name is made up');
}

# karr k22 -- keys are compared by content, not by name
{
  my $named = sub { my $n = shift; $fk->(constraint_name => $n) };
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $named->('r136_41') ] }, { book => [ $named->('r212_7') ] }, $tables, $tables);
  is(scalar @ops, 0, 'same key under the server-assigned names of two databases: no op');

  @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $named->('book_author_fk') ] }, { book => [ $named->('r212_7') ] }, $tables, $tables);
  is(scalar @ops, 0, 'same key under a chosen and a server-assigned name: no op');

  @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ { fk_name => 'r136_41', from_columns => ['author_id'], to_table => 'author',
                  to_columns => ['id'], upd_rule => 'R', del_rule => 'R' } ] },
    { book => [ $fk->(constraint_name => 'r5_5', on_delete => 'RESTRICT') ] }, $tables, $tables);
  is(scalar @ops, 0, 'raw introspector key and model key with the default action: no op');

  # drop uses the name the server gave, add writes none for a server-assigned one
  @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ $named->('r136_41') ] }, { book => [ $fk->(from_columns => ['other_id'], constraint_name => 'r9_9') ] },
    $tables, $tables);
  is(join(',', map { $_->action } @ops), 'drop,add', 'other columns: drop then add');
  is($ops[0]->as_sql, 'ALTER TABLE book DROP CONSTRAINT r136_41;', 'drop by the server name');
  is($ops[1]->as_sql,
    'ALTER TABLE book ADD CONSTRAINT FOREIGN KEY (other_id) REFERENCES author(id);',
    'add without the server-assigned name');

  # target table, target columns and the action are part of the content
  for my $change ([ to_table => 'writer' ], [ to_columns => ['code'] ], [ on_delete => 'CASCADE' ]) {
    @ops = DBIO::Informix::Diff::ForeignKey->diff(
      { book => [ $fk->() ] }, { book => [ $fk->(@$change) ] }, { %$tables, writer => {} }, { %$tables, writer => {} });
    is(join(',', map { $_->action } @ops), 'drop,add', "$change->[0] is content");
  }

  # a name the model chooses is written
  @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [] }, { book => [ $named->('book_author_fk') ] }, $tables, $tables);
  like($ops[0]->as_sql, qr/\) CONSTRAINT book_author_fk;$/, 'a chosen name is written');

  # a key to drop without any name cannot be dropped
  @ops = DBIO::Informix::Diff::ForeignKey->diff(
    { book => [ { from_columns => ['author_id'], to_table => 'author', to_columns => ['id'] } ] },
    { book => [] }, $tables, $tables);
  like(eval { $ops[0]->as_sql; 1 } ? '' : $@, qr/table book .*no name/, 'drop without a name dies, names the table');
}

# a table only in the target: its FK is an ALTER after the CREATE TABLEs
{
  my @ops = DBIO::Informix::Diff::ForeignKey->diff(
    {}, { book => [ $fk->() ] }, {}, $tables);
  is(scalar @ops, 1, 'new table: FK is an op of its own');
  is($ops[0]->as_sql,
    'ALTER TABLE book ADD CONSTRAINT FOREIGN KEY (author_id) REFERENCES author(id) CONSTRAINT book_author_fk;',
    'ADD CONSTRAINT for a new table');
}

# create table: no inline FK
{
  my @ops = DBIO::Informix::Diff::Table->diff(
    {}, { book => {} },
    { book => [ { column_name => 'author_id', data_type => 'integer' } ] },
    { book => [ $fk->(on_delete => 'CASCADE') ] });
  unlike($ops[0]->as_sql, qr/FOREIGN KEY|REFERENCES/, 'no inline FK in CREATE TABLE');
}

# FK of a new table onto a table created later: ALTER after both CREATEs
{
  my $t = { a => {}, b => {} };
  my $model = sub { +{ tables => $_[0], columns => { a => [ { column_name => 'b_id', data_type => 'integer' } ],
      b => [ { column_name => 'id', data_type => 'integer', is_pk => 1 } ] },
    indexes => {}, foreign_keys => { a => [ { constraint_name => 'a_b_fk',
      from_columns => ['b_id'], to_table => 'b', to_columns => ['id'] } ] } } };
  my $sql = DBIO::Informix::Diff->new(source => $model->({}), target => $model->($t))->as_sql;
  unlike($sql, qr/CREATE TABLE[^;]*FOREIGN KEY/s, 'no FOREIGN KEY inside a CREATE TABLE');
  my $alter  = index $sql, 'ALTER TABLE a ADD CONSTRAINT FOREIGN KEY';
  my $create_b = index $sql, 'CREATE TABLE b';
  my $create_a = index $sql, 'CREATE TABLE a';
  ok($alter >= 0, 'ALTER emitted');
  ok($alter > $create_a && $alter > $create_b, 'ALTER stands after both CREATE TABLE');
}

# orchestrator
{
  my $model = sub { +{ tables => $tables, columns => { book => [], author => [] },
                       indexes => {}, foreign_keys => { book => $_[0] } } };
  my $d = DBIO::Informix::Diff->new(source => $model->([]), target => $model->([ $fk->() ]));
  like($d->as_sql, qr/ADD CONSTRAINT FOREIGN KEY/, 'Diff emits the FK op');
  ok(!DBIO::Informix::Diff->new(source => $model->([ $fk->() ]),
      target => $model->([ $fk->() ]))->has_changes, 'unchanged: no changes');
}

# Informix knows ON DELETE CASCADE only: every other action is refused loudly
# (die with table, constraint and reason), never dropped silently. The
# defaults (none / NO ACTION / RESTRICT / raw R, the documented sysreferences
# default) stay silent.
{
  for my $case (
    [ on_delete => 'SET NULL' ], [ on_delete => 'SET DEFAULT' ],
    [ on_update => 'CASCADE' ], [ on_update => 'SET NULL' ],
    [ del_rule => 'X' ], [ upd_rule => 'C' ],
  ) {
    my ($k, $v) = @$case;
    my $err = eval {
      DBIO::Informix::Diff::ForeignKey->diff(
        { book => [] }, { book => [ $fk->($k => $v) ] }, $tables, $tables);
      1 } ? '' : $@;
    like($err, qr/book_author_fk on table book:.*\Q$v\E/s, "$k=$v refused, names table, constraint, value");
  }

  # new table: same refusal
  ok(!eval { DBIO::Informix::Diff::ForeignKey->diff(
      {}, { book => [ $fk->(on_delete => 'SET NULL') ] }, {}, $tables); 1 },
    'refused for a new table too');

  # rule differs only in an unsupported action: not silently equal
  ok(!eval { DBIO::Informix::Diff::ForeignKey->diff(
      { book => [ $fk->() ] }, { book => [ $fk->(on_delete => 'SET NULL') ] },
      $tables, $tables); 1 }, 'a change into an unsupported action is refused');

  # defaults stay silent
  for my $case ([ on_delete => 'NO ACTION' ], [ on_delete => 'RESTRICT' ], [ on_delete => 'R' ],
                [ on_update => 'NO ACTION' ], [ on_update => 'R' ], [ del_rule => 'R' ],
                [ upd_rule => 'R' ], [ on_delete => undef ], [ on_delete => 'C' ]) {
    my ($k, $v) = @$case;
    my @ops = eval { DBIO::Informix::Diff::ForeignKey->diff(
      { book => [] }, { book => [ $fk->($k => $v) ] }, $tables, $tables) };
    is($@, '', "$k=" . ($v // 'undef') . ' is accepted');
  }
}

done_testing;
