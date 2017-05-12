# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl TCC.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 3;
BEGIN { use_ok('C::TCC') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tcc = C::TCC->new();
$tcc->define_symbol('SYM', 1);
$tcc->undefine_symbol('SYM');
$ret = $tcc->compile_string('
int main()
{
#ifdef SYM
    return 1;
#else
    return 2;
#endif
}');
ok($ret == 0);
$ret = $tcc->run();
ok($ret == 2);
