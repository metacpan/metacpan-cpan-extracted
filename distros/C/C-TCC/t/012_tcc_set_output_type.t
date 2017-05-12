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
$ret = $tcc->set_output_type(TCC_OUTPUT_MEMORY);
ok($ret == 0);
undef $tcc;

$tcc = C::TCC->new();
$ret = $tcc->set_output_type(TCC_OUTPUT_EXE);
ok($ret == 0);
undef $tcc;

$tcc = C::TCC->new();
$ret = $tcc->set_output_type(TCC_OUTPUT_DLL);
ok($ret == 0);
undef $tcc;

$tcc = C::TCC->new();
$ret = $tcc->set_output_type(TCC_OUTPUT_OBJ);
ok($ret == 0);
undef $tcc;

$tcc = C::TCC->new();
$ret = $tcc->set_output_type(TCC_OUTPUT_PREPROCESS);
ok($ret == 0);
undef $tcc;
