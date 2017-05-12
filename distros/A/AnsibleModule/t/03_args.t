use strict;
use warnings;
use Test::More;
use Test::AnsibleModule;
my $t = Test::AnsibleModule->new;

$t->run_ok('t/ext/arg_test', bye => 'bye');
is_deeply $t->last_response,
  {
  changed => 0,
  msg     => 'arg_test',
  yay     => 'yes',
  hello   => 'bye',
  bye     => 'bye'
  };
done_testing;
