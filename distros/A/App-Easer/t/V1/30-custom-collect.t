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
   configuration => {
      collect => sub ($m, $s, $a) { return ({this => 'that'}, ['hey']) },
   },
};

subtest 'no input, just defaults, custom collect' => sub {
   test_run($app, [], {}, 'MAIN')
     ->no_exceptions
     ->conf_is({this => 'that'})
     ->args_are(['hey'])
     ->result_is(42)
     ->stdout_like(qr{(?mxs:\A galook! \z)})
     ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

delete $app->{configuration}{collect};

subtest 'no input, just defaults, standard collect' => sub {
   test_run($app, [], {}, 'MAIN')->no_exceptions->conf_is({bar => 'buzz'})
     ->args_are([])->result_is(42)->stdout_like(qr{(?mxs:\A galook! \z)})
     ->stderr_like(qr{(?mxs:\A gaaaah! \z)});
};

done_testing();
