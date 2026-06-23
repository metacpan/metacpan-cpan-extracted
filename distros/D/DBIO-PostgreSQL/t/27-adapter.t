use strict; use warnings;
use Test::More;
use DBIO::PostgreSQL::Adapter ();

my $a = DBIO::PostgreSQL::Adapter->new;
is $a->to_native({ base_type => 'integer' }),   'bigint';
is $a->to_native({ base_type => 'text' }),      'text';
is $a->to_native({ base_type => 'boolean' }),   'boolean';
is $a->to_native({ base_type => 'double' }),    'double precision';
is $a->to_native({ base_type => 'blob' }),      'bytea';
is $a->to_native({ base_type => 'timestamp' }), 'timestamptz';
is $a->to_native({ base_type => 'char', size => 10 }), 'character(10)';
is $a->to_native({ base_type => 'numeric', precision => 8, scale => 2 }), 'numeric(8,2)';
is $a->capabilities->{supports_alter_column_type}, 1, 'PostgreSQL can alter column type';
eval { $a->to_native({ base_type => 'uuid' }) };
like $@, qr/no PostgreSQL native type/, 'unknown base type croaks';
done_testing;
