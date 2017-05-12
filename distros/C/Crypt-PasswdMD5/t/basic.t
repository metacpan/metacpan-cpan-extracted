use strict;
use warnings;

use Test::More;

# ------------------------------------------------

use_ok('Crypt::PasswdMD5');

my($phrase1) = "hello world\n";
my($stage1)  = '$1$1234$BhY1eAOOs7IED4HLA5T5o.';

$|=1;

ok(unix_md5_crypt($phrase1, '1234') eq $stage1, 'Hashing of a simple phrase + salt');

ok(unix_md5_crypt($phrase1, $stage1) eq $stage1, 'Rehash (check) of the phrase');


my($t) = unix_md5_crypt('', $$);

ok(unix_md5_crypt('', $t) eq $t, 'Hashing/rehashing of the empty password');

$t        = unix_md5_crypt('test4');
my($salt) = ($t =~ m/\$.+\$(.+)\$/);

ok(unix_md5_crypt('test4', $salt) eq $t, 'Make sure null salt works');

# Warning: Do not remove the () around ($salt).

$t      = apache_md5_crypt('test5');
($salt) = ($t =~ m/\$.+\$(.+)\$/);

ok(apache_md5_crypt('test5', $salt) eq $t, 'And again with the Apache Variant');

ok($t =~ /^\$apr1\$/, '$t now has the correct value');

done_testing;
