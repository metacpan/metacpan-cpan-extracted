use strict;
use warnings;
use Test::More 0.89;

use lib 't/lib';

use TestColumn;

my $schema = TestColumn->connect('dbi:SQLite:dbname=:memory:');

my $sql = do { open my $fh, '<:raw', 't/lib/TestSchema.sql' or die $!; local $/; <$fh> };
$schema->storage->dbh->do($sql);

my $rs = $schema->resultset('Foo');

{
	my $new = $rs->create({ passphrase => 'moo' });
	my $row = $rs->find({ id => $new->id });

	for my $current ($new, $row) {
		like $current->get_column('passphrase'), qr/reversed/, 'Column stored as reversed after create';
		isa_ok $current->get_inflated_column('passphrase'), 'Crypt::Passphrase::PassphraseHash';
		like $current->get_inflated_column('passphrase')->raw_hash, qr/reversed/, 'Column stored as reversed after create';

		ok !$current->verify_passphrase('mookooh'), 'Rejects incorrect passphrase using check method';
		ok $current->verify_passphrase('moo'), 'Accepts correct passphrase using check method';
		ok $current->passphrase->verify_password('moo'), 'Accepts correct passphrase using object';
		ok !$current->passphrase_needs_rehash, 'Password does not need rehash';
	}


	my $ppr = $row->passphrase;
	isa_ok $ppr, 'Crypt::Passphrase::PassphraseHash';
	ok !$ppr->verify_password('mookooh'), 'Rejects incorrect passphrase';
	ok $ppr->verify_password('moo'), 'Accepts correct passphrase';
	ok !$ppr->needs_rehash, 'Password does not need rehash';

	my $passphraser = $row->column_info('passphrase')->{inflate_passphrase};
	$row->update({ passphrase => $passphraser->curry_with_hash('$reversed$oom') })->discard_changes;
	ok $row->passphrase_needs_rehash, 'Rehash is needed before verify and rehash';
	ok $row->verify_and_rehash_password('moo'), 'Verify and rehash successful';
	ok !$row->passphrase_needs_rehash, 'No second rehash is needed after verify and rehash';
	ok $row->verify_passphrase('moo'), 'Verifies after verify and rehash';

	$row->update({ passphrase => 'mookooh' })->discard_changes;
	ok $row->verify_passphrase('mookooh'), 'Accepts new correct passphrase using check method';
	ok !$row->verify_passphrase('moo'), 'Rejects old passphrase using check method';

}

done_testing;
