use strict;
use warnings;
use Test::More 'no_plan';

BEGIN { use_ok 'Coat::Persistent' }
{
    package Foo;
    use Coat;
    use Coat::Persistent;
}

Coat::Persistent->map_to_dbi('csv', 'f_dir=./t/csv-test-database');
my $dbh = Foo->dbh;
ok( defined $dbh, 'default dbh found' );
$dbh->do("DROP TABLE dbix_sequence_state");
$dbh->do("DROP TABLE dbix_sequence_release");
