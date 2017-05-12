########################################
# 000.setup - jusst create the autodb
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use Class::AutoDB;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test

pass('setup');
done_testing();
