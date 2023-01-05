use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $app = {
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
            {
               getopt => 'help!'
            },
            {
               getopt => 'commands!'
            },
         ],
         execute => sub ($blob, $conf, $args) {
            LocalTester::command_execute(MAIN => $blob, $conf, $args);
            if ($conf->{help}) {
               $blob->{helpers}{'print-help'}->($blob, 'MAIN');
               return 0;
            }
            if ($conf->{commands}) {
               $blob->{helpers}{'print-commands'}->($blob, 'MAIN');
               return 15;
            }
            print {*STDOUT} 'galook!';
            print {*STDERR} 'gaaaah!';
            return 42;
         },
         leaf => 1,
      }
   },
};

subtest 'no input, just defaults' => sub {
   test_run($app, [], {}, 'MAIN')->no_exceptions->conf_is({bar => 'buzz'})
     ->args_are([])->result_is(42)->stdout_like(qr{(?mxs:\A galook! \z)})
     ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

# Avoid defaults
$app->{configuration}{sources} = [qw< +CmdLine +Environment >];

subtest 'defaults no more in effect, env set' => sub {
   test_run($app, [], {GALOOK_FOO => 'BU!'}, 'MAIN')
      ->no_exceptions
      ->conf_is({foo => 'BU!'})
      ->args_are([])->result_is(42)->stdout_like(qr{(?mxs:\A galook! \z)})
      ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

subtest 'defaults no more in effect, cmdline set' => sub {
   test_run($app, ['--foo'], {}, 'MAIN')
      ->no_exceptions
      ->conf_is({foo => 1})
      ->args_are([])->result_is(42)->stdout_like(qr{(?mxs:\A galook! \z)})
      ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

done_testing();
