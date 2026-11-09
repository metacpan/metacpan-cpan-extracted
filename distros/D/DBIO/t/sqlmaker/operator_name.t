use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;

# The operator of a condition, { column => { OPERATOR => value } }, is a
# symbol of the symbol characters or a word of the list operator_words.

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $sm     = $schema->storage->sql_maker;

my @bad = (
  '= 1 OR 1=1 OR name =',
  'is null or true or name like',
  '; drop',
  '--',
  '= --',
  '/*',
  '=/*',
  'like; drop',
  'foo',
  '- like',
  '',
  'like OR 1=1 OR name like',
);

for my $op (@bad) {
  throws_ok { $sm->where({ name => { $op => 'x' } }) }
    qr/is not an operator of a condition/, "refused: '$op'";
}

my @symbols = (
  '=', '!=', '<>', '<', '<=', '>', '>=',
  '@>', '<@', '?|', '?&', '?', '@?', '@@', '&&', '<->',
  '->', '->>', '#>', '#>>',
);
for my $op (@symbols) {
  lives_ok { $sm->_assert_operator_name($op) } "symbol '$op'";
}

my @words = (
  'like', '-like', 'LIKE', 'not like', '-not_like', 'NOT_LIKE',
  'ilike', '-not_ilike', 'in', '-in', 'not in', '-not_in',
  'between', '-between', 'not between', '-not_between',
  'is', '-is', 'is not', '-is_not',
  'similar to', '-similar_to', 'not similar to', '-not_similar_to',
  'regexp', 'not regexp', 'rlike', '-not_rlike',
  '-ident', '-value', '-nest', '-bind', '-and', '-or',
);
for my $op (@words) {
  lives_ok { $sm->_assert_operator_name($op) } "word '$op'";
}

# through the generator
lives_ok { $sm->where({ name => { -like => 'a%' } }) } 'condition with -like';
lives_ok { $sm->where({ id => { -in => [1, 2] } }) } 'condition with -in';
lives_ok { $sm->where({ id => { '>=' => 2 } }) } 'condition with >=';

# -op => [ OP, ... ] in a raw condition: the same rule, at the raw name
for my $op ('= 1 OR 1=1 OR name =', 'foo', '--', 'like; drop') {
  throws_ok { $sm->where({ -op => [ $op, { -ident => 'a' }, 1 ] }) }
    qr/is not an operator of a condition/, "-op refused: '$op'";
}
lives_ok { $sm->where({ -op => [ '=', { -ident => 'a' }, 1 ] }) } '-op with =';
lives_ok { $sm->where({ -op => [ 'like', { -ident => 'a' }, 'x%' ] }) } '-op with like';
lives_ok { $sm->where({ -op => [ '>=', { -ident => 'a' }, 1 ] }) } '-op with >=';

# a numeric suffix is cut off as SQL::Abstract does: the name without it is checked
lives_ok { $sm->_assert_operator_name('-like_1') } 'word with suffix: -like_1';
lives_ok { $sm->_assert_operator_name('-not_like_2') } 'word with suffix: -not_like_2';
throws_ok { $sm->_assert_operator_name('-not_like 2') } qr/not an operator/, 'a space before the digits is no suffix';
lives_ok { $sm->where({ name => { -like_1 => 'a%' } }) } 'condition with -like_1';
throws_ok { $sm->_assert_operator_name('foo_1') } qr/not an operator/,
  'suffix of an unknown word';
throws_ok { $sm->_assert_operator_name('-_1') } qr/not an operator/,
  'suffix alone';

# a driver extends the list through the class method
{
  package My::OperatorSQLMaker;
  our @ISA = ('DBIO::SQLMaker');
  sub operator_words { my $c = shift; ($c->SUPER::operator_words, 'contains') }
}
my $custom = My::OperatorSQLMaker->new;
lives_ok { $custom->_assert_operator_name('-contains') } 'driver word';
throws_ok { $sm->_assert_operator_name('-contains') } qr/not an operator/,
  'the base list does not know it';

done_testing;
