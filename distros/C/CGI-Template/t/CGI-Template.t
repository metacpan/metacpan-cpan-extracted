# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-Template.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('CGI::Template') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use CGI::Template;

my $t = new CGI::Template;

my $reply = $t->header();
ok( $reply =~ m/Content-type: text\/html\n\n/ );
