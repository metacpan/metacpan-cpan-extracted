use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $app = {
   configuration => {
      'auto-leaves' => 0,
   },
   commands => {
      MAIN => {
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
         ],
         execute => sub {
            LocalTester::command_execute(MAIN => @_);
            print {*STDOUT} 'galook!';
            print {*STDERR} 'gaaaah!';
            return 42;
         },
         'default-child' => '',
      }
   },
};

subtest 'no input, just defaults' => sub {
   test_run($app, [], {}, 'MAIN')->no_exceptions->conf_is({bar => 'buzz'})
     ->args_are([])->result_is(42)->stdout_like(qr{(?mxs:\A galook! \z)})
     ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

subtest 'env + cmdline, both parameters' => sub {
   test_run($app, [qw< --bar BAAZ >], {GALOOK_FOO => 1}, 'MAIN')
     ->no_exceptions->conf_is({foo => 1, bar => 'BAAZ'})->args_are([])
     ->result_is(42)->stdout_like(qr{(?mxs:\A galook! \z)})
     ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

test_run($app, ['help'], {}, 'MAIN')->no_exceptions->stdout_like(
   qr{(?mxs:
      example \s+ command .*?
      An \s+ example \s+ command .*?
      --foo .*
      GALOOK_BAR .*?
      help .*?
      commands .*?
   )}, 'output of help command'
);

test_run($app, ['commands'], {}, 'MAIN')->no_exceptions->stdout_like(
   qr{(?mxs:
      help .*?
      commands .*?
   )}, 'output of commands command'
);

test_run($app, ['inexistent'], {}, 'MAIN')->exception_like(
   qr{(?mxs:
      cannot .*? inexistent
   )}, 'inexistent command generates complaint'
);

done_testing();
