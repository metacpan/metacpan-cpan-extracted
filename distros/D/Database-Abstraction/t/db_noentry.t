# Check Berkeley DB with no_entry set

use strict;
use warnings;

use Fcntl;
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

use Test::Needs 'DB_File';

# Define a subclass to instantiate (since Database::Abstraction is abstract)
BEGIN {
	package Database::Test;
	use base 'Database::Abstraction';
}

# Create a temporary Berkeley DB file
my $dir = tempdir(CLEANUP => 1);
my $dbfile = File::Spec->catfile($dir, 'Test.db');

# Tie a hash and populate the database
tie my %db, 'DB_File', $dbfile, O_CREAT|O_RDWR, 0644, $DB_File::DB_HASH
	or die "Cannot tie $dbfile: $!";

%db = (
	alpha => 'one',
	beta  => 'two',
);
untie %db;

ok(-e $dbfile, 'Berkeley DB file created');

# Instantiate Database::Test with no_entry mode enabled
my $dao = Database::Test->new(directory => $dir, no_entry => 1);
isa_ok($dao, 'Database::Test', 'Got a Database::Test object');

# fetchrow_hashref should return scalar value, not hashref
my $value = $dao->fetchrow_hashref(entry => 'alpha');
is($value->{'alpha'}, 'one', 'fetchrow_hashref returned correct scalar value with no_entry');

# Also test with nonexistent key
my $undef = $dao->fetchrow_hashref(entry => 'does_not_exist');
ok(!defined $undef, 'Nonexistent entry returns undef');

done_testing();
