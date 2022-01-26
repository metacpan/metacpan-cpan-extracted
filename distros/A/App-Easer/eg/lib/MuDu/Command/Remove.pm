package MuDu::Command::Remove;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'delete a task',
      description => 'Get rid of a task (definitively)',
      supports    => [qw< remove rm delete del >],
      execute     => \&execute
   }
}

sub execute ($m, $config, $args) {
   resolve($config, $args->[0])->remove;
   return 0;
}

1;
