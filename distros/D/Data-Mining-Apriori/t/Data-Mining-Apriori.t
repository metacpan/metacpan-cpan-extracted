# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Data-Mining-Apriori.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 13;
BEGIN { 
	use_ok('Data::Mining::Apriori') 
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

can_ok("Data::Mining::Apriori", 'new');
can_ok("Data::Mining::Apriori", 'validate_data');
can_ok("Data::Mining::Apriori", 'insert_key_items_transaction');
can_ok("Data::Mining::Apriori", 'input_data_file');
can_ok("Data::Mining::Apriori", 'quantity_possible_rules');
can_ok("Data::Mining::Apriori", 'generate_rules');
can_ok("Data::Mining::Apriori", 'association_rules');
can_ok("Data::Mining::Apriori", 'stop');
can_ok("Data::Mining::Apriori", 'output');
can_ok("Data::Mining::Apriori", 'file');
can_ok("Data::Mining::Apriori", 'excel');

my $apriori = new Data::Mining::Apriori;

isa_ok($apriori, 'Data::Mining::Apriori');
