package Sampler::CmdFoo;

sub spec {
   return {
      help => 'sampler foo',
      supports => [qw< foo >],
      children => [[ '+ChildrenByPrefix', 'Sampler::CmdFoo::Cmd' ]],
      execute => sub {
         print {*STDOUT} 'foo on out';
         print {*STDERR} 'foo on err';
         return 'Foo';
      },
      'default-child' => undef,
   };
}

1;
