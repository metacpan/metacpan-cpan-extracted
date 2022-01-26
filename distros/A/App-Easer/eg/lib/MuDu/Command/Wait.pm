package MuDu::Command::Wait;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'mark a task as waiting',
      description => 'Set a task as waiting for external action',
      supports    => [qw< waiting wait >],
      execute     => \&execute
   }
}

sub execute ($m, $config, $args) { move_task($config, $args, 'waiting') }

1;
