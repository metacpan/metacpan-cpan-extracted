# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TCC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('C::TCC') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tcc = C::TCC->new();
$ret = $tcc->set_output_type(TCC_OUTPUT_OBJ);
ok($ret == 0);
$ret = $tcc->compile_string('int main(){printf("Hello World.\n"); return 0;}');
ok($ret == 0);
$ret = $tcc->output_file("hello.o");
ok($ret == 0);
undef $tcc;

$tcc = C::TCC->new();
$ret = $tcc->add_file('hello.o');
ok($ret == 0);
$ret = $tcc->run();
ok($ret == 0);
