use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $app = {
   name        => 'MAIN',
   help        => 'example command',
   description => 'An example command',
   options     => [
      {
         getopt      => 'foo|f!',
         environment => 'GALOOK_FOO',
      },
      {
         getopt      => 'bar|b=s',
         environment => 'GALOOK_BAR',
         default     => 'buzz',
      },
      {
         getopt => 'help!'
      },
      {
         getopt => 'commands!'
      },
   ],
   execute => sub ($self, @rest) {
      LocalTester::command_execute($self, @rest);
      if ($self->config('help')) {
         $self->auto_help->run('help');
         return 0;
      }
      if ($self->config('commands')) {
         $self->auto_commands->run('commands');
         return 15;
      }
      print {*STDOUT} 'galook!';
      print {*STDERR} 'gaaaah!';
      return 42;
   },
};

subtest 'no options, just defaults' => sub {
   test_run($app, [], {}, 'MAIN')->no_exceptions->conf_is({bar => 'buzz'})
     ->args_are([])->result_is(42)->stdout_like(qr{(?mxs:\A galook! \z)})
     ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

subtest 'option --help' => sub {
   test_run($app, ['--help'], {}, 'MAIN')
     ->no_exceptions->conf_is({bar => 'buzz', help => 1})
     ->args_are([])
     ->result_is(0)
     ->stdout_like(qr{(?mxs: Description: .*? Options:)});
};

subtest 'option --commands' => sub {
   test_run($app, ['--commands'], {}, 'MAIN')
     ->no_exceptions->conf_is({bar => 'buzz', commands => 1})
     ->args_are([])
     ->result_is(15)
     ->stdout_like(qr{no sub-commands});
};

done_testing();
