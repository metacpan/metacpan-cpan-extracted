package MuDu::Command::Resume;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'mark a task as ongoing',
      description => 'Set a task in active mode (from done or waiting)',
      supports    => [qw< resume active restart ongoing >],
      execute     => \&execute
   }
}

sub execute ($m, $config, $args) { move_task($config, $args, 'ongoing') }

1;
