# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'


use Data::Dumper;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;

if (defined $ENV{CONFIG_DBI}) {
  plan tests => 1;	
} else {
  plan skip_all => 'Cannot run test unless CONFIG_DBI is defined. See docs';
}

use_ok('Config::DBI');



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my %X = Config::DBI->hash('basic');

warn Dumper(\%X);

#my $dbh = Config::DBI->basic;
