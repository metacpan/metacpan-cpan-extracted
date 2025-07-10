use strict;
use warnings;
use Test::Most;
use DB::Berkeley;
use MIME::Base64;
use Encode qw(encode_utf8);

my $file = 't/binary.db';
unlink $file if -e $file;

my $db = DB::Berkeley->new($file, 0, 0600);

# Binary strings with nulls and UTF-8
my $key1   = "bin\0key";
my $value1 = "val\xFF\xFE\0ue";

my $key2   = "\x00\x01\x02\x03";
my $value2 = "\xAB\xCD\xEF";

my $key3   = encode_utf8("\x{2603}");  # Unicode Snowman as bytes
my $value3 = encode_utf8("\x{1F4A9}"); # Unicode Pile of Poo as bytes


# Put binary data
ok($db->put($key1, $value1), 'Put binary key1 => value1');
ok($db->put($key2, $value2), 'Put binary key2 => value2');
ok($db->put($key3, $value3), 'Put binary key3 => value3');

# Get and verify with base64 encoding to avoid wide char warnings
is($db->get($key1), $value1, 'Binary get key1 matches (base64)');
is($db->get($key2), $value2, 'Binary get key2 matches (base64)');
is($db->get($key3), $value3, 'Binary get key3 matches (base64)');

# exists
ok($db->exists($key1), 'exists() works with binary key1');
ok(!$db->exists('notfound'), 'non-existent binary key not found');

# keys
my $keys_ref = $db->keys;
cmp_deeply(
	[ sort map { encode_base64($_, '') } @$keys_ref ],
	[ sort map { encode_base64($_, '') } ($key1, $key2, $key3) ],
	'Binary keys match (base64)'
);

# delete
ok($db->delete($key2), 'Deleted binary key2');
ok(!$db->exists($key2), 'key2 no longer exists');

# get after delete
is(undef, $db->get($key2), 'key2 returns undef after delete');

# Done
done_testing();

END { unlink $file if -e $file }
