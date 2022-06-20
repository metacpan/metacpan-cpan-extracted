package Sampler::CmdFoo::CmdBaz;

sub spec {
   return {
      help => 'sampler foo baz',
      supports => [qw< baz >],
      execute => sub {
         print {*STDOUT} 'foo baz on out';
         print {*STDERR} 'foo baz on err';
         return 'Baz';
      },
   };
}

1;
