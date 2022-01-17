# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Condensation.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Condensation') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

require_ok('CDS::Hash');
ok(defined CDS::Hash->fromHex('e0d3b82f94c678f48e83b756675227bdd30568d24130bfc03667833d58f5687b'), 'Text to hash (correct)');
ok(! defined CDS::Hash->fromHex(''), 'Text to hash (empty)');
ok(! defined CDS::Hash->fromHex('idf2h23iuh3k'), 'Text to hash (any)');

require_ok('CDS::KeyPair');
require_ok('CDS::ActorGroup');
require_ok('CDS::HTTPStore');
require_ok('CDS::FolderStore');

done_testing;
