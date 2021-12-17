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
         'default-child' => 'bar',
         children        => [qw< foo bar >],
      },
      foo => {
         help        => 'sub-command foo',
         description => 'first-level sub-command foo',
         supports    => ['foo', 'Foo'],
         options     => [
            {
               getopt => 'hey|h=s',
            },
         ],
         children        => ['baz'],
         'default-child' => 'baz',
      },
      bar => {
         help        => 'sub-command bar',
         description => 'first-level sub-command bar',
         options     => [],
         execute     => sub ($main, $conf, $args) {
            LocalTester::command_execute(bar => @_);
            print {*STDOUT} 'bar on out';
            print {*STDERR} 'bar on err';
            return 'Bar';
         },
      },
      baz => {
         help        => 'sub-sub-command baz',
         description => 'second-level sub-command baz',
         options     => [
            {
               getopt => 'last|l=i',
            },
         ],
         execute => sub ($main, $conf, $args) {
            LocalTester::command_execute(baz => @_);
            print {*STDOUT} 'baz on out';
            print {*STDERR} 'baz on err';
            return 'BAZ';
         },
      },
   },
};

subtest 'help' => sub {
   test_run($app, ['help'], {}, undef)->no_exceptions->stdout_like(
      qr{(?mxs:
         example \s+ command .*?
         An \s+ example \s+ command .*?
         --foo .*
         GALOOK_BAR .*?
         help .*?
         commands .*?
      )}, 'output of help command'
   )->stdout_like(qr{sub-command foo})->stdout_like(qr{sub-command bar});
};

subtest 'foo help' => sub {
   test_run($app, ['foo', 'help'], {}, undef)->no_exceptions->stdout_like(
      qr{(?mxs:
         sub-command \s+ foo .*?
         first-level \s+ sub-command \s+ foo .*?
         --hey .*
         help .*?
         commands .*?
      )}, 'output of help command'
   )->stdout_like(qr{sub-sub-command baz});
};

subtest 'help foo' => sub {
   test_run($app, ['help', 'foo'], {}, undef)->no_exceptions->stdout_like(
      qr{(?mxs:
         sub-command \s+ foo .*?
         first-level \s+ sub-command \s+ foo .*?
         --hey .*
         help .*?
         commands .*?
      )}, 'output of help command'
   )->stdout_like(qr{sub-sub-command baz});
};

subtest 'foo help baz' => sub {
   test_run($app, ['foo', 'help', 'baz'], {}, undef)
     ->no_exceptions->stdout_like(
      qr{(?mxs:
         sub-sub-command \s+ baz .*?
         second-level \s+ sub-command \s+ baz .*?
         --last .*
      )}, 'output of help command'
   )->stdout_like(qr{sub-sub-command baz});
};

subtest 'foo baz' => sub {
   test_run($app, ['foo', 'baz'], {}, 'baz')
     ->no_exceptions->result_is('BAZ')->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

subtest 'foo baz' => sub {
   test_run($app, [qw< --foo foo --hey you baz --last 12 FP >], {}, 'baz')
     ->no_exceptions->result_is('BAZ')
     ->conf_is({foo => 1, bar => 'buzz', hey => 'you', last => 12})
     ->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

subtest 'foo (leveraging default sub-child)' => sub {
   test_run($app, ['foo'], {}, 'baz')->no_exceptions->result_is('BAZ')
     ->stdout_like(qr{baz on out})->stderr_like(qr{baz on err});
};

subtest 'Foo (uppercase, leveraging default sub-child)' => sub {
   test_run($app, ['Foo'], {}, 'baz')->no_exceptions->result_is('BAZ')
     ->stdout_like(qr{baz on out})->stderr_like(qr{baz on err});
};

subtest 'Foo commands (note uppercase)' => sub {
   test_run($app, [qw< Foo commands >], {}, undef)
     ->no_exceptions->stdout_like(qr{(?mxs:help: .*? commands:)});
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

done_testing();
