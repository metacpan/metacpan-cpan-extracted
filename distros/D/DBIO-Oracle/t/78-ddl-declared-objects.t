use strict;
use warnings;
use Test::More;

use DBIO::Test::Conformance ();
use DBIO::Oracle::DDL ();
use DBIO::Oracle::Identifier ();

# OFFLINE (karr k56). DBIO::Oracle::DDL->declared_objects names the objects an
# install writes, as the dictionary holds them -- what the cleanup of
# DBIO::Oracle::Test::Conformance drops and nothing more. The generated names
# come out of the same code that writes the statements, so a name shortened to
# 30 characters is the shortened one, not a second computation of it.

my $long = 'a_table_with_a_rather_long_name';
my $schema = DBIO::Test::Conformance->_build_schema_class({
  name => 't78',
  input => { sources => [
    { name => 'Long', table => $long,
      columns => [ id => { data_type => 'integer', is_nullable => 0, is_auto_increment => 1 },
                   code => { data_type => 'varchar', size => 10 } ],
      primary_key => ['id'],
      indexes => [ { name => 'by_code', columns => ['code'] } ],
    },
    { name => 'Lit', table => \'lit', columns => [ id => { data_type => 'integer' } ],
      primary_key => ['id'] },
    { name => 'V', table => 'v78', columns => [ id => { data_type => 'integer' } ],
      view => { definition => 'SELECT "id" FROM "' . $long . '"', virtual => 0 } },
  ] },
});

my $objects = DBIO::Oracle::DDL->declared_objects($schema);

is_deeply [ sort @{ $objects->{table} } ], [ sort $long, 'LIT' ],
  'the tables: a quoted name as spelled, a literal name as Oracle folds it';
is_deeply $objects->{view}, ['v78'], 'the view';
is_deeply $objects->{sequence}, [ DBIO::Oracle::Identifier::shorten("${long}_id_seq") ],
  'the sequence of the auto-increment column, with the shortened name';
is_deeply $objects->{trigger}, [ DBIO::Oracle::Identifier::shorten("${long}_id_trg") ],
  '... and its trigger';
cmp_ok length($objects->{sequence}[0]), '<=', 30, '... the name fits Oracle\'s 30 characters';
isnt $objects->{sequence}[0], "${long}_id_seq", '... and is not the long one';

is_deeply $objects->{index}, [ [ 'by_code', $long ] ], 'the index, with its table';

my $err = eval {
  DBIO::Oracle::DDL->declared_objects(DBIO::Test::Conformance->_build_schema_class({
    name => 't78b', input => { sources => [
      { name => 'E', table => 'e78', columns => [ id => { data_type => 'enum' } ], primary_key => ['id'] } ] } }));
  1 } ? '' : "$@";
like $err, qr/refus/, 'a declaration the install refuses is refused here, too: nothing was sent, nothing to drop';

done_testing;
