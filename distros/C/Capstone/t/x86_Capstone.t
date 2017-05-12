# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Capstone.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Capstone', ':all'); }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $cs;
my @ins;

# Testing CS_MODE_32
ok($cs = Capstone->new(CS_ARCH_X86, CS_MODE_32));

ok(scalar((@ins = $cs->dis("\x90\x90\xcd\x80"))) == 3);

ok($ins[0]{mnemonic} eq 'nop');

ok($ins[2]{mnemonic} eq 'int' &&
   $ins[2]{op_str} eq '0x80');

ok($cs->set_option(CS_OPT_SYNTAX, CS_OPT_SYNTAX_ATT));


# Testing CS_MODE_64
undef $cs;

ok($cs = Capstone->new(CS_ARCH_X86, CS_MODE_64));

ok(scalar((@ins = $cs->dis("\x48\x83\xec\x08\x48\x85\xc0", 0xFFFFFFF, 0))) == 2);

ok($ins[1]{mnemonic} eq 'test' &&
   $ins[1]{op_str} eq 'rax, rax');

ok($ins[0]{mnemonic} eq 'sub');
ok($ins[0]{op_str} eq 'rsp, 8');

ok($ins[1]{address} == 0x10000003); 
ok($cs->set_option(CS_OPT_SYNTAX, CS_OPT_SYNTAX_ATT));

    
