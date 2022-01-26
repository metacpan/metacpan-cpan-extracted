package MuDu::Command::Cat;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec { __PACKAGE__->autospec(help => 'print one task (no delimiters)') }
sub description { return 'Print one whole task, without adding delimiters' }
sub supports    { return [qw< cat >] }
sub execute ($main, $config, $args) {
   my $child = resolve($config, $args->[0]);
   print {*STDOUT} $child->slurp_utf8;
   return 0;
}

1;
