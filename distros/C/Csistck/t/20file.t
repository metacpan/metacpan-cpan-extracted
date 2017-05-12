use Test::More;
use Test::Exception;
use Csistck;
use File::Temp;
use File::stat;

plan tests => 13;

my $h = File::Temp->new();
my $file = $h->filename;
print $h "Test";
chmod(oct('0666'), $file);

my $t = file($file, mode => '0660');

isa_ok($t, Csistck::Test);
ok($t->can('check'), 'Has check');
ok($t->check, 'Manual check');
isa_ok($t->check, Csistck::Test::Return, 'Manual check return');

# Expect fail, repair should pass, then check should pass 
my $ret;
$ret = $t->execute('check');
is($ret->failed, 1, 'False check expect fail');
isnt($ret->failed, 0, 'False check not not fail');
isnt($ret->passed, 1, 'False check not pass');
$ret = $t->execute('repair');
is($ret->passed, 1, 'Repair expect pass');
isnt($ret->passed, 0, 'Repair not not pass');
isnt($ret->failed, 1, 'Repair not fail');
$ret = $t->execute('check');
is($ret->passed, 1, 'Check expect pass');
isnt($ret->passed, 0, 'Check not not pass');
isnt($ret->failed, 1, 'Check not fail');

1;
