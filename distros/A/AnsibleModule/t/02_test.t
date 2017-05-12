use Test::More;
use strict;
use warnings;
use Data::Dumper qw/Dumper/;

use_ok('Test::AnsibleModule');
my $t = Test::AnsibleModule->new;
$t->run_ok('t/ext/exit_json', {});
$t->is_response({changed => 0, msg => "exit_json"}, 'Response as expected');
$t->fail_ok('t/ext/fail_json', {});
$t->is_response({msg => "fail_json", failed => 1}, 'Response as expected');
$t->run_ok('t/ext/echo', {hello => 'world'});
$t->is_response({changed => 0, msg => "echo", hello => 'world'},
  'Response as expected');
done_testing;
