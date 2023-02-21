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
		is $current->get_column('passphrase'), '$reversed$oom', 'Column stored as reversed after create';
		isa_ok $current->get_inflated_column('passphrase'), 'Crypt::Passphrase::PassphraseHash';
		is $current->get_inflated_column('passphrase')->raw_hash, '$reversed$oom', 'Column stored as reversed after create';

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


	$row->update({ passphrase => 'mookooh' })->discard_changes;
	ok $row->verify_passphrase('mookooh'), 'Accepts new correct passphrase using check method';
	ok !$row->verify_passphrase('moo'), 'Rejects old passphrase using check method';
}

done_testing;
