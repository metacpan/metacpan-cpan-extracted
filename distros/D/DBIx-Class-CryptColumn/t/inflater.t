use strict;
use warnings;
use Test::More 0.89;

use lib 't/lib';

use TestInflate;
use Crypt::Passphrase;
use Crypt::Passphrase::PassphraseHash;

my $schema = TestInflate->connect('dbi:SQLite:dbname=:memory:');

my $sql = do { open my $fh, '<:raw', 't/lib/TestSchema.sql' or die $!; local $/; <$fh> };
$schema->storage->dbh->do($sql);

my $rs = $schema->resultset('Foo');

my $passphrase = TestInflate::Result::Foo->crypt_passphrase;;
my $object = Crypt::Passphrase::PassphraseHash->new($passphrase, $passphrase->hash_password('moo'));

my $id = $rs->create({ passphrase => $object })->id;

my $row = $rs->find({ id => $id });

is $row->get_column('passphrase'), 'oom', 'Column stored as reversed';

my $ppr = $row->passphrase;
isa_ok $ppr, 'Crypt::Passphrase::PassphraseHash';

ok !$ppr->verify_password('affe'), 'Rejects wrong passphrase';
ok $ppr->verify_password('moo'), 'Accepts correct passphrase';

done_testing;
