use strict; use warnings;
use Test::More;
use DBIO::SQLite::Adapter ();

my $a = DBIO::SQLite::Adapter->new;
is $a->to_native({ base_type => 'integer' }),   'INTEGER';
is $a->to_native({ base_type => 'text' }),      'TEXT';
is $a->to_native({ base_type => 'boolean' }),   'BOOLEAN';
is $a->to_native({ base_type => 'double' }),    'REAL';
is $a->to_native({ base_type => 'blob' }),      'BLOB';
is $a->to_native({ base_type => 'timestamp' }), 'TEXT';
is $a->to_native({ base_type => 'char', size => 10 }), 'CHAR(10)';
is $a->to_native({ base_type => 'numeric', precision => 8, scale => 2 }), 'NUMERIC(8,2)';
is $a->capabilities->{supports_alter_column_type}, 0, 'SQLite cannot alter column type';

eval { DBIO::SQLite::Adapter->new->to_native({ base_type => 'uuid' }) };
like $@, qr/no SQLite native type/, 'unknown base type croaks';

done_testing;
