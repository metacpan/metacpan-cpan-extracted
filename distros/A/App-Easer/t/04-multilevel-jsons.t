use v5.24;
use experimental 'signatures';
use Test::More;
use File::Basename 'dirname';
use lib dirname(__FILE__);
use LocalTester;
use Helpers 'tpath';

my $app = {
   configuration => {
      'auto-leaves' => 1,
   },
   commands => {
      MAIN => {
         help        => 'example command',
         description => 'An example command',
         sources     => '+SourcesWithFiles',
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
               getopt => 'config|c=s',
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
            print {*STDOUT} 'baz on out';
            print {*STDERR} 'baz on err';
            return 'BAZ';
         },
      },
   },
};

subtest 'foo baz' => sub {
   test_run($app, [qw< --foo foo --hey you baz --last 12 FP >], {}, 'baz')
     ->no_exceptions->result_is('BAZ')
     ->conf_is({foo => 1, bar => 'buzz', hey => 'you', last => 12})
     ->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

subtest 'foo baz, with config file' => sub {
   test_run(
      $app,
      [
         qw< --foo --config >,
         tpath('example.json'),
         qw< foo --hey you baz --last 12 FP >
      ],
      {},
      'baz'
   )->no_exceptions->result_is('BAZ')->conf_is(
      {
         foo    => 1,
         bar    => 'buzz',
         hey    => 'you',
         last   => 12,
         what   => 'ever',
         config => tpath('example.json')
      }
   )->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

$app->{commands}{MAIN}{'config-files'} =
  [qw< /etcxn/not/existent >, tpath('example.json')];

subtest 'foo baz, with config file' => sub {
   test_run($app, [qw< --foo foo --hey you baz --last 12 FP >], {}, 'baz')
     ->no_exceptions->result_is('BAZ')->conf_is(
      {
         foo  => 1,
         bar  => 'buzz',
         hey  => 'you',
         last => 12,
         what => 'ever',
      }
   )->args_are(['FP'])->stdout_like(qr{baz on out})
     ->stderr_like(qr{baz on err});
};

done_testing();
