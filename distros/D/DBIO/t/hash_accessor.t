use strict;
use warnings;
use Test::More;
use Test::Exception;

# Build a minimal fake row class that has a hash column accessor
{
  package TestRow;
  use parent 'DBIO::HashAccessor';

  sub new {
    my ($class, %args) = @_;
    bless { _data => $args{data} || {} }, $class;
  }

  sub data {
    my ($self, $val) = @_;
    $self->{_data} = $val if defined $val;
    return $self->{_data};
  }
}

TestRow->add_hash_accessor( da => 'data' );

my $row = TestRow->new;

# --- basic get/set ---

is $row->da('foo'), undef, 'get on empty hash returns undef';

is $row->da('foo', 'bar'), 'bar', 'set returns the value';
is $row->da('foo'), 'bar', 'get returns previously set value';

$row->da('num', 42);
is $row->da('num'), 42, 'set/get numeric value';

# --- exists ---

ok $row->da_exists('foo'), 'exists returns true for set key';
ok !$row->da_exists('missing'), 'exists returns false for missing key';

# --- delete ---

is $row->da_delete('foo'), 'bar', 'delete returns old value';
ok !$row->da_exists('foo'), 'key gone after delete';
is $row->da_delete('nonexistent'), undef, 'delete of missing key returns undef';

# --- nested hash ---

is $row->da_hash('opts', 'color', 'red'), 'red', 'hash set returns value';
is $row->da_hash('opts', 'color'), 'red', 'hash get returns set value';
is $row->da_hash('opts', 'missing'), undef, 'hash get missing subkey returns undef';
is $row->da_hash('nope', 'key'), undef, 'hash get on missing top-level returns undef';

# --- nested hash delete ---

is $row->da_hash_delete('opts', 'color'), 'red', 'hash_delete returns old value';
is $row->da_hash('opts', 'color'), undef, 'hash subkey gone after hash_delete';

# --- array push ---

$row->da_push('tags', 'a', 'b', 'c');
is_deeply $row->data->{tags}, ['a', 'b', 'c'], 'push creates array with elements';

$row->da_push('tags', 'd');
is_deeply $row->data->{tags}, ['a', 'b', 'c', 'd'], 'push appends to existing array';

# --- array shift ---

is $row->da_shift('tags'), 'a', 'shift returns first element';
is_deeply $row->data->{tags}, ['b', 'c', 'd'], 'array shrunk after shift';

# --- array in ---

ok $row->da_in('tags', 'b'), 'in returns true for present value';
ok !$row->da_in('tags', 'a'), 'in returns false for removed value';
ok !$row->da_in('tags', 'zzz'), 'in returns false for absent value';

# --- array in_delete ---

$row->da_in_delete('tags', 'c');
is_deeply $row->data->{tags}, ['b', 'd'], 'in_delete removes the value from array';

# --- shift on empty ---

my $empty_row = TestRow->new;
is $empty_row->da_shift('nope'), undef, 'shift on nonexistent key returns undef';

# --- push on fresh key ---

$empty_row->da_push('list', 'x');
is_deeply $empty_row->data->{list}, ['x'], 'push on new key creates array';

# --- error cases ---

dies_ok { TestRow->add_hash_accessor('x') } 'dies without hash name';
dies_ok { TestRow->add_hash_accessor('same', 'same') } 'dies when accessor equals hash';
dies_ok { $row->da() } 'dies with no args';
dies_ok { $row->da('a', 'b', 'c') } 'dies with too many args';

# --- accessor/hash name collision with second registration ---

{
  package TestRow2;
  use parent 'DBIO::HashAccessor';

  sub new { bless { _meta => {} }, shift }
  sub meta_col {
    my ($self, $val) = @_;
    $self->{_meta} = $val if defined $val;
    return $self->{_meta};
  }
}

TestRow2->add_hash_accessor( m => 'meta_col' );
my $r2 = TestRow2->new;
$r2->m('key', 'val');
is $r2->m('key'), 'val', 'second class with different accessor works';

done_testing;
