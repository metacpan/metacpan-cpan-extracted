# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TCC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('C::TCC') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tcc;
$tcc = C::TCC->new();
$tcc->compile_string('int main(){return 0;}');
$ret = $tcc->run();
ok($ret == 0);
undef $tcc;

$tcc = C::TCC->new();
$tcc->compile_string('int main(){return 1;}');
$ret = $tcc->run();
ok($ret == 1);
undef $tcc;

$tcc = C::TCC->new();
$tcc->compile_string('int main(){return 255;}');
$ret = $tcc->run();
ok($ret == 255);
undef $tcc;

$tcc = C::TCC->new();
$tcc->compile_string('int main(int argc, char *argv[]){return argc;}');
$ret = $tcc->run(('a', 'b', 'c'));
ok($ret == 3);
undef $tcc;

$tcc = C::TCC->new();
$tcc->compile_string('
int main(int argc, char *argv[])
{
    int i, ret=0;
    for(i=0; i<argc; i++){
        ret+=atoi(argv[i]);
    }
    return ret;
}');
$ret = $tcc->run('1', '2', '3');
ok($ret == 6);
undef $tcc;
