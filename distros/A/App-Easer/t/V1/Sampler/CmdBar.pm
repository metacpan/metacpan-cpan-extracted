package Sampler::CmdBar;

sub spec {
   return {
      help        => 'sub-command bar',
      description => 'first-level sub-command bar',
      supports => [qw< bar >],
      execute => __PACKAGE__,
      children => 0,
   };
}

sub execute ($main, $conf, $args) {
   print {*STDOUT} 'bar on out';
   print {*STDERR} 'bar on err';
   return 'Bar';
};

1;
