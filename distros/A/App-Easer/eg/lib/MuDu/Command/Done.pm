package MuDu::Command::Done;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'mark a task as completed',
      description => 'Archive a task as completed',
      supports    => [qw< done tick yay >],
      execute     => \&execute,
   }
}

sub execute ($m, $config, $args) { move_task($config, $args, 'done') }

1;
