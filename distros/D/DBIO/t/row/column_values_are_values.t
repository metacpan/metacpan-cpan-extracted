use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::SQLMaker;

# A column value is a value: what goes to the storage for a column is a
# scalar, undef, an object, an arrayref (an array data type, always bound) or
# an explicit literal (\'...' / \[ $sql, @bind ]). A HASH, CODE, GLOB or
# reference to a reference that is no literal throws, naming the column and the
# type and never the value. The search path is not covered here.
#
# Everything runs on the mock storage -- no real DB.

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

sub fresh { $storage->clear_mocks; $storage->reset_captured }
sub writes {
  grep { $_->{op} =~ /^(?:insert|update)$/ } $storage->captured_queries
}

sub mock_artist { $storage->mock_persistent(qr/FROM "artist"/i, [[ 7, 'Seven', 13, undef ]]) }

my $msg = qr/column 'name' got a HASH reference -- a column value is a value; use \\\[ \.\.\. \] for literal SQL or an inflated column type/;

# --- Row::update -----------------------------------------------------------
fresh();
mock_artist();
{
  my $row = $schema->resultset('Artist')->find({ artistid => 7 });
  fresh();
  throws_ok { $row->update({ name => { -ident => 'charfield' } }) } $msg,
    'row update with a hash value throws';
  is scalar(writes()), 0, 'nothing reached the storage';

  throws_ok { $row->name({ -ident => 'charfield' }) } $msg,
    'accessor with a hash value throws';
  throws_ok { $row->set_column(name => { -ident => 'charfield' }) } $msg,
    'set_column with a hash value throws';
  throws_ok { $row->set_columns({ name => { -ident => 'charfield' } }) } $msg,
    'set_columns with a hash value throws';
  throws_ok { $row->set_inflated_columns({ name => { -ident => 'charfield' } }) } $msg,
    'set_inflated_columns with a hash value throws';

  # the value is never part of the message
  throws_ok { $row->update({ name => { -ident => 'SECRET_COL' } }) } qr/\A(?!.*SECRET_COL)/s,
    'the message names no value';

  for my $ref ([ CODE => sub { 1 } ], [ GLOB => \*STDOUT ], [ REF => \\'x' ]) {
    my ($type, $val) = @$ref;
    throws_ok { $row->set_column(name => $val) } qr/column 'name' got a \Q$type\E reference/,
      "a $type reference throws";
  }
}

# --- ResultSet::update -----------------------------------------------------
fresh();
throws_ok {
  $schema->resultset('Artist')->search({ artistid => 7 })->update({ name => { -ident => 'charfield' } })
} $msg, 'resultset update with a hash value throws';
is scalar(writes()), 0, 'nothing reached the storage';

# --- create / new_result + insert -----------------------------------------
fresh();
throws_ok { $schema->resultset('Artist')->create({ name => { -ident => 'charfield' } }) } $msg,
  'create with a hash value throws';
throws_ok { $schema->resultset('Artist')->new_result({ name => { -ident => 'charfield' } }) } $msg,
  'new_result with a hash value throws';
{
  my $row = $schema->resultset('Artist')->new_result({});
  # a value forced past the early checks is stopped before the storage
  $row->{_column_data}{name} = { -ident => 'charfield' };
  throws_ok { $row->insert } $msg, 'insert stops a hash value before the storage';
}
is scalar(writes()), 0, 'nothing reached the storage';

# --- populate, list and void ----------------------------------------------
fresh();
throws_ok {
  $schema->resultset('Artist')->populate([ { name => 'a' }, { name => { -in => [1] } } ])
} $msg, 'populate (list) with a hash value throws';
throws_ok {
  $schema->resultset('Artist')->populate([ { name => 'a' }, { name => { -in => [1] } } ]);
} $msg, 'populate (void) with a hash value throws';
throws_ok {
  $schema->resultset('Artist')->populate([ [qw(name)], [ { -ident => 'charfield' } ] ])
} $msg, 'populate (arrayref form) with a hash value throws';
is scalar(writes()), 0, 'nothing reached the storage';

# --- what stays a value ----------------------------------------------------
fresh();
lives_ok { $schema->resultset('Artist')->create({ name => \"UPPER('x')" }) }
  'a scalar literal is a value';
my ($w) = writes();
like $w->{sql}, qr/UPPER\('x'\)/, 'scalar literal rendered as before';

fresh();
lives_ok { $schema->resultset('Artist')->create({ name => \[ 'UPPER(?)', 'x' ] }) }
  'a literal with binds is a value';
($w) = writes();
like $w->{sql}, qr/UPPER\(\?\)/, 'bind literal rendered as before';

fresh();
lives_ok { $schema->resultset('Artist')->create({ name => undef }) } 'undef is a value';
lives_ok { $schema->resultset('Artist')->create({ name => 'plain' }) } 'a scalar is a value';
lives_ok { $schema->resultset('Artist')->populate([ { name => 'p1' }, { name => \'lower(1)' } ]) }
  'populate with values and literals lives';

# --- arrayrefs are bound, never literal SQL --------------------------------
for my $case (
  [ 'mock storage maker', $storage->sql_maker ],
  [ 'async maker (no storage options)', DBIO::SQLMaker->new(quote_char => '"') ],
) {
  my ($name, $maker) = @$case;
  my ($sql, @bind) = $maker->insert('artist', { name => [ 'x', 'y' ] });
  like $sql, qr/VALUES \(\s*\?\s*\)/, "$name: an arrayref renders as one placeholder";
  unlike $sql, qr/\bx\b|\by\b/, "$name: no array element in the SQL text";
  is scalar(@bind), 1, "$name: one bind";
}

# --- inflated columns keep taking their content ----------------------------
{
  my $s = DBIO::Test->init_schema(no_deploy => 1);
  my $rsrc = $s->source('Artist');
  $rsrc->add_columns(charfield => {
    %{ $rsrc->column_info('charfield') },
    _inflate_info => {
      inflate => sub { $_[0] },
      deflate => sub { ref $_[0] eq 'HASH' ? join(',', %{ $_[0] }) : $_[0] },
    },
  });
  my $row;
  lives_ok { $row = $s->resultset('Artist')->new_result({ name => 'n', charfield => { a => 1 } }) }
    'new with a hash for an inflated column lives';
  lives_ok { $row->insert } 'the deflated value is stored';
  my ($ins) = grep { $_->{op} eq 'insert' } $s->storage->captured_queries;
  ok $ins, 'insert captured';

  lives_ok { $row->set_inflated_column(charfield => { b => 2 }) }
    'set_inflated_column with a hash for an inflated column lives';
}

# --- multi-create: a hash under a relationship name is a relationship ------
fresh();
lives_ok {
  $schema->resultset('CD')->create({
    title  => 'mc',
    year   => 2000,
    artist => { name => 'multi' },
  });
} 'multi-create with a relationship hash lives';

done_testing;
