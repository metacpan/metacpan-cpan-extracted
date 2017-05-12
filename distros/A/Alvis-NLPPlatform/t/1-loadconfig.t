
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 0-creation.t'

#########################

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More tests => 2;

BEGIN { use_ok('Alvis::NLPPlatform') }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# Instantiation of abstract subclass
my %config;
my $def_config;
my $doc_xml;
eval { use Alvis::NLPPlatform; };
eval { use Config::General; };
eval { use Data::Dumper; };
eval { (%config = Alvis::NLPPlatform::load_config("etc/alvis-nlpplatform/nlpplatform.rc")) && ($def_config=1); };
ok(defined $def_config);
