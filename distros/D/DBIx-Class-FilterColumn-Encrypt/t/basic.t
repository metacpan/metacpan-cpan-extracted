use strict;
use warnings;
use Test::More 0.89;

use lib 't/lib';

use TestEncrypt;
use Crypt::Passphrase;

my $schema = TestEncrypt->connect('dbi:SQLite:dbname=:memory:');

my $sql = do { open my $fh, '<:raw', 't/lib/TestSchema.sql' or die $!; local $/; <$fh> };
$schema->storage->dbh->do($sql);

my $rs = $schema->resultset('Foo');

my $inserted = $rs->create({ data => 'abcd' });

my $id = $inserted->id;

my $row = $rs->find({ id => $id });

is $inserted->data, 'abcd', 'Column inserted as data';
is $row->data, 'abcd', 'Column stored as data';

my $raw1 = $inserted->get_column('data');
my $raw2 = $row->get_column('data');

isnt $raw1, 'abcd', 'data isn\'t abcd on insert';
is length $raw1, 37, 'data has the right length on insert';

isnt $raw2, 'abcd', 'data isn\'t abcd on fetch';
is length $raw2, 37, 'data has the right length on fetch';

done_testing;

