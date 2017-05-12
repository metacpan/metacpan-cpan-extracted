# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Catalyst-Plugin-DateTime.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { 
	use_ok('Catalyst::Plugin::DateTime') 
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#
# DateTime->new test
#
my $new = Catalyst::Plugin::DateTime->datetime(month => '01', year => '2003', day => '14');
ok(((defined $new) && (ref $new eq 'DateTime')), 'datetime() with args works');

$new = Catalyst::Plugin::DateTime->dt(month => '01', year => '2003', day => '14');
ok(((defined $new) && (ref $new eq 'DateTime')), 'dt() with args works');

#
# DateTime->now (no args) test
#
my $now = Catalyst::Plugin::DateTime->datetime();
ok(((defined $now) && (ref $now eq 'DateTime')), 'datetime() without args works');

$now = Catalyst::Plugin::DateTime->dt();
ok(((defined $now) && (ref $now eq 'DateTime')), 'dt() without args works');

