package MuDu::Command::Show;
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use MuDu::Utils;

sub spec {
   return {
      help        => 'print one task',
      description => 'Print one whole task',
      supports    => [qw< show print get >],
      execute     => __PACKAGE__,
   };
}

sub execute ($main, $config, $args) {
   my $child = resolve($config, $args->[0]);
   my $contents = $child->slurp_utf8;
   $contents =~ s{\n\z}{}mxs;
   say "----\n$contents\n----";
   return 0;
} ## end sub show

1;
