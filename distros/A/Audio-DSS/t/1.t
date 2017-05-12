# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Audio::DSS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $testfile =  'eg/dss_is_cool.dss';
my $dss = new Audio::DSS($testfile);
# print $dss->{file};
is($dss->{file}, 'eg/dss_is_cool.dss', 'filename is okay');
is($dss->{create_date}, '2004-08-17 17:33:02', 'create_date is okay');
is($dss->{complete_date}, '2004-08-17 17:33:04', 'complete_date is okay');

