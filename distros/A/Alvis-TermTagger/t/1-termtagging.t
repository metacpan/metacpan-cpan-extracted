
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 0-creation.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 2;

BEGIN { use_ok('Alvis::TermTagger') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass
my $factory;
eval { use Alvis::TermTagger; };
eval { *STDERR=*STDOUT; };
ok(Alvis::TermTagger::termtagging("etc/corpus-test.txt", "etc/termlist-test.lst", "etc/output") == 0);


