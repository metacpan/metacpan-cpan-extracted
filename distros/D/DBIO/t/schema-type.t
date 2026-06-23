use strict; use warnings;
use Test::More;
use DBIO::Schema::Type ();

is DBIO::Schema::Type::normalize('integer'),   'integer',   'integer';
is DBIO::Schema::Type::normalize('INT'),        'integer',   'int alias, case-insensitive';
is DBIO::Schema::Type::normalize('bigint'),     'integer',   'bigint -> integer';
is DBIO::Schema::Type::normalize('varchar'),    'text',      'varchar -> text';
is DBIO::Schema::Type::normalize('varchar(255)'),'text',     'varchar(n) -> text (params stripped)';
is DBIO::Schema::Type::normalize('character'),  'char',      'character -> char';
is DBIO::Schema::Type::normalize('decimal'),    'numeric',   'decimal -> numeric';
is DBIO::Schema::Type::normalize('real'),       'double',    'real -> double';
is DBIO::Schema::Type::normalize('bytea'),      'blob',      'bytea -> blob';
is DBIO::Schema::Type::normalize('datetime'),   'timestamp', 'datetime -> timestamp';

eval { DBIO::Schema::Type::normalize('geometry') };
like $@, qr/unknown data_type/, 'unknown type dies';

my $c = DBIO::Schema::Type::canonical_column('id',
  { data_type => 'integer', is_auto_increment => 1 });
is $c->{base_type}, 'integer', 'canonical base_type';
is $c->{not_null},  1,         'absent is_nullable => not_null';
is $c->{auto_increment}, 1,    'auto_increment carried';

my $v = DBIO::Schema::Type::canonical_column('name',
  { data_type => 'char', size => 32, is_nullable => 1 });
is $v->{base_type}, 'char', 'char base_type';
is $v->{size},      32,     'char size carried';
is $v->{not_null},  0,      'is_nullable => not not_null';

my $n = DBIO::Schema::Type::canonical_column('amount',
  { data_type => 'numeric', size => [10, 2] });
is $n->{precision}, 10, 'numeric precision';
is $n->{scale},      2, 'numeric scale';

done_testing;
