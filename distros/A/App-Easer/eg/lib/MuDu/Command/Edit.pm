package MuDu::Command::Edit;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'edit a task',
      description => 'Start an editor to modify the task',
      supports    => [qw< edit modify change update >],
      options     => [
         {
            help   => 'set the editor for adding the task, if needed',
            getopt => 'editor|visual|e=s',
            environment => 'VISUAL',
            default     => 'vi',
         }
      ],
      execute => \&execute,
   }
}

sub execute ($main, $config, $args) {
   my $target = resolve($config, $args->[0]);
   my $previous = $target->slurp_utf8;
   return 0 if edit_file($config, $target) && length get_title($target);
   $target->spew_utf8($previous);
   fatal("bailing out editing task");
}

1;
