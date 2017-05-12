# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CGI-okTemplate.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('CGI::okTemplate') };
our $data;
require 't/data.inc';
ok(($tmp = new CGI::okTemplate), 'create new objest');
ok($tmp->read_template('t/test.tpl'), 'read template file');
ok($txt = $tmp->parse($data), 'parse data');
open OUT, '> t/result.txt';
print OUT $txt;
close OUT;
cmp_ok(-s 't/result.txt', '==', -s 't/test.txt', 'compare file size');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

