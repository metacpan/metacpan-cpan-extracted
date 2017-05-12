# Before `make install' is performed this script should be runnable with
# `make test'. 

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 13;
use Data::Dumper;

BEGIN {
    use_ok('Collection::Utl::StoreDir');
    use_ok( 'File::Temp', qw/ tempfile tempdir / );
}
ok my $tmp_dir = tempdir( CLEANUP => 1 ), 'create tmp dir';
isa_ok my $store1 = ( new Collection::Utl::StoreDir:: $tmp_dir ),
  'Collection::Utl::StoreDir', "on $tmp_dir";
my $test_key1 = "test.txt";
my $test_val1 = "test file";
my $test_key2 = "test2.txt";
$store1->putText( $test_key1, $test_val1 );
is_deeply( $store1->get_keys, [$test_key1], "check get keys" );
$store1->delete_keys($test_key1);
is_deeply( $store1->get_keys, [], "check get keys after delete" );
my $tmp_dir1 = $store1->_dir . "dir1";
isa_ok my $store2 = ( new Collection::Utl::StoreDir:: $tmp_dir1 ),
  'Collection::Utl::StoreDir', "on $tmp_dir1";
$store2->putText( $test_key1, $test_val1 );
is_deeply( $store2->get_keys, [$test_key1], "check get keys" );
is_deeply( $store1->get_keys, [],
    "check get keys (check skip dir in key list)" );
is $store2->getText($test_key1), $test_val1, 'check content';
$store1->putText( $test_key2, $store2->getText_fh($test_key1) );
is_deeply( $store1->get_keys, [$test_key2],
    'check keys store1->putText(key, $fh)' );
$store2->clean;
ok !-e $tmp_dir1, 'check clean2';
$store1->clean;
ok !-e $tmp_dir, 'check clean1';

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

