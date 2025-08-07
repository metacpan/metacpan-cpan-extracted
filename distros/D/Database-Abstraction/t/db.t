# Check Berkeley DB

use strict;
use warnings;

use Fcntl;
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

use Test::Needs 'DB_File';

# Define a subclass to instantiate (Database::Abstraction is abstract)
BEGIN {
	package Database::Test;
	use base 'Database::Abstraction';
}

# Create a temporary directory for our Berkeley DB file
my $dir = tempdir(CLEANUP => 1);
my $dbfile = File::Spec->catfile($dir, 'Test.db');

# Tie a hash to a BerkeleyDB file (create it) and insert some entries
tie my %db, 'DB_File', $dbfile, O_CREAT|O_RDWR, 0644, $DB_File::DB_HASH
	or die "Cannot tie $dbfile: $!";

%db = (
	k1 => 'v1',
	k2 => 'v2',
);
untie %db;

# Verify the DB file exists
ok(-e $dbfile, 'Berkeley DB file created');

# Instantiate our Database::Abstraction subclass pointing to $dir
my $dao = Database::Test->new(directory => $dir);
isa_ok($dao, 'Database::Test', 'Got a Database::Test object');

# Test fetchrow_hashref: retrieve a row by key
my $row = $dao->fetchrow_hashref(entry => 'k1');
is_deeply($row, { entry => 'v1' }, 'fetchrow_hashref returned correct hashref');

# Test AUTOLOAD column access: calling ->entry('k2') returns the value
is($dao->entry('k2'), 'v2', 'AUTOLOAD entry() returns correct value for k2');

# Test that selectall_hash croaks on BerkeleyDB (unsupported)
dies_ok { $dao->selectall_hash() } 'selectall_hash croaks for BerkeleyDB';

# Clean up (optional; tempdir with CLEANUP => 1 will auto-remove)
done_testing();
