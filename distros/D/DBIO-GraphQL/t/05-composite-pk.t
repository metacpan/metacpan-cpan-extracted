use strict;
use warnings;

use Test::More;
use lib 't/lib', 'lib';

use DBIO::GraphQL;
use My::Test qw(deploy_schema);

{
  package CPK::Result::Book;
  use DBIO;
  __PACKAGE__->table('books');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    title => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->has_many(
    book_tags => 'CPK::Result::BookTag',
    { 'foreign.book_id' => 'self.id' }
  );
}
{
  package CPK::Result::Tag;
  use DBIO;
  __PACKAGE__->table('tags');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    name => { data_type => 'varchar', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package CPK::Result::BookTag;
  use DBIO;
  __PACKAGE__->table('book_tags');
  __PACKAGE__->add_columns(
    book_id => { data_type => 'integer', is_nullable => 0 },
    tag_id  => { data_type => 'integer', is_nullable => 0 },
    note    => { data_type => 'varchar', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('book_id', 'tag_id');
  __PACKAGE__->add_unique_constraint(unique_note => ['note']);
  __PACKAGE__->belongs_to(
    book => 'CPK::Result::Book',
    { 'foreign.id' => 'self.book_id' }
  );
  __PACKAGE__->belongs_to(
    tag => 'CPK::Result::Tag',
    { 'foreign.id' => 'self.tag_id' }
  );
}
{
  package CPK::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class( Book    => 'CPK::Result::Book'    );
  __PACKAGE__->register_class( Tag     => 'CPK::Result::Tag'     );
  __PACKAGE__->register_class( BookTag => 'CPK::Result::BookTag' );
}
{
  # Three-column primary key: n = 2 cannot tell a general row-wise seek
  # from a two-column special case.
  package CPK3::Result::Slot;
  use DBIO;
  __PACKAGE__->table('slots');
  __PACKAGE__->add_columns(
    a => { data_type => 'integer', is_nullable => 0 },
    b => { data_type => 'integer', is_nullable => 0 },
    c => { data_type => 'integer', is_nullable => 0 },
  );
  __PACKAGE__->set_primary_key('a', 'b', 'c');
}
{
  package CPK3::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('SQLite');
  __PACKAGE__->register_class( Slot => 'CPK3::Result::Slot' );
}

my $db = CPK::Schema->connect('dbi:SQLite:dbname=:memory:');
deploy_schema($db);

$db->resultset('Book')->create({ id => 1, title => 'Test Book' });
$db->resultset('Tag')->create({ id => 10, name => 'fiction' });
$db->resultset('Tag')->create({ id => 11, name => 'classic' });
$db->resultset('BookTag')->create({ book_id => 1, tag_id => 10, note => 'primary tag' });

my $result = DBIO::GraphQL->to_graphql($db, mutations => 1);
my ($exec, $ctx) = @{$result}{qw(execute context)};

sub gql {
  my ($query, $vars) = @_;
  return $exec->($query, undef, $ctx, $vars // {});
}

# Schema shape
my $qf      = $result->{schema}->query->fields;
my $bt_args = $qf->{bookTag}{args};
ok(exists $qf->{bookTag},      'singular bookTag query exists');
ok(exists $bt_args->{book_id}, 'bookTag query has book_id arg');
ok(exists $bt_args->{tag_id},  'bookTag query has tag_id arg' );

# Singular composite - PK query
{
  my $res = gql('{ bookTag(book_id: 1, tag_id: 10) { book_id tag_id note } }');
  ok(!$res->{errors}, 'composite PK query: no errors')
    or diag explain $res->{errors};
  is($res->{data}{bookTag}{book_id}, 1,             'book_id correct');
  is($res->{data}{bookTag}{tag_id},  10,            'tag_id correct' );
  is($res->{data}{bookTag}{note},    'primary tag', 'note correct'   );
}

# createBookTag
{
  my $res = gql('mutation {
    createBookTag(book_id: 1, tag_id: 11, note: "secondary") {
      book_id tag_id note
    }
  }');

  ok(!$res->{errors}, 'createBookTag: no errors')
    or diag explain $res->{errors};
  is($res->{data}{createBookTag}{note}, 'secondary', 'note on new BookTag');
  is($db->resultset('BookTag')->count, 2, 'BookTag count is now 2');
}

# updateBookTag
{
  my $res = gql('mutation {
    updateBookTag(book_id: 1, tag_id: 10, note: "updated note") { note }
  }');

  ok(!$res->{errors}, 'updateBookTag: no errors')
    or diag explain $res->{errors};
  is($res->{data}{updateBookTag}{note}, 'updated note', 'note updated');
}

# deleteBookTag
{
  my $res = gql('mutation { deleteBookTag(book_id: 1, tag_id: 11) }');

  ok(!$res->{errors}, 'deleteBookTag: no errors');
  is($res->{data}{deleteBookTag}, 1, 'deleteBookTag returns true');
  is($db->resultset('BookTag')->count, 1, 'BookTag count back to 1');
}

# deleteBookTag — one of two PK columns beside a unique constraint is
# ambiguous (karr k10): it is rejected, not ignored, and deletes nothing.
{
  my $res = gql('mutation { deleteBookTag(book_id: 1, note: "updated note") }');

  ok($res->{errors}, 'deleteBookTag by partial PK + unique is rejected');
  is($db->resultset('BookTag')->count, 1, 'the BookTag row is still there');
}

# The unique constraint alone still finds the row.
{
  my $res = gql('mutation { deleteBookTag(note: "updated note") }');

  ok(!$res->{errors}, 'deleteBookTag by unique constraint: no errors')
    or diag explain $res->{errors};
  is($res->{data}{deleteBookTag}, 1, 'the unique constraint finds the row');
  is($db->resultset('BookTag')->count, 0, 'the BookTag row is gone');
}

# Cursor pagination over a composite primary key (karr k6).
#
# WHY: a client that follows nextCursor until hasNextPage is false must have
# seen every row exactly once, in primary-key order - that is the whole
# contract of a cursor. The seek behind `after` therefore has to compare the
# key row-wise (a > x, or a = x and b > y, ...). Comparing each column on its
# own drops every row whose later key columns "jump back" when an earlier one
# advances, while total still counts them.

# walk_by_cursor($gql_exec, $ctx, $field, $first, \@cols, $extra_args)
#
# Follows nextCursor from the first page until hasNextPage is false. The
# page count is capped so a cursor that does not advance fails the test
# instead of hanging it.
sub walk_by_cursor {
  my ($gql_exec, $gql_ctx, $field, $first, $cols, $extra) = @_;
  $extra //= '';

  my %walk = (rows => [], pages => 0, finished => 0);
  my $after;
  for (1 .. 20) {
    my $res = $gql_exec->(
      "query(\$c: String) {
        $field(cursor: { after: \$c, first: $first }$extra) {
          total hasNextPage nextCursor nodes { @$cols }
        }
      }",
      undef, $gql_ctx, { c => $after });
    if ($res->{errors}) {
      $walk{errors} = $res->{errors};
      last;
    }

    my $conn = $res->{data}{$field};
    $walk{pages}++;
    $walk{total} //= $conn->{total};
    $walk{max_page} = @{ $conn->{nodes} }
      if @{ $conn->{nodes} } > ($walk{max_page} // 0);
    push @{ $walk{rows} },
      map { my $n = $_; join '/', map { $n->{$_} } @$cols } @{ $conn->{nodes} };

    unless ($conn->{hasNextPage}) {
      $walk{finished}    = 1;
      $walk{last_cursor} = $conn->{nextCursor};
      last;
    }
    $after = $conn->{nextCursor};
  }
  return \%walk;
}

# check_walk($walk, \@expected, $first, $label)
sub check_walk {
  my ($walk, $expected, $first, $label) = @_;

  ok(!$walk->{errors}, "$label: no errors")
    or diag explain $walk->{errors};
  ok($walk->{finished}, "$label: the walk ends with hasNextPage false")
    or diag "still paging after $walk->{pages} pages";
  ok(!defined $walk->{last_cursor}, "$label: no nextCursor on the last page");
  is_deeply($walk->{rows}, $expected,
    "$label: every row once, in primary-key order");
  is(scalar @{ $walk->{rows} }, $walk->{total},
    "$label: rows delivered equal total");
  cmp_ok($walk->{max_page} // 0, '<=', $first,
    "$label: no page is larger than first");
}

# Two-column key. Inserted out of key order so the order asserted below
# comes from the query, not from the insert sequence.
my @book_tag_keys = qw( 1/1 1/2 1/3 2/1 2/2 3/1 );
my ($bt_exec, $bt_ctx);
{
  my $db2 = CPK::Schema->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db2);
  $db2->resultset('Book')->create({ id => $_, title => "Book $_" }) for 1 .. 3;
  $db2->resultset('Tag')->create({ id => $_, name => "tag $_" })    for 1 .. 3;
  for my $key (qw( 2/2 1/3 3/1 1/1 2/1 1/2 )) {
    my ($book_id, $tag_id) = split m{/}, $key;
    $db2->resultset('BookTag')->create({ book_id => $book_id, tag_id => $tag_id });
  }
  my $r2 = DBIO::GraphQL->to_graphql($db2);
  ($bt_exec, $bt_ctx) = @{$r2}{qw(execute context)};
}

# first: 2 is the case from the ticket; first: 1 makes every row a cursor
# boundary once.
for my $first (2, 1, 4) {
  my $walk = walk_by_cursor(
    $bt_exec, $bt_ctx, 'allBookTags', $first, [qw( book_id tag_id )],
  );
  check_walk($walk, \@book_tag_keys, $first, "cursor walk book_tags first=$first");
}

# Three-column key: b and c both jump back when a column to their left
# advances.
my @slot_keys = qw( 1/1/2 1/1/3 1/2/1 1/2/2 2/1/1 2/1/3 2/2/1 3/1/1 );
{
  my $db3 = CPK3::Schema->connect('dbi:SQLite:dbname=:memory:');
  deploy_schema($db3);
  for my $key (qw( 2/1/3 1/2/1 3/1/1 1/1/3 2/2/1 1/1/2 2/1/1 1/2/2 )) {
    my %slot;
    @slot{qw( a b c )} = split m{/}, $key;
    $db3->resultset('Slot')->create(\%slot);
  }
  my $r3 = DBIO::GraphQL->to_graphql($db3);

  for my $first (3, 1, 2) {
    my $walk = walk_by_cursor(
      $r3->{execute}, $r3->{context}, 'allSlots', $first, [qw( a b c )],
    );
    check_walk($walk, \@slot_keys, $first, "cursor walk slots first=$first");
  }
}

# orderBy next to cursor: the cursor names a position in ascending
# primary-key order and in no other. An orderBy that is that order is
# harmless and still walks the whole key; anything else is refused, because
# serving it would hand out a nextCursor that does not lead to the next page.
{
  my $walk = walk_by_cursor(
    $bt_exec, $bt_ctx, 'allBookTags', 2, [qw( book_id tag_id )],
    ', orderBy: { field: "book_id", direction: ASC }',
  );
  check_walk($walk, \@book_tag_keys, 2,
    'cursor walk book_tags ordered by leading key column ASC');
}

for my $order (
  [ 'tag_id',  'ASC',  'a later primary-key column' ],
  [ 'book_id', 'DESC', 'the leading primary-key column descending' ],
  [ 'note',    'ASC',  'a column outside the primary key' ],
) {
  my ($field, $dir, $what) = @$order;
  my $res = $bt_exec->(
    "{ allBookTags(cursor: { first: 2 }, orderBy: { field: \"$field\", direction: $dir }) {
      total nextCursor nodes { book_id tag_id }
    } }",
    undef, $bt_ctx, {});

  like(($res->{errors} // [])->[0]{message} // '',
    qr/^DBIO::GraphQL: cursor pagination .* ascending primary-key order/,
    "cursor + orderBy on $what is refused with the cursor-order message");
  ok(!defined $res->{data}{allBookTags},
    "cursor + orderBy on $what delivers no rows");
}

# A cursor that does not carry one value per primary-key column cannot name
# a position in this source. It is refused rather than compared against NULL
# for the missing column, which would silently answer "no rows".
for my $case (
  [ 'MQ==',     'too few values'  ],   # base64("1")
  [ 'MToxOjE=', 'too many values' ],   # base64("1:1:1")
) {
  my ($after, $what) = @$case;
  my $res = $bt_exec->(
    'query($c: String) { allBookTags(cursor: { after: $c, first: 2 }) {
      total nodes { book_id tag_id }
    } }',
    undef, $bt_ctx, { c => $after });

  like(($res->{errors} // [])->[0]{message} // '',
    qr/^DBIO::GraphQL: cursor does not match the primary key of source 'BookTag'/,
    "cursor with $what for the primary key is refused");
  ok(!defined $res->{data}{allBookTags},
    "cursor with $what delivers no rows");
}

done_testing;
