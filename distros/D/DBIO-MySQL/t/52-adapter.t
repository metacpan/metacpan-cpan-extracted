use strict; use warnings;
use Test::More;
use DBIO::MySQL::Adapter ();

my $a = DBIO::MySQL::Adapter->new;
is $a->to_native({ base_type => 'integer' }),   'BIGINT';
is $a->to_native({ base_type => 'text' }),      'LONGTEXT';
is $a->to_native({ base_type => 'boolean' }),   'TINYINT(1)';
is $a->to_native({ base_type => 'double' }),    'DOUBLE';
is $a->to_native({ base_type => 'blob' }),      'LONGBLOB';
is $a->to_native({ base_type => 'timestamp' }), 'DATETIME';
is $a->to_native({ base_type => 'char', size => 10 }), 'CHAR(10)';
is $a->to_native({ base_type => 'numeric', precision => 8, scale => 2 }), 'DECIMAL(8,2)';
is $a->capabilities->{supports_alter_column_type}, 1, 'MySQL can alter column type';
eval { $a->to_native({ base_type => 'uuid' }) };
like $@, qr/no MySQL native type/, 'unknown base type croaks';
done_testing;
