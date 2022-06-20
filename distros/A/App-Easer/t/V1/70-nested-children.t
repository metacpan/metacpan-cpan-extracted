use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;

my $app = {
   configuration => {
      'auto-leaves' => 1,
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
         'default-child' => {index => 1},
         children => [
            {
               help        => 'sub-command foo',
               description => 'first-level sub-command foo',
               supports    => ['foo', 'Foo'],
               options     => [
                  {
                     getopt => 'hey|h=s',
                  },
               ],
               execute => sub {
                  print {*STDOUT} 'foo on out';
                  print {*STDERR} 'foo on err';
                  return 'Foo';
               },
            },
            'my-name-is-bar',
         ],
      },
      'my-name-is-bar' => {
         supports => ['bar'],
         help        => 'sub-command bar',
         description => 'first-level sub-command bar',
         options     => [],
         execute     => sub ($main, $conf, $args) {
            print {*STDOUT} 'bar on out';
            print {*STDERR} 'bar on err';
            return 'Bar';
         },
      },
   },
};

subtest 'foo' => sub {
   test_run($app, ['foo'], {}, 'foo')->no_exceptions->result_is('Foo')
      ->stdout_like(qr{foo on out})->stderr_like(qr{foo on err});
};

subtest 'help foo' => sub {
   test_run($app, ['help', 'foo'], {}, undef)->no_exceptions->stdout_like(
      qr{(?mxs:
         sub-command \s+ foo .*?
         first-level \s+ sub-command \s+ foo .*?
         hey
      )}, 'output of help command'
   );
};

subtest 'bar' => sub {
   test_run($app, ['bar'], {}, 'bar')->no_exceptions->result_is('Bar')
     ->stdout_like(qr{bar on out})->stderr_like(qr{bar on err});
};

subtest 'help bar' => sub {
   test_run($app, ['help', 'bar'], {}, undef)->no_exceptions->stdout_like(
      qr{(?mxs:
         sub-command \s+ bar .*?
         first-level \s+ sub-command \s+ bar .*?
         has \s+ no \s+ options
      )}, 'output of help command'
   );
};

subtest 'bar help (help is ignored)' => sub {
   test_run($app, [qw< bar help >], {}, undef)
     ->no_exceptions->stdout_like(qr{bar on out})
     ->stderr_like(qr{bar on err});
};

subtest 'bar as default' => sub {
   test_run($app, [], {}, 'bar')->no_exceptions->result_is('Bar')
     ->stdout_like(qr{bar on out})->stderr_like(qr{bar on err});
};

$app->{commands}{MAIN}{'default-child'}{index} = 0;

subtest 'foo as default' => sub {
   test_run($app, [], {}, 'foo')->no_exceptions->result_is('Foo')
     ->stdout_like(qr{foo on out})->stderr_like(qr{foo on err});
};

done_testing();
