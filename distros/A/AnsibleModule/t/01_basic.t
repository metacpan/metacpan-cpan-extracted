use Test::More;
use strict;
use warnings;

use Test::AnsibleModule;
my $t = Test::AnsibleModule->new;
{
  use_ok('AnsibleModule');
  my $m = AnsibleModule->new;
  isa_ok $m, 'AnsibleModule';

  # exit_json
  can_ok $m, 'exit_json';
  $t->run_ok('t/ext/exit_json');
};

done_testing;
