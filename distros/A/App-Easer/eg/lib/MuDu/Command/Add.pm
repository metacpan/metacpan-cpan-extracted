package MuDu::Command::Add;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';
use POSIX 'strftime';

use MuDu::Utils;

sub spec { __PACKAGE__->autospec() }
sub help        { return 'add a task' }
sub description { return 'Add a task, optionally setting it as waiting' }
sub supports    { return [qw< add new post >] }
sub options {
   return [
      {
         help   => 'add the tasks as waiting',
         getopt => 'waiting|w!'
      },
      {
         help   => 'set the editor for adding the task, if needed',
         getopt => 'editor|visual|e=s',
         environment => 'VISUAL',
         default     => 'vi',
      }
   ];
}
sub execute ($main, $config, $args) {
   my $id = strftime('%Y%m%d-%H%M%S', localtime);
   my $category = $config->{waiting} ? 'waiting' : 'ongoing';
   my $hint = path($config->{basedir})->child($category, $id);
   my $target = add_file($config, $hint, '');
   if ($args->@*) {
      $target->spew_utf8(join(' ', $args->@*) . "\n");
      return 0;
   }
   return 0 if edit_file($config, $target) && length get_title($target);
   $target->remove if -e $target;
   fatal("bailing out creating new task");
}

1;
