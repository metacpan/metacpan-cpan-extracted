#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 9;
use Data::Dumper;
use lib qw(../lib lib);
use Scalar::Util qw(blessed);
BEGIN { use_ok('Data::Range::Compare') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $obj=Data::Range::Compare->new({},1,2);
ok($obj,'basic used of the constructor');
ok(!$obj->missing,'obj should not be missing');
ok(!$obj->generated,'obj should not be generated');
$obj=Data::Range::Compare->new({},1,2,1);

ok($obj->generated,'obj should be generated');

ok(!$obj->missing,'obj should not be missing');

$obj=Data::Range::Compare->new({},1,2,0,1);

ok(!$obj->generated,'obj should not be generated');

ok($obj->missing,'obj should be missing');

$obj=new Data::Range::Compare({},0,1);
ok($obj,'syntax new class check');
